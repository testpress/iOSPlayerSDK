import Foundation

public final class EncryptionKeyRepository {
    static let shared = EncryptionKeyRepository()
    private let serviceId = "com.tpstreams.iOSPlayerSDK.encryption.keys"
    private let keyPrefix = "VIDEO_ENCRYPTION_KEY_"

    private init() {}

    private func keychainKey(for identifier: String) -> String {
        return keyPrefix + identifier
    }

    public func save(encryptionKey: Data, for identifier: String) {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceId,
            kSecAttrAccount as String: keychainKey(for: identifier)
        ]
        let keychainUpdateAttributes: [String: Any] = [
            kSecValueData as String: encryptionKey
        ]

        let status = SecItemUpdate(keychainQuery as CFDictionary, keychainUpdateAttributes as CFDictionary)
        if status == errSecItemNotFound {
            var insertQuery = keychainQuery
            insertQuery[kSecValueData as String] = encryptionKey
            insertQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(insertQuery as CFDictionary, nil)
            if addStatus != errSecSuccess {
                debugPrint("EncryptionKeyRepository: Failed to save key for \(identifier). Status: \(addStatus)")
            }
        } else if status != errSecSuccess {
            debugPrint("EncryptionKeyRepository: Failed to update key for \(identifier). Status: \(status)")
        }
    }

    public func get(for identifier: String) -> Data? {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceId,
            kSecAttrAccount as String: keychainKey(for: identifier),
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &result)
        return status == errSecSuccess ? result as? Data : nil
    }

    public func delete(for identifier: String) {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceId,
            kSecAttrAccount as String: keychainKey(for: identifier)
        ]
        let status = SecItemDelete(keychainQuery as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            debugPrint("EncryptionKeyRepository: Failed to delete key for \(identifier). Status: \(status)")
        }
    }

    public func deleteAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceId
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            debugPrint("EncryptionKeyRepository: Failed to delete all keys. Status: \(status)")
        }
    }
}
