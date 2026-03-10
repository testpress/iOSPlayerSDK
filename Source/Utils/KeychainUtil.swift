import Foundation
import Security

class KeychainUtil {
    
    static func save(data: Data, service: String, account: String) {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let keychainUpdateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(keychainQuery as CFDictionary, keychainUpdateAttributes as CFDictionary)
        if status == errSecItemNotFound {
            var insertQuery = keychainQuery
            insertQuery[kSecValueData as String] = data
            insertQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(insertQuery as CFDictionary, nil)
            if addStatus != errSecSuccess {
                debugPrint("KeychainUtil: Failed to save key for \(account). Status: \(addStatus)")
            }
        } else if status != errSecSuccess {
            debugPrint("KeychainUtil: Failed to update key for \(account). Status: \(status)")
        }
    }
    
    static func get(service: String, account: String) -> Data? {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &result)
        return status == errSecSuccess ? result as? Data : nil
    }
    
    static func delete(service: String, account: String) {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(keychainQuery as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            debugPrint("KeychainUtil: Failed to delete key for \(account). Status: \(status)")
        }
    }
    
    static func deleteAll(service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            debugPrint("KeychainUtil: Failed to delete all keys. Status: \(status)")
        }
    }
}
