import SwiftUI
import LocalAuthentication

/// Biometric gate: locks the app when entering foreground if enabled
/// and if more than N minutes passed since last unlock.
@MainActor
final class BiometricGate: ObservableObject {
    static let shared = BiometricGate()

    @AppStorage("biometric.enabled") var enabled: Bool = true
    @AppStorage("biometric.lockAfterSeconds") var lockAfterSeconds: Int = 60 // lock after 1 minute bg
    @Published private(set) var isLocked: Bool = false
    @Published var lastAuthError: String?

    private var lastUnlockAt: Date?
    private var wentBackgroundAt: Date?

    var canUseBiometrics: Bool {
        var err: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }

    var biometricKindName: String {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch ctx.biometryType {
        case .faceID:   return "Face ID"
        case .touchID:  return "Touch ID"
        case .opticID:  return "Optic ID"
        default:        return "Biometria"
        }
    }

    var biometricIcon: String {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch ctx.biometryType {
        case .faceID:  return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default:       return "lock.shield.fill"
        }
    }

    func applicationDidEnterBackground() {
        wentBackgroundAt = Date()
    }

    func applicationWillEnterForeground() {
        guard enabled, canUseBiometrics else { return }
        // Lock SOLO se siamo davvero andati in background (non solo inactive per FaceID prompt / Control Center)
        guard let went = wentBackgroundAt else { return }
        let elapsed = Date().timeIntervalSince(went)
        if elapsed > Double(lockAfterSeconds) {
            isLocked = true
        }
        wentBackgroundAt = nil
    }

    func lockNow() { isLocked = true }

    func authenticate() async -> Bool {
        guard canUseBiometrics else {
            isLocked = false
            return true
        }
        let ctx = LAContext()
        ctx.localizedFallbackTitle = "Usa codice dispositivo"
        do {
            let ok = try await ctx.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Sblocca FirmaCDC per visualizzare i tuoi documenti."
            )
            if ok {
                isLocked = false
                lastUnlockAt = Date()
                lastAuthError = nil
                Haptics.success()
            }
            return ok
        } catch let error as LAError {
            lastAuthError = userFriendlyMessage(for: error)
            Haptics.error()
            return false
        } catch {
            lastAuthError = error.localizedDescription
            Haptics.error()
            return false
        }
    }

    private func userFriendlyMessage(for err: LAError) -> String {
        switch err.code {
        case .userCancel, .appCancel, .systemCancel:
            return "Autenticazione annullata. Tocca 'Sblocca' per riprovare."
        case .userFallback:
            return "Usa il codice del dispositivo per continuare."
        case .biometryLockout:
            return "\(biometricKindName) bloccato dopo troppi tentativi. Sblocca con il codice del dispositivo, poi riprova."
        case .biometryNotAvailable:
            return "Biometria non disponibile su questo dispositivo."
        case .biometryNotEnrolled:
            return "Nessun volto/impronta registrati. Configura \(biometricKindName) in Impostazioni."
        case .passcodeNotSet:
            return "Nessun codice dispositivo impostato. Imposta un codice in Impostazioni."
        case .authenticationFailed:
            return "Autenticazione non riuscita. Riprova."
        default:
            return err.localizedDescription
        }
    }
}

// MARK: - Lock overlay
struct BiometricLockOverlay: View {
    @EnvironmentObject var gate: BiometricGate
    @State private var attempted = false

    var body: some View {
        ZStack {
            // Dim backdrop
            BrandGradient.hero.ignoresSafeArea()
            // Blobs
            Circle().fill(BrandColor.cyan.opacity(0.25))
                .frame(width: 320, height: 320)
                .offset(x: -120, y: -260).blur(radius: 60)
            Circle().fill(Color.white.opacity(0.12))
                .frame(width: 280, height: 280)
                .offset(x: 140, y: 280).blur(radius: 60)

            VStack(spacing: 24) {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 130, height: 130)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                    Image(systemName: gate.biometricIcon)
                        .font(.system(size: 62, weight: .regular))
                        .foregroundStyle(.white)
                        .shadow(color: BrandColor.deepBlue.opacity(0.5), radius: 12, x: 0, y: 6)
                }
                VStack(spacing: 6) {
                    Text("FirmaCDC bloccata")
                        .font(BrandFont.title(24)).foregroundStyle(.white)
                    Text("Autenticati con \(gate.biometricKindName) per continuare")
                        .font(BrandFont.body(14))
                        .foregroundStyle(.white.opacity(0.85))
                }
                if let e = gate.lastAuthError {
                    InlineError(message: e).padding(.horizontal, 24)
                }
                Spacer()
                GradientButton(title: "Sblocca",
                               systemImage: gate.biometricIcon,
                               gradient: BrandGradient.glass) {
                    Task { await gate.authenticate() }
                }
                .padding(.horizontal, 24).padding(.bottom, 30)
            }
        }
        .transition(.opacity)
        .task {
            if !attempted {
                attempted = true
                _ = await gate.authenticate()
            }
        }
    }
}
