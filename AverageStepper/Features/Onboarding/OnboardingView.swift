import SwiftUI

struct OnboardingView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var model = OnboardingViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                Text("Walk your step goal")
                    .font(Theme.title)
                    .accessibilityAddTraits(.isHeader)

                Text("Average Stepper plans a walking route from where you are, tuned to a target step count. Your data stays on this device.")
                    .font(Theme.body)
                    .foregroundStyle(.secondary)

                ASCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Location for routes & tracking", systemImage: "location.fill")
                            .font(Theme.headline)
                        Text("We use your approximate location to build a route and show progress during a walk.")
                            .font(Theme.body)
                            .foregroundStyle(.secondary)
                    }
                }

                PrimaryButton("Continue", systemImage: "arrow.right") {
                    model.completeIntro(dependencies: dependencies)
                }

                SecondaryButton("Enable location access", systemImage: "location") {
                    model.requestLocation(dependencies: dependencies)
                }
            }
            .padding()
            .frame(maxWidth: Theme.contentMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    OnboardingView()
        .environment(AppDependencies.preview)
}
