import Foundation
import Alamofire
import Security

private let serviceId = "com.tpstreams.iOSPlayerSDK.encryption.keys"
private let keyPrefix = "VIDEO_ENCRYPTION_KEY_"

public final class EncryptionKeyRepository {
    static let shared = EncryptionKeyRepository()
    
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
    
    public static func prefetchEncryptionKey(for video: Video, accessToken: String?, assetId: String? = nil) {
        guard let canonicalId = video.keyIdentifier ?? assetId, !canonicalId.isEmpty else { return }
        
        fetchEncryptionKey(videoId: canonicalId, accessToken: accessToken) { keyData in
            if let keyData = keyData {
                EncryptionKeyRepository.shared.save(encryptionKey: keyData, for: canonicalId)
            } else if let url = URL(string: video.playbackURL) {
                parsePlaylistForEncryptionKey(url, canonicalId, accessToken: accessToken)
            }
        }
    }
    
    private static func parsePlaylistForEncryptionKey(_ playlistURL: URL, _ identifier: String, accessToken: String?) {
        let headers: HTTPHeaders = TPStreamsSDK.authToken.map { ["Authorization": "JWT \($0)"] } ?? [:]
        
        var finalURL = playlistURL
        if let token = accessToken, !token.isEmpty,
           var comp = URLComponents(url: playlistURL, resolvingAgainstBaseURL: true) {
            var items = comp.queryItems ?? []
            if !items.contains(where: { $0.name == "access_token" }) {
                items.append(URLQueryItem(name: "access_token", value: token))
                comp.queryItems = items
                finalURL = comp.url ?? playlistURL
            }
        }
        
        AF.request(finalURL, headers: headers).responseData { response in
            guard let data = response.data, let playlistContent = String(data: data, encoding: .utf8) else { return }
            
            if playlistContent.contains("#EXT-X-STREAM-INF") {
                if let variant = playlistContent.components(separatedBy: .newlines).first(where: { $0.contains(".m3u8") && !$0.hasPrefix("#") }),
                   let url = URL(string: variant.trimmingCharacters(in: .whitespaces), relativeTo: playlistURL) {
                    parsePlaylistForEncryptionKey(url, identifier, accessToken: accessToken)
                }
                return
            }
            
            let pattern = "#EXT-X-KEY:.*URI=\"([^\"]+)\""
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: playlistContent, options: [], range: NSRange(playlistContent.startIndex..., in: playlistContent)),
                  let uriRange = Range(match.range(at: 1), in: playlistContent) else { return }
            
            let uri = String(playlistContent[uriRange])
            guard let keyURL = URL(string: uri, relativeTo: playlistURL) else { return }
            
            fetchEncryptionKey(url: keyURL, accessToken: accessToken) { data in
                if let data = data { EncryptionKeyRepository.shared.save(encryptionKey: data, for: identifier) }
            }
        }
    }
    
    static func fetchEncryptionKey(videoId: String? = nil, url: URL? = nil, accessToken: String?, completion: @escaping (Data?) -> Void) {
        guard let requestURL: URL = {
            if let url = url { return url }
            guard let videoId = videoId, let org = TPStreamsSDK.orgCode else { return nil }
            let apiTemplate = TPStreamsSDK.provider.API.AES_ENCRYPTION_KEY_API
            return URL(string: String(format: apiTemplate, org, videoId))
        }() else { completion(nil); return }
        
        var comp = URLComponents(url: requestURL, resolvingAgainstBaseURL: true)
        if let token = accessToken, !token.isEmpty {
            var items = comp?.queryItems ?? []
            if !items.contains(where: { $0.name == "access_token" }) {
                items.append(URLQueryItem(name: "access_token", value: token))
                comp?.queryItems = items
            }
        }
        
        let headers: HTTPHeaders = TPStreamsSDK.authToken.map { ["Authorization": "JWT \($0)"] } ?? [:]
        AF.request(comp?.url ?? requestURL, headers: headers).responseData { response in
            completion(try? response.result.get())
        }
    }
}
