import SwiftUI

@main
struct RavengApp: App {
    @StateObject private var auth    = AuthService.shared
    @StateObject private var api     = APIClient.shared
    @StateObject private var tod     = TimeOfDay.shared
    @StateObject private var gate    = BiometricGate.shared
    @StateObject private var reach   = Reachability.shared
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
                .environmentObject(reach)
                .preferredColorScheme(.light)
                .tint(BrandColor.brightBlue)
                .overlay(alignment: .top) {
                    if !reach.isOnline {
                        OfflineBanner()
                            .padding(.top, 2)
                    }
                }
                .overlay {
                    if gate.isLocked && auth.isAuthenticated {
                        BiometricLockOverlay()
                            .environmentObject(gate)
                            .zIndex(99)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: gate.isLocked)
                .animation(.easeInOut(duration: 0.25), value: reach.isOnline)
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
