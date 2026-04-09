# Average Stepper

## 1. Project overview

**Average Stepper** is a local-first iOS MVP that turns a **target step count** into **walking routes** near the user’s current position. It uses **MapKit** walking directions to chain segments into loop-style or out-and-back paths, tracks an **active walk** with Core Location, estimates steps from distance via stride, and awards **badges / streaks** from on-device walk history—no account and no backend in this build.

## 2. MVP feature list

- **Onboarding**: Multi-page flow explaining location use, route generation, tracking, and a dedicated permissions step with status and Settings link when denied.
- **Plan (Home)**: Step goal (stepper + quick picks), estimated distance/time, **Generate route** (MapKit-backed pipeline), hints for weak GPS / Apple Park default in Simulator.
- **Route preview**: Map polyline, pick among scored route options, **Start walk**.
- **Active walk**: Live map, steps/distance/route progress, pause/resume, adherence hints, optional **Simulate position** (DEBUG settings) for Simulator.
- **Walk complete**: Summary, streaks, lifetime totals, newly unlocked achievements, confetti (respects Reduce Motion).
- **Achievements**: Badges driven by local history rules.
- **Settings**: Default step goal, stride, walking speed, loop closure preference, units, animations, DEBUG simulation toggle, reset achievements / reset all local data.
- **Resume after relaunch**: If a walk was active, a **full-screen resume** stack appears on next launch until acknowledged.

## 3. Tech stack

| Area | Choice |
|------|--------|
| UI | SwiftUI |
| Pattern | MVVM-ish (`@Observable` view models + feature views; `AppDependencies` composition root) |
| Maps / routing | MapKit (`MKMapView` via SwiftUI `Map`, `MKDirections` for walking legs) |
| Location | Core Location (`CLLocationManager`, when-in-use) |
| Persistence | JSON in Application Support / documents (`UserPreferencesStore`, `WalkSessionPersistence`, `GamificationPersistence`) |
| Minimum OS | iOS **17.0** (per Xcode project) |

## 4. Architecture overview

- **`AverageStepperApp`** → injects **`AppDependencies`** (`@Observable`) into the environment.
- **`RootView`**: Onboarding vs **`MainTabView`**; presents **`ResumeWalkNavigationStack`** when an interrupted active walk is restored from disk.
- **`MainTabView`**: Tabs for Plan (`HomeView` → `NavigationStack` + `HomeStack` destinations), Achievements, Settings.
- **Routing**: `RouteGenerationService` → `RouteGenerationPipeline` (waypoint patterns → `RouteWaypointAssembler` + `MKDirectionsWalkingDirectionsService` → scoring → top options).
- **Active walk**: `WalkSessionManager` owns session state, timer-based persistence, location handler, step estimation, route progress / completion rules.
- **Gamification**: `AchievementEngine` + `BadgeCatalog` rules over `walkHistory` loaded at launch; `recordCompletedWalk` appends on completion.

## 5. Folder structure overview

```
AverageStepper/
├── AverageStepperApp.swift
├── App/                 # RootView, MainTabView, AppDependencies, resume stack
├── Features/            # Onboarding, Home, RoutePreview, ActiveWalk, WalkComplete, Achievements, Settings
├── DesignSystem/        # Theme, buttons, cards
├── Core/
│   ├── Models/          # WalkSession, routes, preferences, etc.
│   ├── Services/        # Location, routing, walk session, achievements, step distance
│   ├── Routing/         # Pipeline, scoring, MapKit directions, waypoint math
│   ├── Gamification/    # Badges, streaks, rules, persistence types
│   ├── ActiveWalk/      # Polyline math, walk snapshot persistence
│   ├── Persistence/     # User preferences store
│   ├── Utilities/       # Copy, formatting, map region fitting
│   └── Mock/            # MockData for previews/tests
├── Resources/Assets.xcassets
AverageStepperTests/     # Unit tests (routing, gamification, walk session, geodesy, home VM, etc.)
AverageStepper.xcodeproj
scripts/gen_xcodeproj.py # Optional helper script (if used in your workflow)
```

## 6. Requirements to run the app

- **macOS** with **Xcode 15+** (project last opened with Xcode 15 settings; iOS 17 SDK).
- An **Apple ID** for signing (Simulator can use automatic signing with a personal team in many setups).
- **iPhone Simulator** or a physical **iPhone** with iOS 17+.

This repository was validated by code review here; **full compilation was not executed** in this environment because only Xcode Command Line Tools were available (`xcodebuild` requires the full Xcode app as the active developer directory). You should confirm a clean build locally (see below).

## 7. Step-by-step: open and run in Xcode (MacBook)

1. Install **Xcode** from the Mac App Store (or Apple Developer) and open it once to finish installing components.
2. If needed, set the active developer directory:  
   `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
3. Clone or copy this repo and double-click **`AverageStepper.xcodeproj`** (or **File → Open** in Xcode).
4. In the toolbar, select the **AverageStepper** scheme and a destination (**iPhone 16** or any iOS 17+ Simulator, or your device).
5. Select the **AverageStepper** target → **Signing & Capabilities**: choose your **Team** so the app can run on device; Simulator often works with automatic signing.
6. Press **Run** (⌘R).

## 8. How to test in Simulator

- Exercise **onboarding**, **Plan**, **route generation** (expect network use for MapKit; failures are possible in poor network or sparse map data).
- For **active walk** without GPS, enable **Settings → Simulate walk position** (only in **DEBUG** builds) and use **Simulate position along route** on the active walk screen.
- Use **Device → Location** in Simulator to set a custom location or Apple’s canned routes when testing real location updates.

## 9. How to test location-dependent behavior

- **Simulator**: **Features → Location** → choose a **custom** or city location before generating a route; leave location **none** to exercise the “no fix / default coordinate” hints.
- **Device**: Test outdoors for faster GPS; verify **waiting for GPS** → **tracking** transitions and map annotation movement.
- **Denied permission**: iOS **Settings → Privacy & Security → Location Services** → **Average Stepper** → **Never**, then confirm Plan and Active Walk show errors and **Open Settings** flows.

## 10. How to test the permissions flow

1. Delete the app (or reset **Settings → General → Transfer or Reset → Reset Location & Privacy** for a clean prompt—destructive for all apps).
2. Launch the app: complete onboarding through **Allow location** (system dialog).
3. Deny once: confirm **Plan** blocks **Generate route** with copy for denied access.
4. From onboarding’s denied state, use **Open Settings** and return after enabling **While Using the App**.

## 11. How to run unit tests in Xcode

1. Open **`AverageStepper.xcodeproj`**.
2. Press **⌘U** or **Product → Test**.
3. The **AverageStepperTests** target runs tests such as routing, streaks, walk session, geodesy, and home view model behavior.

## 12. Known limitations of the MVP

- **No HealthKit / pedometer**: “Steps” during a walk are **estimated from GPS distance × stride**, not Apple Watch or CMStepCounter.
- **No background tracking**: Uses **when-in-use** location only; no background modes for walking.
- **No live rerouting**: Route is fixed after preview; copy states this explicitly.
- **Heuristic routes**: Loops are built from geometric waypoints + MapKit legs; results vary by area, pedestrian graph, and Apple’s routing.
- **Bundle ID** is `com.example.AverageStepper`—change before App Store distribution.
- **Development team** is blank in the project; you must assign signing locally.
- **App Store privacy manifest**: If you ship to the App Store, you may need a **PrivacyInfo.xcprivacy** file describing required-reason APIs; not included in this MVP repo—confirm with Apple’s current requirements before submission.

## 13. Future improvements

- Real step counts (HealthKit / Core Motion) with privacy copy and optional entitlements.
- Smarter rerouting or off-route recovery when user leaves the polyline.
- Richer tests around `RouteGenerationPipeline` with injected `WalkingDirectionsProviding` mocks.
- Background audio/voice cues only if product scope expands (would need more entitlements and UX).
- Replace `com.example` bundle identifier and add CI (Xcode Cloud or GitHub Actions on macOS) for `xcodebuild test`.

## 14. Privacy note (local-first MVP)

- Location is used **while using the app** to generate nearby routes and show position during walks, as described in **`INFOPLIST_KEY_NSLocationWhenInUseUsageDescription`** in the Xcode target (generated Info.plist).
- Walk history and preferences are stored **locally as JSON**; there is **no server**, **no account**, and **no analytics SDK** in this codebase.
- Users can **reset achievements** or **reset all local data** from Settings.

---

*Generated for this repository’s structure and code as of the MVP audit; behavior on device remains **your** final check in Xcode.*
