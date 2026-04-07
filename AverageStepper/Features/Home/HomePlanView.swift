import SwiftUI
import UIKit

/// Main “Plan a walk” content: target steps, metrics, route generation, and location-denied guidance.
struct HomePlanView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.openURL) private var openURL
    @Bindable var model: HomeViewModel
    @Binding var path: [HomeStack]

    private let quickPicks = [3000, 4000, 5000, 6000, 8000, 10_000]

    var body: some View {
        @Bindable var walk = dependencies.walkSessionManager
        @Bindable var location = dependencies.locationForObservation

        ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                if walk.session.status == .active {
                    ASCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Walk in progress")
                                .font(Theme.headline)
                            Text("Continue tracking or end the walk from the walk screen.")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.Colors.muted)
                            PrimaryButton("Continue walk", systemImage: "location.fill") {
                                path.append(.activeWalk)
                            }
                            .accessibilityLabel("Continue walk in progress")
                        }
                    }
                }

                if location.authorizationState == .denied {
                    locationDeniedCard
                }

                ASCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Target steps")
                            .font(Theme.headline)
                            .accessibilityAddTraits(.isHeader)

                        Stepper(value: $model.targetSteps, in: 1000...20_000, step: 500) {
                            Text("\(model.targetSteps) steps")
                                .font(Theme.body)
                                .lineLimit(nil)
                                .multilineTextAlignment(.leading)
                        }
                        .accessibilityLabel("Target steps")
                        .accessibilityValue("\(model.targetSteps)")

                        Text("Quick picks")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.Colors.muted)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
                            ForEach(quickPicks, id: \.self) { value in
                                Button {
                                    model.targetSteps = value
                                } label: {
                                    Text(formatK(value))
                                        .font(Theme.body.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                                .buttonStyle(.bordered)
                                .tint(model.targetSteps == value ? Color.accentColor : Color.secondary)
                                .accessibilityLabel("\(value) steps")
                                .accessibilityAddTraits(model.targetSteps == value ? .isSelected : [])
                            }
                        }
                    }
                }

                HStack(alignment: .top, spacing: 12) {
                    MetricCard(
                        title: "Est. distance",
                        value: Formatting.distance(model.estimatedDistanceMeters(), units: dependencies.preferences.units),
                        subtitle: "Stride \(Int(dependencies.preferences.strideMeters * 100)) cm"
                    )
                    MetricCard(
                        title: "Est. time",
                        value: Formatting.duration(model.estimatedWalkDuration()),
                        subtitle: "Walking pace"
                    )
                }
                .frame(maxWidth: .infinity)

                if let hint = model.routeHint, model.lastError == nil {
                    ASCard {
                        Label(hint, systemImage: "antenna.radiowaves.left.and.right")
                            .font(Theme.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }

                if let lastError = model.lastError {
                    ASCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Couldn’t generate")
                                .font(Theme.headline)
                            Text(lastError)
                                .font(Theme.body)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 12) {
                                PrimaryButton("Try again", systemImage: "arrow.clockwise") {
                                    Task {
                                        if let route = await model.generateRoute() {
                                            path.append(.routePreview(route))
                                        }
                                    }
                                }
                                .disabled(model.isGenerating)

                                SecondaryButton("Clear", systemImage: "xmark.circle") {
                                    model.clearError()
                                }
                            }
                        }
                    }
                    .accessibilityElement(children: .contain)
                }

                PrimaryButton("Generate route", systemImage: "map") {
                    Task {
                        if let route = await model.generateRoute() {
                            path.append(.routePreview(route))
                        }
                    }
                }
                .disabled(model.isGenerating || location.authorizationState == .denied)
                .accessibilityHint("Creates a walking route for your target step goal")

                if model.isGenerating {
                    ProgressView("Building route…")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .accessibilityLabel("Building route")
                }
            }
            .padding()
            .frame(maxWidth: Theme.contentMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            model.targetSteps = dependencies.preferences.defaultTargetSteps
        }
        .onChange(of: dependencies.preferences.defaultTargetSteps) { _, newValue in
            model.targetSteps = newValue
        }
    }

    private var locationDeniedCard: some View {
        ASCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(AppCopy.Location.deniedTitle)
                    .font(Theme.headline)
                Text(AppCopy.Location.deniedBody)
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(AppCopy.Location.openSettings) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Opens Settings for this app")
            }
        }
    }

    private func formatK(_ v: Int) -> String {
        "\(v / 1000)k"
    }
}
