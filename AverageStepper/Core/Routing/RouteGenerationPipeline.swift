import CoreLocation
import Foundation

/// **Route generation pipeline (MVP heuristic)**
///
/// Apple provides point-to-point walking directions only — there is no “build me a loop of N steps” API.
/// This pipeline:
/// 1. Converts the step goal → target distance using stride (`StepDistanceEstimator`).
/// 2. **Waypoint generation** (`WaypointPatternGenerator`): polygon loops, near-loops, and out-and-back fallbacks.
/// 3. **Segment routing** (`RouteWaypointAssembler` + `WalkingDirectionsProviding`): chains MapKit walking legs.
/// 4. **Scoring** (`RouteScorer`): distance fit, closure to start, complexity, turning, ETA deviation.
/// 5. **Selection**: prefer candidates inside a relative distance tolerance band; dedupe fingerprints; return top 3.
///
/// All distances along roads come from MapKit; straight-line helpers are only for waypoint placement and closure checks.
///
/// ## Real-world brittleness (MVP)
/// - **No true loop API**: Waypoints are geometric heuristics; `MKDirections` may fail legs, detour, or snap unpredictably near water, highways, or sparse pedestrian graphs.
/// - **Scale sensitivity**: `WaypointPatternGenerator` uses flat-earth offsets; error grows away from the equator and is not geodesy-exact for long legs.
/// - **Scoring vs. feasibility**: A low `RouteScorer` score does not guarantee walkability (construction, stairs, private property); tolerance bands are relative to target distance only.
/// - **Directions churn**: MapKit results can change between iOS releases or server-side data; fingerprints help dedupe but won’t stabilize routing outcomes across devices.
/// - **Failure modes**: If every pattern throws or yields empty candidates, the pipeline surfaces `RouteGenerationError.noCandidateFound` — UX should treat this as “try another area/time,” not a bug in scoring alone.
struct RouteGenerationPipeline: Sendable {
    var config: RoutingConfig
    var directions: WalkingDirectionsProviding
    var stepEstimator: StepDistanceEstimating

    func makeGeneratedRoute(
        goal: WalkGoal,
        preferences: UserPreferences,
        start: CLLocationCoordinate2D
    ) async throws -> GeneratedRoute {
        let targetDistance = stepEstimator.targetMeters(forSteps: goal.targetSteps, strideMeters: preferences.strideMeters)
        let expectedDuration = stepEstimator.estimatedDuration(
            distanceMeters: targetDistance,
            speedMetersPerSecond: preferences.walkingSpeedMetersPerSecond
        )

        RoutingLogger.log.debug("Target steps \(goal.targetSteps) → target distance \(Int(targetDistance)) m")

        var loopPatterns: [(label: String, kind: RoutePatternKind, coords: [CLLocationCoordinate2D])] = []

        // Loop / near-loop families (rotation diversifies street snapping).
        for sides in config.polygonSides {
            for rot in config.rotationJitterRadians {
                loopPatterns.append((
                    label: "Loop (\(sides) sides)",
                    kind: .loopPolygon,
                    coords: WaypointPatternGenerator.loopPolygon(
                        start: start,
                        targetPerimeterMeters: targetDistance,
                        sides: sides,
                        rotationRadians: rot
                    )
                ))
                loopPatterns.append((
                    label: "Near-loop (\(sides) sides)",
                    kind: .nearLoop,
                    coords: WaypointPatternGenerator.nearLoop(
                        start: start,
                        targetPerimeterMeters: targetDistance,
                        sides: sides,
                        rotationRadians: rot,
                        shortfallMeters: min(90, preferences.loopClosureRadiusMeters * 0.6)
                    )
                ))
            }
        }

        let limitedLoops = Array(loopPatterns.prefix(config.maxLoopPatternAttempts))

        var patterns = limitedLoops

        // Out-and-back is the robust fallback when loops fail to snap nicely — always attempted.
        for deg in config.outAndBackBearingsDegrees {
            patterns.append((
                label: "Out & back",
                kind: .outAndBack,
                coords: WaypointPatternGenerator.outAndBack(
                    start: start,
                    totalDistanceMeters: targetDistance,
                    bearingDegreesFromNorth: deg
                )
            ))
        }

        let limited = patterns

        var candidates: [ScoredCandidate] = []
        var seenFingerprints: Set<String> = []

        for pattern in limited {
            do {
                let assembled = try await RouteWaypointAssembler.assemble(
                    waypoints: pattern.coords,
                    directions: directions
                )

                let endCoord = assembled.coordinates.last ?? start
                let closure = Geodesy.distanceMeters(endCoord, start)

                let inputs = RouteScoreInputs(
                    targetDistanceMeters: targetDistance,
                    actualDistanceMeters: assembled.distanceMeters,
                    closureDistanceMeters: closure,
                    segmentCount: assembled.segmentCount,
                    estimatedDuration: assembled.estimatedDuration,
                    expectedDuration: expectedDuration,
                    coordinates: assembled.coordinates
                )

                let score = RouteScorer.score(inputs: inputs, weights: config.scoreWeights)

                let fingerprint = RouteScorer.fingerprint(
                    distanceMeters: assembled.distanceMeters,
                    coordinates: assembled.coordinates
                )
                if seenFingerprints.contains(fingerprint) {
                    RoutingLogger.log.debug("Skipping duplicate fingerprint \(fingerprint)")
                    continue
                }
                seenFingerprints.insert(fingerprint)

                let estSteps = stepEstimator.estimatedSteps(
                    forDistanceMeters: assembled.distanceMeters,
                    strideMeters: preferences.strideMeters
                )

                candidates.append(
                    ScoredCandidate(
                        label: pattern.label,
                        kind: pattern.kind,
                        score: score,
                        assembly: assembled,
                        estimatedSteps: estSteps
                    )
                )

                RoutingLogger.log.debug(
                    "Candidate \(pattern.label): dist \(Int(assembled.distanceMeters)) m, score \(String(format: "%.3f", score)), closure \(Int(closure)) m"
                )
            } catch {
                RoutingLogger.log.error("Pattern failed (\(pattern.label)): \(String(describing: error))")
            }
        }

        // Prefer candidates within tolerance, but still rank if everything is slightly off.
        let toleranceMin = targetDistance * (1 - config.acceptableDistanceRelativeError)
        let toleranceMax = targetDistance * (1 + config.acceptableDistanceRelativeError)
        let withinBand = candidates.filter { $0.assembly.distanceMeters >= toleranceMin && $0.assembly.distanceMeters <= toleranceMax }
        let pool = withinBand.isEmpty ? candidates : withinBand

        let sorted = pool.sorted { $0.score < $1.score }
        let top = Array(sorted.prefix(config.topOptionsCount))

        guard !top.isEmpty else {
            throw RouteGenerationError.noCandidateFound
        }

        let options: [RouteOption] = top.map { cand in
            RouteOption(
                distanceMeters: cand.assembly.distanceMeters,
                estimatedSteps: cand.estimatedSteps,
                estimatedDuration: cand.assembly.estimatedDuration,
                coordinates: cand.assembly.coordinates.map(LatLon.init),
                score: cand.score,
                kind: cand.kind,
                label: cand.label
            )
        }

        return GeneratedRoute(
            goal: goal,
            targetDistanceMeters: targetDistance,
            options: options
        )
    }

    private struct ScoredCandidate: Sendable {
        var label: String
        var kind: RoutePatternKind
        var score: Double
        var assembly: AssembledWalkRoute
        var estimatedSteps: Int
    }
}
