import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject var auth: AuthService
    @State private var showEmailLogin = false
    @State private var animateLogo = false

    var body: some View {
        ZStack {
            // background
            BrandGradient.hero.ignoresSafeArea()
            // floating blobs
            Circle().fill(BrandColor.cyan.opacity(0.35))
                .frame(width: 320, height: 320)
                .offset(x: -120, y: -260).blur(radius: 60)
            Circle().fill(Color.white.opacity(0.18))
                .frame(width: 280, height: 280)
                .offset(x: 150, y: 280).blur(radius: 60)

            VStack(spacing: 28) {
                Spacer()

                // Logo
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                    Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: BrandColor.deepBlue.opacity(0.6), radius: 12, x: 0, y: 6)
                }
                .scaleEffect(animateLogo ? 1 : 0.6)
                .opacity(animateLogo ? 1 : 0)

                VStack(spacing: 8) {
                    Text("FirmaCDC")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(2)
                    Text("Firma digitale certificata")
                        .font(BrandFont.body(16))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .opacity(animateLogo ? 1 : 0)
                .offset(y: animateLogo ? 0 : 20)

                Spacer()

                VStack(spacing: 14) {
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { req in
                            req.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            Task { await auth.handleAppleSignIn(result) }
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous))
                    .shadow(color: .black.opacity(0.20), radius: 10, x: 0, y: 6)

                    Button {
                        Haptics.tap(); showEmailLogin = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                            Text("Accedi con email")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: BrandRadius.md, style: .continuous)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1.2)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .opacity(animateLogo ? 1 : 0)

                if let err = auth.lastError {
                    InlineError(message: err).padding(.horizontal, 24)
                }

                Text("Continuando accetti i Termini e la Privacy Policy.")
                    .font(BrandFont.body(11))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animateLogo = true
            }
        }
        .sheet(isPresented: $showEmailLogin) {
            EmailLoginView().environmentObject(auth)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct EmailLoginView: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var loading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Accedi")
                .font(BrandFont.display(28))
                .foregroundStyle(BrandColor.ink)
            Text("Inserisci le credenziali del tuo account FirmaCDC.")
                .font(BrandFont.body(14))
                .foregroundStyle(BrandColor.mute)

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(BrandColor.surface, in: RoundedRectangle(cornerRadius: BrandRadius.sm))
                SecureField("Password", text: $password)
                    .padding(14)
                    .background(BrandColor.surface, in: RoundedRectangle(cornerRadius: BrandRadius.sm))
            }

            if let err = auth.lastError {
                InlineError(message: err)
            }

            GradientButton(title: "Accedi", systemImage: "arrow.right.circle.fill",
                           isLoading: loading,
                           disabled: email.isEmpty || password.isEmpty) {
                Task {
                    loading = true
                    await auth.loginEmail(email, password: password)
                    loading = false
                    if auth.isAuthenticated { dismiss() }
                }
            }

            Spacer()
        }
        .padding(24)
    }
}
