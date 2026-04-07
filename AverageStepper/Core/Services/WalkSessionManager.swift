import CoreLocation
import Foundation
import Observation

/// Owns live walk metrics, GPS handling, route adherence, and JSON persistence for resume-after-kill.
@MainActor
@Observable
final class WalkSessionManager: WalkSessionManaging {
    private(set) var session: WalkSession
    private(set) var activeRoute: GeneratedRoute?
    private(set) var selectedRouteOption: RouteOption?
    private(set) var needsResumeWalkPresentation: Bool = false
    /// Last acceptable-GPS coordinate (for map); may update while still in `waitingForGPS`.
    private(set) var lastKnownUserCoordinate: CLLocationCoordinate2D?
    /// Total polyline length of the selected route (meters).
    private(set) var routePolylineLengthMeters: Double = 0

    private let persistence: WalkSessionPersistence
    private let locationService: LocationProviding

    var locationAuthorizationState: LocationAuthorizationState {
        locationService.authorizationState
    }
    private let stepEstimator: StepDistanceEstimating
    private let config: ActiveWalkConfig

    private var strideMeters: Double = UserPreferences.default.strideMeters
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private var routeLengthMeters: Double = 0
    private var routeProgressHighWaterMark: Double = 0
    private var lastGoodLocation: CLLocation?
    private var goodFixStartTime: Date?
    private var tickTimer: Timer?
    private var persistTick: Int = 0
    private var debugSimulationIndex: Int = 0
    private var debugSimulateEnabled: Bool = false
    private var pauseStartedAt: Date?

    init(
        session: WalkSession = WalkSession(goal: WalkGoal(targetSteps: 0)),
        persistence: WalkSessionPersistence = WalkSessionPersistence(),
        locationService: LocationProviding,
        stepEstimator: StepDistanceEstimating = StepDistanceEstimator(),
        config: ActiveWalkConfig = .default,
        restoreFromDisk: Bool = true
    ) {
        self.session = session
        self.persistence = persistence
        self.locationService = locationService
        self.stepEstimator = stepEstimator
        self.config = config

        if restoreFromDisk, let snap = persistence.load(), snap.session.status == .active {
            self.session = snap.session
            self.activeRoute = snap.generatedRoute
            self.selectedRouteOption = snap.selectedRouteOption
            self.routeProgressHighWaterMark = snap.routeProgressHighWaterMark
            self.needsResumeWalkPresentation = true
            self.strideMeters = UserPreferences.default.strideMeters
            if snap.session.trackingPhase == .paused {
                self.pauseStartedAt = Date()
            }
            rebuildRouteCoordinates()
            wireLocationHandler()
            startTickTimer()
            locationService.requestWhenInUseAuthorization()
            locationService.startUpdatingLocation()
        }
    }

    func acknowledgeResumePresentation() {
        needsResumeWalkPresentation = false
    }

    func begin(route: GeneratedRoute, selectedOption: RouteOption, goal: WalkGoal, preferences: UserPreferences) {
        tearDownTimersAndLocation()
        needsResumeWalkPresentation = false
        strideMeters = preferences.strideMeters
        debugSimulateEnabled = false
        activeRoute = route
        selectedRouteOption = selectedOption
        routeCoordinates = selectedOption.coordinates.map(\.clCoordinate)
        routeLengthMeters = RoutePolylineGeometry.totalLengthMeters(coordinates: routeCoordinates)
        routePolylineLengthMeters = routeLengthMeters
        routeProgressHighWaterMark = 0
        lastGoodLocation = nil
        goodFixStartTime = nil
        lastKnownUserCoordinate = nil
        pauseStartedAt = nil

        session = WalkSession(
            startedAt: Date(),
            goal: goal,
            plannedRouteId: route.id,
            selectedRouteOptionId: selectedOption.id,
            status: .active,
            trackingPhase: .waitingForGPS,
            liveSteps: 0,
            liveDistanceMeters: 0,
            routeProgress01: 0,
            elapsedActiveTime: 0,
            accumulatedPausedTime: 0,
            adherenceStatus: .unknown,
            completionReason: nil,
            lastErrorMessage: nil
        )

        wireLocationHandler()
        locationService.requestWhenInUseAuthorization()
        locationService.startUpdatingLocation()
        startTickTimer()
        persistSnapshot()
    }

    func pause() {
        guard session.status == .active else { return }
        if session.trackingPhase == .paused { return }
        session.trackingPhase = .paused
        pauseStartedAt = Date()
        persistSnapshot()
    }

    func resume() {
        guard session.status == .active else { return }
        if locationService.authorizationState == .denied {
            session.lastErrorMessage = "Location access is off. Enable it in Settings to continue tracking, or end the walk."
            return
        }
        session.lastErrorMessage = nil
        if session.trackingPhase == .paused {
            flushPauseIntervalIfNeeded()
            session.trackingPhase = .tracking
        }
        persistSnapshot()
    }

    func complete(reason: WalkCompletionReason) {
        flushPauseIntervalIfNeeded()
        stopTickTimer()
        locationService.setLocationUpdateHandler(nil)
        locationService.stopUpdatingLocation()
        session.endedAt = Date()
        session.status = .completed
        session.trackingPhase = .inactive
        session.completionReason = reason
        persistence.clear()
    }

    func cancel() {
        flushPauseIntervalIfNeeded()
        stopTickTimer()
        locationService.setLocationUpdateHandler(nil)
        locationService.stopUpdatingLocation()
        session.endedAt = Date()
        session.status = .cancelled
        session.trackingPhase = .inactive
        session.completionReason = .aborted
        needsResumeWalkPresentation = false
        activeRoute = nil
        selectedRouteOption = nil
        persistence.clear()
    }

    func resetIdle() {
        cancel()
        session = WalkSession(goal: WalkGoal(targetSteps: 0))
        activeRoute = nil
        selectedRouteOption = nil
    }

    func simulateAdvancePosition() {
        guard debugSimulateEnabled, !routeCoordinates.isEmpty else { return }
        debugSimulationIndex = min(debugSimulationIndex + 1, routeCoordinates.count - 1)
        let c = routeCoordinates[debugSimulationIndex]
        let loc = CLLocation(
            coordinate: c,
            altitude: 0,
            horizontalAccuracy: 8,
            verticalAccuracy: 0,
            timestamp: Date()
        )
        processLocation(loc)
    }

    /// Enables simulation along the route (Simulator / debug).
    func setDebugSimulationEnabled(_ enabled: Bool) {
        debugSimulateEnabled = enabled
        debugSimulationIndex = 0
    }

    // MARK: - Private

    private func rebuildRouteCoordinates() {
        routeCoordinates = selectedRouteOption?.coordinates.map(\.clCoordinate) ?? []
        routeLengthMeters = RoutePolylineGeometry.totalLengthMeters(coordinates: routeCoordinates)
        routePolylineLengthMeters = routeLengthMeters
    }

    private func flushPauseIntervalIfNeeded() {
        guard let start = pauseStartedAt else { return }
        session.accumulatedPausedTime += Date().timeIntervalSince(start)
        pauseStartedAt = nil
    }

    private func wireLocationHandler() {
        locationService.setLocationUpdateHandler { [weak self] location in
            self?.processLocation(location)
        }
    }

    private func startTickTimer() {
        stopTickTimer()
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        tickTimer = timer
    }

    private func stopTickTimer() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func tearDownTimersAndLocation() {
        stopTickTimer()
        locationService.setLocationUpdateHandler(nil)
        locationService.stopUpdatingLocation()
    }

    private func tick() {
        guard session.status == .active else { return }
        if session.trackingPhase == .tracking {
            session.elapsedActiveTime += 1
        }
        persistTick += 1
        if persistTick % 5 == 0 {
            persistSnapshot()
        }
    }

    private func processLocation(_ location: CLLocation) {
        guard session.status == .active else { return }
        if session.trackingPhase == .paused { return }

        if locationService.authorizationState == .denied {
            session.lastErrorMessage = "Location is off. Open Settings to allow access, or end the walk."
            return
        }

        if location.horizontalAccuracy >= 0, location.horizontalAccuracy <= config.maxAcceptableHorizontalAccuracy {
            lastKnownUserCoordinate = location.coordinate
        }

        if location.horizontalAccuracy < 0 || location.horizontalAccuracy > config.maxAcceptableHorizontalAccuracy {
            if session.trackingPhase == .waitingForGPS {
                session.lastErrorMessage = "Waiting for a clearer GPS fix…"
            }
            return
        }

        if session.trackingPhase == .waitingForGPS {
            if goodFixStartTime == nil { goodFixStartTime = Date() }
            if let start = goodFixStartTime, Date().timeIntervalSince(start) >= config.minimumGoodFixSeconds {
                session.trackingPhase = .tracking
                goodFixStartTime = nil
                session.lastErrorMessage = nil
            } else {
                session.lastErrorMessage = "Locking GPS…"
                return
            }
        }

        session.lastErrorMessage = nil

        if let last = lastGoodLocation {
            let dt = max(location.timestamp.timeIntervalSince(last.timestamp), 0.05)
            let segment = location.distance(from: last)
            let speed = segment / dt
            if speed <= config.maxPlausibleWalkingSpeedMetersPerSecond, segment > 0.5 {
                session.liveDistanceMeters += segment
            }
        }
        lastGoodLocation = location

        session.liveSteps = stepEstimator.estimatedSteps(
            forDistanceMeters: session.liveDistanceMeters,
            strideMeters: strideMeters
        )

        updateRouteMetrics(user: location.coordinate)
        checkCompletion()
        persistSnapshot()
    }

    private func updateRouteMetrics(user: CLLocationCoordinate2D) {
        guard routeCoordinates.count >= 2 else {
            session.routeProgress01 = routeProgressHighWaterMark
            session.adherenceStatus = .unknown
            return
        }

        let (_, cross, _, _) = RoutePolylineGeometry.nearestPointOnPolyline(to: user, coordinates: routeCoordinates)
        let along = RoutePolylineGeometry.distanceAlongPolyline(to: user, coordinates: routeCoordinates)
        let progress = min(1, max(0, along / max(routeLengthMeters, 1)))
        routeProgressHighWaterMark = max(routeProgressHighWaterMark, progress)
        session.routeProgress01 = routeProgressHighWaterMark

        if routeProgressHighWaterMark >= config.routeCompletionProgressThreshold {
            session.adherenceStatus = .routeComplete
            return
        }

        if cross <= config.onRouteToleranceMeters {
            session.adherenceStatus = .onRoute
        } else if cross <= config.slightlyOffRouteToleranceMeters {
            session.adherenceStatus = .slightlyOffRoute
        } else {
            session.adherenceStatus = .offRoute
        }
    }

    private func checkCompletion() {
        guard session.status == .active else { return }

        if routeProgressHighWaterMark >= config.routeCompletionProgressThreshold {
            complete(reason: .routeCompleted)
            return
        }

        let stepTarget = Double(session.goal.targetSteps)
        if stepTarget > 0, Double(session.liveSteps) >= stepTarget * config.stepGoalCompletionThreshold {
            complete(reason: .reachedStepGoal)
        }
    }

    private func persistSnapshot() {
        guard session.status == .active, let route = activeRoute, let option = selectedRouteOption else { return }
        let snap = PersistedWalkSnapshot(
            session: session,
            generatedRoute: route,
            selectedRouteOption: option,
            routeProgressHighWaterMark: routeProgressHighWaterMark
        )
        try? persistence.save(snap)
    }

    /// SwiftUI previews: attach a route without starting Core Location.
    func attachPreviewRoute(_ route: GeneratedRoute, option: RouteOption) {
        activeRoute = route
        selectedRouteOption = option
        rebuildRouteCoordinates()
        lastKnownUserCoordinate = routeCoordinates.first
    }
}
