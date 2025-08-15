import Foundation
import Security

final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    // If Keychain Sharing is configured with an access group, set it here; otherwise leave nil.
    private var accessGroup: String? {
        // Example: return "group.app.witwork.vpn"
        return nil
    }

    func set(_ value: Data, for key: String) {
        let query: [String: Any] = {
            var q: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
            ]
            if let group = accessGroup { q[kSecAttrAccessGroup as String] = group }
            return q
        }()

        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = value
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }

    func get(_ key: String) -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let group = accessGroup { query[kSecAttrAccessGroup as String] = group }
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return data
    }

    func setString(_ value: String, for key: String) {
        if let data = value.data(using: .utf8) { set(data, for: key) }
    }
    func getString(_ key: String) -> String? {
        guard let data = get(key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
