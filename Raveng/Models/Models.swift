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
struct PendingSubmitter: Codable, Identifiable, Hashable {
    let id: Int
    let slug: String
    let name: String?
    let email: String?
    let documentName: String?
    let createdAt: String?
    let feaMode: String?
    let completedAt: String?

    // UI compat
    var templateName: String? { documentName }

    enum CodingKeys: String, CodingKey {
        case id, slug, name, email
        case documentName = "document_name"
        case createdAt    = "created_at"
        case feaMode      = "fea_mode"
        case completedAt  = "completed_at"
    }
}

// Server returns: { submitter: {...}, submission: {...}, preview_url: "..." }
struct SubmitterDetail: Decodable, Equatable {
    let submitter: SubmitterInfo
    let submission: SubmissionInfo?
    let previewUrl: String?

    enum CodingKeys: String, CodingKey {
        case submitter, submission
        case previewUrl = "preview_url"
    }

    // Flat accessors used by the UI
    var id: Int            { submitter.id }
    var slug: String       { submitter.slug }
    var name: String?      { submitter.name }
    var email: String?     { submitter.email }
    var phone: String?     { submitter.phone }
    var feaMode: String?   { submitter.feaMode }
    var documentUrl: String? { previewUrl }
    var templateName: String? { submission?.name ?? submitter.documentName }
    var status: String?    { submission?.status }
    var fields: [SubmitterField]? { nil }  // fields arrivano via submission.fields se servono
}

struct SubmitterInfo: Decodable, Equatable {
    let id: Int
    let slug: String
    let email: String?
    let name: String?
    let phone: String?
    let completedAt: String?
    let submissionId: Int?
    let feaMode: String?
    let documentName: String?

    enum CodingKeys: String, CodingKey {
        case id, slug, email, name, phone
        case completedAt   = "completed_at"
        case submissionId  = "submission_id"
        case feaMode       = "fea_mode"
        case documentName  = "document_name"
    }
}

struct SubmissionInfo: Decodable, Equatable {
    let id: Int
    let templateId: Int?
    let name: String?
    let status: String?
    let createdAt: String?
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status
        case templateId   = "template_id"
        case createdAt    = "created_at"
        case completedAt  = "completed_at"
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
struct TemplateSummary: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let createdAt: String?
    let submittersCount: Int?
    let fieldsCount: Int?

    // UI compat
    var submissionsCount: Int? { submittersCount }

    enum CodingKeys: String, CodingKey {
        case id, name
        case createdAt        = "created_at"
        case submittersCount  = "submitters_count"
        case fieldsCount      = "fields_count"
    }
}

struct TemplateDetail: Decodable, Equatable {
    let template: TemplateInfo
    let stats: TemplateStats
    let submissions: [SubmissionSummary]
}

struct TemplateInfo: Decodable, Equatable {
    let id: Int
    let name: String
    let slug: String?
    let createdAt: String?
    let updatedAt: String?
    let archivedAt: String?
    let fieldsCount: Int?
    let submittersCount: Int?
    let author: String?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, author
        case createdAt       = "created_at"
        case updatedAt       = "updated_at"
        case archivedAt      = "archived_at"
        case fieldsCount     = "fields_count"
        case submittersCount = "submitters_count"
    }
}

struct TemplateStats: Decodable, Equatable {
    let total: Int
    let completed: Int
    let pending: Int
    let submitters: Int
}

struct SubmissionSummary: Codable, Identifiable, Hashable {
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
