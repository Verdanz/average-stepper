import CoreLocation
import MapKit
import SwiftUI
import UIKit

struct ActiveWalkView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.openURL) private var openURL
    @Binding var path: [HomeStack]
    @State private var model: ActiveWalkViewModel?
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        @Bindable var walk = dependencies.walkSessionManager
        Group {
            if let model {
                activeContent(model: model, walk: walk)
            } else {
                ProgressView()
                    .onAppear {
                        let m = ActiveWalkViewModel(
                            walkSessionManager: dependencies.walkSessionManager,
                            preferences: dependencies.preferences
                        )
                        model = m
                        dependencies.walkSessionManager.setDebugSimulationEnabled(dependencies.debugSimulateWalk)
                        fitCameraToRoute(walk: dependencies.walkSessionManager)
                    }
            }
        }
        .navigationTitle("Walking")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onChange(of: dependencies.debugSimulateWalk) { _, enabled in
            dependencies.walkSessionManager.setDebugSimulationEnabled(enabled)
        }
        .onChange(of: walk.session.status) { oldStatus, newStatus in
            guard oldStatus == .active, newStatus == .completed else { return }
            dependencies.recordCompletedWalk(walk.session)
            path = [.walkComplete]
        }
    }

    @ViewBuilder
    private func activeContent(model: ActiveWalkViewModel, walk: WalkSessionManager) -> some View {
        let session = walk.session
        if session.status != .active {
            ContentUnavailableView(
                "No active walk",
                systemImage: "figure.walk",
                description: Text("Start a walk from a route preview.")
            )
            PrimaryButton("Back", systemImage: "chevron.left") {
                path.removeLast()
            }
            .padding()
        } else {
            walkTrackingBody(model: model, walk: walk)
        }
    }

    private func walkTrackingBody(model: ActiveWalkViewModel, walk: WalkSessionManager) -> some View {
        let session = walk.session
        let coords = walk.selectedRouteOption?.coordinates.map(\.clCoordinate) ?? []

        return ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                statusBanner(model: model, session: session)

                mapSection(coords: coords, model: model)

                progressSection(model: model, session: session)

                metricsSection(model: model, session: session)

                if model.locationDenied {
                    locationDeniedCard
                }

                controlsSection(model: model, session: session)
            }
            .padding()
            .frame(maxWidth: Theme.contentMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("End", systemImage: "stop.circle") {
                    Button("End and save", systemImage: "checkmark.circle") {
                        model.endWalkEarly()
                    }
                }
            }
        }
        .onAppear {
            fitCameraToRoute(walk: walk)
        }
        .onChange(of: walk.lastKnownUserCoordinate?.latitude) { _, _ in
            followUserIfPossible(model: model, walk: walk)
        }
        .onChange(of: walk.lastKnownUserCoordinate?.longitude) { _, _ in
            followUserIfPossible(model: model, walk: walk)
        }
    }

    @ViewBuilder
    private func statusBanner(model: ActiveWalkViewModel, session: WalkSession) -> some View {
        let phase = session.trackingPhase
        ASCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: phaseIcon(phase))
                        .foregroundStyle(statusColor(model: model, phase: phase))
                    Text(model.primaryStatusLine(for: session))
                        .font(Theme.headline)
                    Spacer()
                    Text(model.elapsedTimeText(for: session))
                        .font(Theme.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                if let hint = model.secondaryHintLine(for: session) {
                    Text(hint)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.Colors.muted)
                }
                if phase == .paused {
                    Text("Timer is paused. Distance is not counted until you resume.")
                        .font(Theme.caption)
                        .foregroundStyle(.secondary)
                }
                if session.trackingPhase == .waitingForGPS {
                    ProgressView()
                        .padding(.top, 4)
                }
            }
        }
    }

    private func phaseIcon(_ phase: WalkTrackingPhase) -> String {
        switch phase {
        case .inactive: return "circle"
        case .waitingForGPS: return "location.circle"
        case .tracking: return "figure.walk"
        case .paused: return "pause.circle"
        }
    }

    private func statusColor(model: ActiveWalkViewModel, phase: WalkTrackingPhase) -> Color {
        if model.locationDenied { return .red }
        switch phase {
        case .waitingForGPS: return .orange
        case .paused: return .secondary
        case .tracking: return Theme.Colors.accent
        case .inactive: return .secondary
        }
    }

    private func mapSection(coords: [CLLocationCoordinate2D], model: ActiveWalkViewModel) -> some View {
        Map(position: $cameraPosition) {
            if coords.count >= 2 {
                MapPolyline(coordinates: coords)
                    .stroke(Theme.Colors.accent.opacity(0.75), lineWidth: 5)
            }
            if let c = model.lastUserCoordinate {
                Annotation("You", coordinate: c) {
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.35))
                            .frame(width: 28, height: 28)
                        Circle()
                            .fill(.blue)
                            .frame(width: 12, height: 12)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }

    private func progressSection(model: ActiveWalkViewModel, session: WalkSession) -> some View {
        ASCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Progress")
                    .font(Theme.headline)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Steps toward goal")
                            .font(Theme.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Formatting.steps(session.liveSteps)) / \(Formatting.steps(session.goal.targetSteps))")
                            .font(Theme.caption.monospacedDigit())
                    }
                    ProgressView(value: model.stepProgress01(for: session))
                        .tint(Theme.Colors.accent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Route completion")
                            .font(Theme.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(session.routeProgress01 * 100))%")
                            .font(Theme.caption.monospacedDigit())
                    }
                    ProgressView(value: session.routeProgress01)
                        .tint(.green)
                }
            }
        }
    }

    private func metricsSection(model: ActiveWalkViewModel, session: WalkSession) -> some View {
        HStack(spacing: 12) {
            MetricCard(
                title: "Remaining (route)",
                value: Formatting.distance(model.estimatedRemainingRouteMeters(for: session), units: dependencies.preferences.units),
                subtitle: "Along planned path"
            )
            MetricCard(
                title: "Est. time left",
                value: Formatting.duration(model.estimatedRemainingWalkTime(for: session)),
                subtitle: "By your pace setting"
            )
        }
    }

    private var locationDeniedCard: some View {
        ASCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Location access needed")
                    .font(Theme.headline)
                Text("Turn on location for this app to track your walk, or end the session.")
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func controlsSection(model: ActiveWalkViewModel, session: WalkSession) -> some View {
        let phase = session.trackingPhase
        return Group {
            if phase == .paused {
                PrimaryButton("Resume", systemImage: "play.fill") {
                    model.resume()
                }
            } else {
                SecondaryButton("Pause", systemImage: "pause.fill") {
                    model.pause()
                }
            }

            if dependencies.debugSimulateWalk {
                SecondaryButton("Simulate position along route", systemImage: "forward.fill") {
                    model.simulateAdvance()
                }
            }

            Text("Routes are fixed in this MVP — there is no live rerouting. If GPS is noisy, progress may update slowly.")
                .font(Theme.caption)
                .foregroundStyle(Theme.Colors.muted)
        }
    }

    private func fitCameraToRoute(walk: WalkSessionManager) {
        let coords = walk.selectedRouteOption?.coordinates.map(\.clCoordinate) ?? []
        guard !coords.isEmpty else { return }
        cameraPosition = .region(MapRegionFitting.region(for: coords))
    }

    private func followUserIfPossible(model: ActiveWalkViewModel, walk: WalkSessionManager) {
        guard let c = model.lastUserCoordinate else { return }
        let span = MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
        cameraPosition = .region(MKCoordinateRegion(center: c, span: span))
    }
}

#Preview {
    NavigationStack {
        ActiveWalkView(path: .constant([.activeWalk]))
            .environment(AppDependencies.preview)
    }
}
