import Foundation

// MARK: - API namespaced helpers
enum API {

    // MARK: Auth
    enum Auth {
        struct AppleSignInBody: Encodable {
            let identity_token: String
            let authorization_code: String?
            let user: AppleUserName?
        }
        struct AppleUserName: Encodable {
            let firstName: String?
            let lastName: String?
        }
        struct LoginBody: Encodable {
            let email: String
            let password: String
        }

        static func appleSignIn(identityToken: String, code: String?, firstName: String?, lastName: String?) -> APIRequest {
            APIRequest(
                path: "auth/apple_sign_in",
                method: .POST,
                body: AppleSignInBody(
                    identity_token: identityToken,
                    authorization_code: code,
                    user: AppleUserName(firstName: firstName, lastName: lastName)
                ),
                requiresAuth: false
            )
        }
        static func login(email: String, password: String) -> APIRequest {
            APIRequest(path: "auth/login", method: .POST,
                       body: LoginBody(email: email, password: password), requiresAuth: false)
        }
        static func me() -> APIRequest { APIRequest(path: "me") }
        static func logout() -> APIRequest { APIRequest(path: "auth/logout", method: .POST) }
    }

    // MARK: Signer
    enum Signer {
        static func pending() -> APIRequest { APIRequest(path: "signer/pending") }
        static func detail(slug: String) -> APIRequest { APIRequest(path: "signer/submitter/\(slug)") }

        struct SignBody: Encodable {
            let signature_image_base64: String
            let values: [String: String]?
        }
        static func sign(slug: String, signaturePNGBase64: String, values: [String: String]?) -> APIRequest {
            APIRequest(
                path: "signer/submitter/\(slug)/sign",
                method: .POST,
                body: SignBody(signature_image_base64: signaturePNGBase64, values: values)
            )
        }
    }

    // MARK: Admin
    enum Admin {
        static func templates() -> APIRequest { APIRequest(path: "admin/templates") }
        static func submissions(page: Int = 1) -> APIRequest {
            APIRequest(path: "admin/submissions", query: ["page": "\(page)"])
        }
        static func submission(id: Int) -> APIRequest { APIRequest(path: "admin/submissions/\(id)") }
    }

    // MARK: CDC + Apple Pay
    enum Cdc {
        static func createCheckout(slug: String) -> APIRequest {
            APIRequest(path: "cdc/\(slug)/create_checkout", method: .POST)
        }

        struct MerchantValidationBody: Encodable {
            let validation_url: String
        }
        static func merchantValidation(slug: String, validationUrl: String) -> APIRequest {
            APIRequest(
                path: "cdc/\(slug)/apple_pay/merchant_validation",
                method: .POST,
                body: MerchantValidationBody(validation_url: validationUrl)
            )
        }

        struct ApplePayProcessBody: Encodable {
            let payment_token: PaymentTokenDict
        }
        struct PaymentTokenDict: Encodable {
            let paymentData: [String: AnyCodable]
            let paymentMethod: [String: AnyCodable]?
            let transactionIdentifier: String
        }
        static func processApplePay(slug: String, body: ApplePayProcessBody) -> APIRequest {
            APIRequest(path: "cdc/\(slug)/apple_pay/process", method: .POST, body: body)
        }

        static func paymentStatus(slug: String) -> APIRequest {
            APIRequest(path: "cdc/\(slug)/payment_status")
        }
    }

    // MARK: Verify (public, no auth)
    enum Verify {
        struct ByHashBody: Encodable { let document_hash: String }
        static func byHash(_ hash: String) -> APIRequest {
            APIRequest(
                path: "verify/blockchain",
                method: .POST,
                body: ByHashBody(document_hash: hash),
                requiresAuth: false
            )
        }
        static func info(hash: String) -> APIRequest {
            APIRequest(path: "verify/blockchain_info/\(hash)", requiresAuth: false)
        }
    }
}

// MARK: - AnyCodable for Apple Pay payment token (variable shape)
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Bool.self)        { value = v; return }
        if let v = try? c.decode(Int.self)         { value = v; return }
        if let v = try? c.decode(Double.self)      { value = v; return }
        if let v = try? c.decode(String.self)      { value = v; return }
        if let v = try? c.decode([AnyCodable].self){ value = v.map(\.value); return }
        if let v = try? c.decode([String: AnyCodable].self) {
            value = v.mapValues(\.value); return
        }
        value = NSNull()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch value {
        case let v as Bool:    try c.encode(v)
        case let v as Int:     try c.encode(v)
        case let v as Double:  try c.encode(v)
        case let v as String:  try c.encode(v)
        case let v as [Any]:   try c.encode(v.map(AnyCodable.init))
        case let v as [String: Any]: try c.encode(v.mapValues(AnyCodable.init))
        case is NSNull:        try c.encodeNil()
        default:               try c.encodeNil()
        }
    }
}
