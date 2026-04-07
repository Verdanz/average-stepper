import SwiftUI

@main
struct AverageStepperApp: App {
    @State private var dependencies = AppDependencies.live

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(dependencies)
        }
    }
}
