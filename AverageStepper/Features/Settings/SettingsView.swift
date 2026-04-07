import SwiftUI

struct SettingsView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var model = SettingsViewModel()

    var body: some View {
        Form {
            Section("Default step goal") {
                Text("Starting target when you open Plan — same presets as quick picks on the home screen.")
                    .font(Theme.caption)
                    .foregroundStyle(.secondary)
                presetGrid(values: [3000, 4000, 5000, 6000, 8000, 10_000, 12_000], selection: defaultStepsBinding) { v in
                    "\(v / 1000)k"
                }
            }

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
                            }
                        ),
                        in: 0.55...0.95,
                        step: 0.01
                    ) {
                        Text("Stride length")
                    }
                    .accessibilityLabel("Stride length, \(Int(dependencies.preferences.strideMeters * 100)) centimeters")

                    Text("Converts steps ↔ distance. Tune to your height or past walks.")
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
                            }
                        ),
                        in: 0.9...1.8,
                        step: 0.05
                    ) {
                        Text("Walking speed")
                    }
                    .accessibilityLabel("Walking speed for time estimates")
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
                            }
                        ),
                        in: 50...250,
                        step: 10
                    ) {
                        Text("Loop closure radius")
                    }
                    .accessibilityLabel("Loop closure radius in meters")

                    Text("How close a route should return to the start to count as a loop.")
                        .font(Theme.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Units") {
                Picker(
                    "Measurement units",
                    selection: Binding(
                        get: { dependencies.preferences.units },
                        set: { newValue in
                            var prefs = dependencies.preferences
                            prefs.units = newValue
                            dependencies.preferences = prefs
                        }
                    )
                ) {
                    Text("Metric").tag(MeasurementUnits.metric)
                    Text("Imperial").tag(MeasurementUnits.imperial)
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Distance units")
            }

            Section("Experience") {
                Toggle(
                    "Celebratory animations",
                    isOn: Binding(
                        get: { dependencies.preferences.celebratoryAnimationsEnabled },
                        set: { newValue in
                            var prefs = dependencies.preferences
                            prefs.celebratoryAnimationsEnabled = newValue
                            dependencies.preferences = prefs
                        }
                    )
                )
                .accessibilityHint("Soft motion when you finish a walk")

                #if DEBUG
                Toggle(
                    "Simulate walk position",
                    isOn: Binding(
                        get: { dependencies.debugSimulateWalk },
                        set: { dependencies.debugSimulateWalk = $0 }
                    )
                )
                Text("Advances a test point along the route on the active walk screen.")
                    .font(Theme.caption)
                    .foregroundStyle(.secondary)
                #endif
            }

            Section("Privacy") {
                Text(AppCopy.Privacy.summary)
                    .font(Theme.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Data") {
                Button("Reset achievements", role: .destructive) {
                    model.showResetAchievementsConfirm = true
                }
                .accessibilityHint("Clears completed walk history and badge progress")

                Button("Reset local data", role: .destructive) {
                    model.showResetAllDataConfirm = true
                }
                .accessibilityHint("Clears walks and resets stride and other settings to defaults")

                LabeledContent("Storage") {
                    Text("On device")
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Reset achievements?",
            isPresented: $model.showResetAchievementsConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                dependencies.resetWalkHistoryAndAchievements()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes your completed walk history. Badges derived from history will lock again.")
        }
        .confirmationDialog(
            "Reset all local data?",
            isPresented: $model.showResetAllDataConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset everything on device", role: .destructive) {
                dependencies.resetAllLocalData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Clears walk history and resets preferences to defaults. Your account is not affected — there is no account in this build.")
        }
    }

    private var defaultStepsBinding: Binding<Int> {
        Binding(
            get: { dependencies.preferences.defaultTargetSteps },
            set: { newValue in
                var prefs = dependencies.preferences
                prefs.defaultTargetSteps = newValue
                dependencies.preferences = prefs
            }
        )
    }

    private func presetGrid(
        values: [Int],
        selection: Binding<Int>,
        label: @escaping (Int) -> String
    ) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
            ForEach(values, id: \.self) { value in
                Button {
                    selection.wrappedValue = value
                } label: {
                    Text(label(value))
                        .font(Theme.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(selection.wrappedValue == value ? Color.accentColor : Color.secondary)
                .accessibilityLabel("\(value) steps")
                .accessibilityAddTraits(selection.wrappedValue == value ? .isSelected : [])
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppDependencies.preview)
    }
}
