# Average Stepper

iOS app that turns a **step goal** into an approximate **walking distance**, generates **MapKit-based route options** (loops and out-and-back patterns), tracks an **active walk** with GPS, and rewards progress with **badges and streaks**.

## Architecture

- **SwiftUI** app shell (`AverageStepperApp`, `RootView`, tab navigation) with an `AppDependencies` container for services and persisted preferences.
- **Domain**: `WalkSession` / `WalkGoal`, gamification totals, `BadgeCatalog` + `AchievementRuleEvaluator`, `StreakManager`.
- **Routing**: `RouteGenerationPipeline` coordinates `WaypointPatternGenerator` → `RouteWaypointAssembler` + `WalkingDirectionsProviding` → `RouteScorer` selection.
- **Active walk**: `WalkSessionManager` (`WalkSessionManaging`) consumes `LocationProviding`, `StepDistanceEstimating`, and persists resume state via `WalkSessionPersistence`.
- **Tests**: `AverageStepperTests` cover stride math, route scoring, streaks, achievement rules, and session lifecycle with `MockLocationService`.

## Apple frameworks

- **SwiftUI** — UI
- **MapKit** (`MKDirections`, maps in flow) — walking directions and polylines
- **Core Location** — live tracking and authorization
- **Foundation** — persistence (JSON), calendars for streaks
- **Observation** — `@Observable` services where used

## MVP limitations

- **Heuristic routes**: There is no “build a perfect N-step loop” API; candidates are geometric patterns + chained legs, so quality varies by area and pedestrian network.
- **Stride / steps**: Distance ↔ steps uses fixed stride and summed GPS distance; no HealthKit integration in MVP.
- **Single-user, on-device**: No account sync, social features, or server-side route cache.
- **Foreground-focused**: Designed around “when in use” location; background tracking policies are not fully productized.
- **Achievements**: Rules are local and catalog-driven; changing rules does not migrate historical unlock semantics.

## Roadmap (ideas)

- HealthKit step/distance reconciliation and optional calibration wizard
- Smarter route families (A–B commutes, saved routes) and offline map snapshots
- Background delivery and richer notifications for long walks
- Accessibility pass (VoiceOver on map + live metrics) and Dynamic Type polish
- Widgets / Live Activities for active walk status

## Engineering notes

- **Brittle routing code** is called out in `RouteGenerationPipeline` (MapKit variability, heuristic loops, scoring vs. real-world walkability).
- Regenerate the Xcode project after adding Swift files: `python3 scripts/gen_xcodeproj.py`.

## Top 5 improvements after MVP

1. **HealthKit** — read step count where available; calibrate stride from recent data; optional “true steps” vs. GPS-derived steps.
2. **Routing robustness** — retry strategies, more pattern diversity, user-placed waypoints, and clearer failure UX when `noCandidateFound`.
3. **Background & battery** — geofencing or visit-based prompts; configurable accuracy vs. battery; pause detection.
4. **Testing & CI** — `xcodebuild test` on a simulator in CI; snapshot/UI tests for critical flows.
5. **Product depth** — editable routes, favorites, and weekly summaries without expanding scope to accounts.
