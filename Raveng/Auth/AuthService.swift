import Foundation
import AuthenticationServices

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: AppUser?
    @Published var isAuthenticated: Bool = false
    @Published var lastError: String?

    init() {
        if let token = KeychainService.get(.accessToken), !token.isEmpty {
            isAuthenticated = true
            if let userJSON = KeychainService.get(.userJSON),
               let data = userJSON.data(using: .utf8),
               let user = try? JSONDecoder().decode(AppUser.self, from: data) {
                currentUser = user
            }
        }
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let e):
            lastError = e.localizedDescription
        case .success(let auth):
            guard let cred = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = cred.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8)
            else {
                lastError = "Token Apple non disponibile."
                return
            }
            let code = cred.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
            let firstName = cred.fullName?.givenName
            let lastName  = cred.fullName?.familyName

            do {
                let tokens: AuthTokens = try await APIClient.shared.send(
                    API.Auth.appleSignIn(identityToken: identityToken, code: code,
                                         firstName: firstName, lastName: lastName)
                )
                persist(tokens)
                Haptics.success()
            } catch {
                lastError = error.localizedDescription
                Haptics.error()
            }
        }
    }

    func loginEmail(_ email: String, password: String) async {
        do {
            let tokens: AuthTokens = try await APIClient.shared.send(
                API.Auth.login(email: email, password: password)
            )
            persist(tokens)
            Haptics.success()
        } catch {
            lastError = error.localizedDescription
            Haptics.error()
        }
    }

    func logout() async {
        try? await APIClient.shared.sendVoid(API.Auth.logout())
        KeychainService.clearAll()
        currentUser = nil
        isAuthenticated = false
    }

    private func persist(_ tokens: AuthTokens) {
        KeychainService.set(tokens.accessToken, for: .accessToken)
        KeychainService.set(tokens.refreshToken, for: .refreshToken)
        if let data = try? JSONEncoder().encode(tokens.user),
           let json = String(data: data, encoding: .utf8) {
            KeychainService.set(json, for: .userJSON)
        }
        currentUser = tokens.user
        isAuthenticated = true
        lastError = nil
    }
}
