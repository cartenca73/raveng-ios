import Foundation

// MARK: - User
struct AppUser: Codable, Identifiable, Equatable {
    let id: Int
    let email: String
    let firstName: String?
    let lastName: String?
    let role: String?

    var fullName: String {
        [firstName, lastName].compactMap { $0?.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .ifEmpty(email)
    }

    enum CodingKeys: String, CodingKey {
        case id, email, role
        case firstName = "first_name"
        case lastName  = "last_name"
    }
}

// MARK: - Auth
struct AuthTokens: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int?
    let user: AppUser

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn    = "expires_in"
        case user
    }
}

// MARK: - Submitter / Submission
struct PendingSubmitter: Codable, Identifiable, Equatable {
    let id: Int
    let slug: String
    let name: String?
    let email: String?
    let templateName: String?
    let createdAt: String?
    let feaMode: String?

    enum CodingKeys: String, CodingKey {
        case id, slug, name, email
        case templateName = "template_name"
        case createdAt    = "created_at"
        case feaMode      = "fea_mode"
    }
}

struct SubmitterDetail: Codable, Equatable {
    let id: Int
    let slug: String
    let name: String?
    let email: String?
    let phone: String?
    let status: String?
    let templateName: String?
    let documentUrl: String?
    let feaMode: String?
    let fields: [SubmitterField]?

    enum CodingKeys: String, CodingKey {
        case id, slug, name, email, phone, status, fields
        case templateName = "template_name"
        case documentUrl  = "document_url"
        case feaMode      = "fea_mode"
    }
}

struct SubmitterField: Codable, Identifiable, Equatable {
    let uuid: String
    let name: String?
    let type: String
    let required: Bool?
    let value: String?

    var id: String { uuid }
}

// MARK: - Templates / Submissions (admin)
struct TemplateSummary: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let createdAt: String?
    let submissionsCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name
        case createdAt        = "created_at"
        case submissionsCount = "submissions_count"
    }
}

struct SubmissionSummary: Codable, Identifiable, Equatable {
    let id: Int
    let templateName: String?
    let status: String?
    let createdAt: String?
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case templateName = "template_name"
        case status
        case createdAt    = "created_at"
        case completedAt  = "completed_at"
    }
}

// MARK: - Blockchain Verification
struct BlockchainInfo: Codable, Equatable {
    let documentHash: String
    let signerName: String?
    let signedAt: String?
    let bitcoinTxId: String?
    let blockHeight: Int?
    let merkleRoot: String?
    let otsProofAvailable: Bool?
    let attestation: String?

    enum CodingKeys: String, CodingKey {
        case documentHash      = "document_hash"
        case signerName        = "signer_name"
        case signedAt          = "signed_at"
        case bitcoinTxId       = "bitcoin_txid"
        case blockHeight       = "block_height"
        case merkleRoot        = "merkle_root"
        case otsProofAvailable = "ots_proof_available"
        case attestation
    }
}

// MARK: - Apple Pay / CDC
struct CdcCheckout: Codable, Equatable {
    let checkoutId: String
    let amount: Double
    let currency: String
    let merchantIdentifier: String

    enum CodingKeys: String, CodingKey {
        case checkoutId         = "checkout_id"
        case amount, currency
        case merchantIdentifier = "merchant_identifier"
    }
}

struct CdcPaymentStatus: Codable, Equatable {
    let status: String
    let transactionId: String?
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case status
        case transactionId = "transaction_id"
        case completedAt   = "completed_at"
    }
}

// MARK: - Generic helpers
private extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}
