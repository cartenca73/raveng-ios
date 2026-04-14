import Foundation

// MARK: - Errors
enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case http(Int, String?)
    case decoding(Error)
    case transport(Error)
    case empty

    var errorDescription: String? {
        switch self {
        case .invalidURL:        return "URL non valido."
        case .unauthorized:      return "Sessione scaduta. Effettua di nuovo l'accesso."
        case .http(let c, let m): return "Errore server (\(c)): \(m ?? "")"
        case .decoding(let e):   return "Risposta non valida: \(e.localizedDescription)"
        case .transport(let e):  return "Connessione: \(e.localizedDescription)"
        case .empty:             return "Risposta vuota."
        }
    }
}

// MARK: - Endpoints
enum APIMethod: String { case GET, POST, PUT, DELETE, PATCH }

struct APIRequest {
    let path: String
    var method: APIMethod = .GET
    var query: [String: String] = [:]
    var body: Encodable? = nil
    var requiresAuth: Bool = true
}

// MARK: - Client
@MainActor
final class APIClient: ObservableObject {
    static let shared = APIClient()

    static let baseURL = URL(string: "https://docusign.ce4u.it/api/app/v1")!

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: Generic send
    func send<T: Decodable>(_ req: APIRequest, as: T.Type = T.self) async throws -> T {
        let urlReq = try buildRequest(req)
        do {
            let (data, response) = try await session.data(for: urlReq)
            guard let http = response as? HTTPURLResponse else { throw APIError.empty }
            if http.statusCode == 401 {
                // try refresh once
                if await tryRefreshToken() {
                    let retryReq = try buildRequest(req)
                    let (d2, r2) = try await session.data(for: retryReq)
                    return try parse(d2, r2 as? HTTPURLResponse)
                }
                throw APIError.unauthorized
            }
            return try parse(data, http)
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.transport(error)
        }
    }

    // For endpoints that return no JSON (or we don't care)
    func sendVoid(_ req: APIRequest) async throws {
        let urlReq = try buildRequest(req)
        let (_, response) = try await session.data(for: urlReq)
        guard let http = response as? HTTPURLResponse else { throw APIError.empty }
        if http.statusCode == 401 { throw APIError.unauthorized }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.http(http.statusCode, nil)
        }
    }

    // MARK: Build
    private func buildRequest(_ req: APIRequest) throws -> URLRequest {
        var comps = URLComponents(
            url: APIClient.baseURL.appendingPathComponent(req.path),
            resolvingAgainstBaseURL: false
        )
        if !req.query.isEmpty {
            comps?.queryItems = req.query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = comps?.url else { throw APIError.invalidURL }

        var r = URLRequest(url: url)
        r.httpMethod = req.method.rawValue
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.setValue("application/json", forHTTPHeaderField: "Accept")
        r.setValue("Raveng-iOS/1.0", forHTTPHeaderField: "User-Agent")

        if req.requiresAuth, let token = KeychainService.get(.accessToken) {
            r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = req.body {
            r.httpBody = try encoder.encode(AnyEncodable(body))
        }
        r.timeoutInterval = 25
        return r
    }

    // MARK: Parse
    private func parse<T: Decodable>(_ data: Data, _ http: HTTPURLResponse?) throws -> T {
        guard let http else { throw APIError.empty }
        if (200..<300).contains(http.statusCode) {
            do { return try decoder.decode(T.self, from: data) }
            catch { throw APIError.decoding(error) }
        } else {
            let msg = String(data: data, encoding: .utf8)
            throw APIError.http(http.statusCode, msg)
        }
    }

    // MARK: Refresh
    private func tryRefreshToken() async -> Bool {
        guard let refresh = KeychainService.get(.refreshToken) else { return false }
        struct Body: Encodable { let refresh_token: String }
        struct Resp: Decodable {
            let access_token: String
            let refresh_token: String?
        }
        do {
            var url = APIClient.baseURL.appendingPathComponent("auth/refresh")
            var r = URLRequest(url: url)
            r.httpMethod = "POST"
            r.setValue("application/json", forHTTPHeaderField: "Content-Type")
            r.httpBody = try JSONEncoder().encode(Body(refresh_token: refresh))
            let (data, resp) = try await session.data(for: r)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return false }
            let tok = try JSONDecoder().decode(Resp.self, from: data)
            KeychainService.set(tok.access_token, for: .accessToken)
            if let rt = tok.refresh_token { KeychainService.set(rt, for: .refreshToken) }
            _ = url
            return true
        } catch {
            return false
        }
    }
}

// MARK: - AnyEncodable wrapper
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ wrapped: Encodable) {
        self._encode = wrapped.encode
    }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

