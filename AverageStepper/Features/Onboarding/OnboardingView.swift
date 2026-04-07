import SwiftUI
import UIKit

struct OnboardingView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.openURL) private var openURL
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        @Bindable var model = viewModel
        @Bindable var location = dependencies.locationForObservation

        VStack(spacing: 0) {
            TabView(selection: $model.stepIndex) {
                welcomePage.tag(0)
                locationPage.tag(1)
                routesPage.tag(2)
                trackingPage.tag(3)
                permissionsPage(location: location).tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut(duration: 0.25), value: model.stepIndex)

            bottomBar(vm: viewModel)
        }
        .background(Color(.systemGroupedBackground))
        .accessibilityElement(children: .contain)
    }

    private var welcomePage: some View {
        OnboardingPage(
            title: "Walk toward your goal",
            subtitle: "Average Stepper plans outdoor-style walking routes from where you are, tuned to a target step count. Everything stays on this device."
        ) {
            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.Colors.accent)
                .accessibilityHidden(true)
        }
        .accessibilityLabel("Walk toward your goal. Average Stepper plans routes from your location. Data stays on device.")
    }

    private var locationPage: some View {
        OnboardingPage(
            title: "Why we use location",
            subtitle: AppCopy.Location.whyWeNeedIt
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Routes near you", systemImage: "map.fill")
                    .font(Theme.body.weight(.semibold))
                Text(AppCopy.Location.accuracy)
                    .font(Theme.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityLabel("Why we use location. \(AppCopy.Location.whyWeNeedIt) \(AppCopy.Location.accuracy)")
    }

    private var routesPage: some View {
        OnboardingPage(
            title: "Routes from your step goal",
            subtitle: AppCopy.Routes.fromSteps
        ) {
            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }

    private var trackingPage: some View {
        OnboardingPage(
            title: "Progress on the walk",
            subtitle: AppCopy.Routes.tracking
        ) {
            Image(systemName: "location.fill.viewfinder")
                .font(.system(size: 44))
                .foregroundStyle(Theme.Colors.accent.opacity(0.85))
                .accessibilityHidden(true)
        }
    }

    private func permissionsPage(location: LocationService) -> some View {
        OnboardingPage(
            title: "Location access",
            subtitle: "When you’re ready, allow location while using the app. You can change this later in Settings."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                authorizationStatusRow(for: location.authorizationState)
                Text(AppCopy.Privacy.summary)
                    .font(Theme.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityLabel("Location permission. Current status: \(authorizationLabel(for: location.authorizationState))")
    }

    @ViewBuilder
    private func authorizationStatusRow(for state: LocationAuthorizationState) -> some View {
        switch state {
        case .authorizedWhenInUse, .authorizedAlways:
            Label("Location enabled", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(Theme.body)
        case .denied:
            VStack(alignment: .leading, spacing: 8) {
                Label(AppCopy.Location.deniedTitle, systemImage: "xmark.circle.fill")
                    .foregroundStyle(.orange)
                Text(AppCopy.Location.deniedBody)
                    .font(Theme.caption)
                    .foregroundStyle(.secondary)
                Button(AppCopy.Location.openSettings) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Opens the Settings app for this device")
            }
        case .notDetermined:
            Text("Not requested yet — use the button below when you’re ready.")
                .font(Theme.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func authorizationLabel(for state: LocationAuthorizationState) -> String {
        switch state {
        case .notDetermined: return "not determined"
        case .denied: return "denied"
        case .authorizedWhenInUse: return "while in use"
        case .authorizedAlways: return "always"
        }
    }

    @ViewBuilder
    private func bottomBar(vm: OnboardingViewModel) -> some View {
        VStack(spacing: 12) {
            if vm.stepIndex < vm.pageCount - 1 {
                PrimaryButton("Continue", systemImage: "arrow.right") {
                    vm.advance()
                }
                .accessibilityLabel("Continue to next onboarding screen")

                SecondaryButton("Back", systemImage: "chevron.left") {
                    vm.goBack()
                }
                .disabled(vm.stepIndex == 0)
                .accessibilityLabel("Go back")
            } else {
                PrimaryButton("Allow location", systemImage: "location.fill") {
                    vm.requestLocation(dependencies: dependencies)
                }
                .accessibilityLabel("Request location while in use access")

                PrimaryButton("Start planning", systemImage: "checkmark.circle.fill") {
                    vm.completeOnboarding(dependencies: dependencies)
                }
                .accessibilityLabel("Finish onboarding and go to the app")

                SecondaryButton("Back", systemImage: "chevron.left") {
                    vm.goBack()
                }
            }
        }
        .padding()
        .frame(maxWidth: Theme.contentMaxWidth)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Page

private struct OnboardingPage<Accessory: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                Text(title)
                    .font(Theme.title)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)

                Text(subtitle)
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                accessory()
            }
            .padding()
            .frame(maxWidth: Theme.contentMaxWidth)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppDependencies.preview)
}
