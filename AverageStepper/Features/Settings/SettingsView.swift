import SwiftUI

struct SettingsView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var model = SettingsViewModel()

    var body: some View {
        Form {
            Section("Walking model") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stride length: \(Int(dependencies.preferences.strideMeters * 100)) cm")
                        .font(Theme.body)
                    Slider(
                        value: Binding(
                            get: { dependencies.preferences.strideMeters },
                            set: { newValue in
                                var prefs = dependencies.preferences
                                prefs.strideMeters = newValue
                                dependencies.preferences = prefs
                                model.markNeedsPersistence()
                            }
                        ),
                        in: 0.55...0.95,
                        step: 0.01
                    ) {
                        Text("Stride")
                    }
                    Text("Used to convert steps ↔ distance. Tune to match your height or past walks.")
                        .font(Theme.caption)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Walking speed: \(String(format: "%.1f", dependencies.preferences.walkingSpeedMetersPerSecond)) m/s")
                        .font(Theme.body)
                    Slider(
                        value: Binding(
                            get: { dependencies.preferences.walkingSpeedMetersPerSecond },
                            set: { newValue in
                                var prefs = dependencies.preferences
                                prefs.walkingSpeedMetersPerSecond = newValue
                                dependencies.preferences = prefs
                                model.markNeedsPersistence()
                            }
                        ),
                        in: 0.9...1.8,
                        step: 0.05
                    ) {
                        Text("Speed")
                    }
                }
            }

            Section("Loop preference") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Closure radius: \(Int(dependencies.preferences.loopClosureRadiusMeters)) m")
                        .font(Theme.body)
                    Slider(
                        value: Binding(
                            get: { dependencies.preferences.loopClosureRadiusMeters },
                            set: { newValue in
                                var prefs = dependencies.preferences
                                prefs.loopClosureRadiusMeters = newValue
                                dependencies.preferences = prefs
                                model.markNeedsPersistence()
                            }
                        ),
                        in: 50...250,
                        step: 10
                    ) {
                        Text("Radius")
                    }
                    Text("How close the route should return to your start to count as a loop.")
                        .font(Theme.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Units") {
                Picker(
                    "Measurement",
                    selection: Binding(
                        get: { dependencies.preferences.units },
                        set: { newValue in
                            var prefs = dependencies.preferences
                            prefs.units = newValue
                            dependencies.preferences = prefs
                            model.markNeedsPersistence()
                        }
                    )
                ) {
                    Text("Metric").tag(MeasurementUnits.metric)
                    Text("Imperial").tag(MeasurementUnits.imperial)
                }
                .pickerStyle(.segmented)
            }

            #if DEBUG
            Section("Developer") {
                Toggle(
                    "Simulate walk position",
                    isOn: Binding(
                        get: { dependencies.debugSimulateWalk },
                        set: { dependencies.debugSimulateWalk = $0 }
                    )
                )
                Text("Shows a control on the active walk screen to advance a fake GPS point along the route (Simulator-friendly).")
                    .font(Theme.caption)
                    .foregroundStyle(.secondary)
            }
            #endif

            Section("About") {
                LabeledContent("Data") {
                    Text("On device")
                }
                Text("No account, no backend in this MVP build.")
                    .font(Theme.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppDependencies.preview)
    }
}
