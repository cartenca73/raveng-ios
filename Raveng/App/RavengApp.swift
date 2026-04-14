import SwiftUI

@main
struct RavengApp: App {
    @StateObject private var auth = AuthService.shared
    @StateObject private var api  = APIClient.shared

    init() {
        // Global appearance tuning
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav

        let tab = UITabBarAppearance()
        tab.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(api)
                .preferredColorScheme(.light)
                .tint(BrandColor.brightBlue)
        }
    }
}
