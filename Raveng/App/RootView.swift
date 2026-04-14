import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthService
    @AppStorage("onboarding.completed") private var onboardingDone = false

    var body: some View {
        Group {
            if !onboardingDone {
                OnboardingView()
                    .transition(.opacity)
            } else if auth.isAuthenticated {
                MainTabView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                WelcomeView()
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: auth.isAuthenticated)
        .animation(.easeInOut, value: onboardingDone)
    }
}

struct MainTabView: View {
    @EnvironmentObject var auth: AuthService
    @State private var selection: Int = 0
    @State private var showSpotlight = false
    @StateObject private var spotlightData = SpotlightDataHub()

    private let tabs: [FloatingTab] = [
        .init(id: 0, title: "Firma",      systemImage: "signature"),
        .init(id: 1, title: "Admin",      systemImage: "rectangle.stack.fill"),
        .init(id: 2, title: "Verifica",   systemImage: "checkmark.shield.fill"),
        .init(id: 3, title: "Profilo",    systemImage: "person.crop.circle.fill")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case 0: SignerHomeView()
                case 1: AdminHomeView()
                case 2: VerifyHomeView()
                default: ProfileView()
                }
            }
            .transition(.opacity)
            .environmentObject(spotlightData)

            FloatingTabBar(tabs: tabs, selection: $selection, onSearchTap: {
                showSpotlight = true
            })
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showSpotlight) {
            SpotlightSearchView(
                query: .constant(""),
                pending: spotlightData.pending,
                templates: spotlightData.templates
            ) { dest in
                handleSpotlight(dest)
            }
            .presentationDetents([.large])
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTab)) { notif in
            if let i = notif.object as? Int, (0...3).contains(i) {
                withAnimation { selection = i }
            }
        }
    }

    private func handleSpotlight(_ dest: SpotlightDestination) {
        switch dest {
        case .tab(let i):  selection = i
        case .signerDetail:  selection = 0
        case .templateDetail: selection = 1
        case .action: break
        }
    }
}

// Shared lightweight data hub that SignerHome/AdminHome push into so Spotlight can search.
@MainActor
final class SpotlightDataHub: ObservableObject {
    @Published var pending: [PendingSubmitter] = []
    @Published var templates: [TemplateSummary] = []
}

struct ProfileView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var tod: TimeOfDay
    @EnvironmentObject var gate: BiometricGate

    var body: some View {
        NavigationStack {
            ZStack {
                BrandColor.surface.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        HeroHeader(
                            title: "\(tod.greeting), \(firstName)",
                            subtitle: auth.currentUser?.email ?? "",
                            systemImage: "person.crop.circle.fill",
                            eyebrow: tod.eyebrowLabel
                        )

                        AppCard {
                            VStack(alignment: .leading, spacing: 14) {
                                ProfileRow(icon: "envelope.fill", title: "Email",
                                           value: auth.currentUser?.email ?? "—")
                                Divider()
                                ProfileRow(icon: "person.text.rectangle",
                                           title: "Ruolo",
                                           value: (auth.currentUser?.role ?? "user").capitalized)
                            }
                        }
                        .padding(.horizontal, 16)

                        // Security card
                        AppCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 10) {
                                    Image(systemName: gate.biometricIcon)
                                        .foregroundStyle(BrandColor.midBlue)
                                    Text("Sicurezza").font(BrandFont.title(16))
                                    Spacer()
                                }
                                Divider()
                                Toggle(isOn: $gate.enabled) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Sblocco con \(gate.biometricKindName)")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        Text("Richiedi biometria all'avvio")
                                            .font(BrandFont.caption(11)).foregroundStyle(BrandColor.mute)
                                    }
                                }
                                .tint(BrandColor.brightBlue)
                                .disabled(!gate.canUseBiometrics)

                                Button {
                                    gate.lockNow()
                                } label: {
                                    Label("Blocca ora", systemImage: "lock.fill")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(BrandColor.ink)
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        GradientButton(title: "Esci",
                                       systemImage: "arrow.right.square.fill",
                                       gradient: LinearGradient(
                                           colors: [BrandColor.danger, Color(hex: 0xDC2626)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing
                                       )) {
                            Task { await auth.logout() }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var firstName: String {
        let full = auth.currentUser?.fullName ?? ""
        return full.split(separator: " ").first.map(String.init) ?? "Ciao"
    }
}

private struct ProfileRow: View {
    let icon: String
    let title: String
    let value: String
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(BrandColor.skyTint).frame(width: 38, height: 38)
                Image(systemName: icon).foregroundStyle(BrandColor.midBlue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(BrandColor.mute)
                Text(value).font(.system(size: 15, weight: .medium)).foregroundStyle(BrandColor.ink)
            }
            Spacer()
        }
    }
}
