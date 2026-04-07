import CoreLocation
import MapKit
import SwiftUI

struct RoutePreviewView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Binding var path: [HomeStack]
    let route: GeneratedRoute

    @State private var position: MapCameraPosition = .automatic
    @State private var model: RoutePreviewViewModel?

    var body: some View {
        Group {
            if let model {
                content(model: model)
            } else {
                ProgressView()
                    .onAppear {
                        model = RoutePreviewViewModel(
                            route: route,
                            preferences: dependencies.preferences
                        )
                        let coords = route.options.first?.coordinates.map(\.clCoordinate) ?? []
                        position = .region(MapRegionFitting.region(for: coords))
                    }
            }
        }
        .navigationTitle("Route preview")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(model: RoutePreviewViewModel) -> some View {
        @Bindable var model = model
        let selected = model.selectedOption
        let coords = selected?.coordinates.map(\.clCoordinate) ?? []
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                Map(initialPosition: position) {
                    MapPolyline(coordinates: coords)
                        .stroke(Theme.Colors.accent, lineWidth: 5)
                    if let start = coords.first {
                        Annotation("Start", coordinate: start) {
                            Image(systemName: "figure.walk.circle.fill")
                                .font(.title)
                                .foregroundStyle(Theme.Colors.accent)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .onChange(of: model.selectedOptionID) { _, _ in
                    let c = model.selectedOption?.coordinates.map(\.clCoordinate) ?? []
                    position = .region(MapRegionFitting.region(for: c))
                }

                ASCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plan summary")
                            .font(Theme.headline)
                        LabeledContent("Target steps", value: model.goalStepsText)
                        LabeledContent("Target distance (stride-based)", value: model.targetDistanceText)
                        Text("Stride \(Int(dependencies.preferences.strideMeters * 100)) cm — adjust in Settings.")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.Colors.muted)
                    }
                    .font(Theme.body)
                }

                Text("Choose a route")
                    .font(Theme.headline)

                ForEach(route.options) { option in
                    optionCard(option: option, model: model)
                }

                if let selected {
                    PrimaryButton("Start walk", systemImage: "play.fill") {
                        dependencies.walkSessionManager.begin(
                            route: route,
                            selectedOption: selected,
                            goal: route.goal,
                            preferences: dependencies.preferences
                        )
                        path.append(.activeWalk)
                    }
                } else {
                    PrimaryButton("Select a route", systemImage: "play.fill") {}
                        .disabled(true)
                }

                SecondaryButton("Try another route") {
                    path.removeLast()
                }
            }
            .padding()
            .frame(maxWidth: Theme.contentMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func optionCard(option: RouteOption, model: RoutePreviewViewModel) -> some View {
        let isSelected = option.id == model.selectedOptionID
        return Button {
            model.selectedOptionID = option.id
        } label: {
            ASCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(option.label)
                            .font(Theme.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.Colors.accent)
                        }
                    }
                    LabeledContent("Est. steps", value: model.optionStepsText(option))
                    LabeledContent("Distance", value: model.optionDistanceText(option))
                    LabeledContent("Est. walk time", value: model.optionDurationText(option))
                    LabeledContent("Score (lower is better)", value: model.optionScoreText(option))
                    LabeledContent("Pattern", value: model.kindText(option))
                }
                .font(Theme.body)
            }
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(isSelected ? Theme.Colors.accent : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    NavigationStack {
        RoutePreviewView(
            path: .constant([.routePreview(MockData.generatedRoute(
                for: MockData.sampleGoal,
                near: CLLocationCoordinate2D(latitude: 37.33, longitude: -122.01),
                preferences: MockData.samplePreferences,
                stepEstimator: StepDistanceEstimator()
            ))]),
            route: MockData.generatedRoute(
                for: MockData.sampleGoal,
                near: CLLocationCoordinate2D(latitude: 37.33, longitude: -122.01),
                preferences: MockData.samplePreferences,
                stepEstimator: StepDistanceEstimator()
            )
        )
        .environment(AppDependencies.preview)
    }
}
