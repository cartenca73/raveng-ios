import SwiftUI

@main
struct RavengApp: App {
    @StateObject private var auth    = AuthService.shared
    @StateObject private var api     = APIClient.shared
    @StateObject private var tod     = TimeOfDay.shared
    @StateObject private var gate    = BiometricGate.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Global appearance
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav

        let tab = UITabBarAppearance()
        tab.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(api)
                .environmentObject(tod)
                .environmentObject(gate)
                .preferredColorScheme(.light)
                .tint(BrandColor.brightBlue)
                .overlay {
                    if gate.isLocked && auth.isAuthenticated {
                        BiometricLockOverlay()
                            .environmentObject(gate)
                            .zIndex(99)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: gate.isLocked)
        }
        .onChange(of: scenePhase) { _, new in
            switch new {
            case .background:
                gate.applicationDidEnterBackground()
            case .active:
                gate.applicationWillEnterForeground()
            default:
                break
            }
        }
    }
}
