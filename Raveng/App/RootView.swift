import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                WelcomeView()
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: auth.isAuthenticated)
    }
}

struct MainTabView: View {
    @EnvironmentObject var auth: AuthService
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            SignerHomeView()
                .tabItem {
                    Label("Da firmare", systemImage: "signature")
                }
                .tag(0)

            AdminHomeView()
                .tabItem {
                    Label("Amministra", systemImage: "rectangle.stack.fill")
                }
                .tag(1)

            VerifyHomeView()
                .tabItem {
                    Label("Verifica", systemImage: "checkmark.shield.fill")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profilo", systemImage: "person.crop.circle.fill")
                }
                .tag(3)
        }
    }
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
                        .padding(.bottom, 20)
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
