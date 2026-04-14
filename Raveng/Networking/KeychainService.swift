import Foundation
import Security

enum KeychainKey: String {
    case accessToken  = "raveng.access_token"
    case refreshToken = "raveng.refresh_token"
    case userJSON     = "raveng.user_json"
}

enum KeychainService {
    @discardableResult
    static func set(_ value: String, for key: KeychainKey) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(q as CFDictionary)
        var add = q
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    static func get(_ key: KeychainKey) -> String? {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data,
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    @discardableResult
    static func delete(_ key: KeychainKey) -> Bool {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]
        return SecItemDelete(q as CFDictionary) == errSecSuccess
    }

    static func clearAll() {
        delete(.accessToken); delete(.refreshToken); delete(.userJSON)
    }
}
