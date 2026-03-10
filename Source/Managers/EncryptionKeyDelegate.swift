import Foundation
import Alamofire

final class EncryptionKeyDelegate {
    static let shared = EncryptionKeyDelegate()
    
    private let serviceId = "com.tpstreams.iOSPlayerSDK.encryption.keys"
    private let keyPrefix = "VIDEO_ENCRYPTION_KEY_"
    
    private init() {}
    
    private func keychainKey(for identifier: String) -> String {
        return keyPrefix + identifier
    }
    
    func save(encryptionKey: Data, for identifier: String) {
        KeychainUtil.save(data: encryptionKey, service: serviceId, account: keychainKey(for: identifier))
    }
    
    func get(for identifier: String) -> Data? {
        return KeychainUtil.get(service: serviceId, account: keychainKey(for: identifier))
    }
    
    func delete(for identifier: String) {
        KeychainUtil.delete(service: serviceId, account: keychainKey(for: identifier))
    }
    
    func deleteAll() {
        KeychainUtil.deleteAll(service: serviceId)
    }
    
    func prefetchKey(for video: Video, identifier: String, accessToken: String?) {
        fetchKey(assetId: identifier, accessToken: accessToken) { [weak self] keyData in
            if let keyData = keyData {
                self?.save(encryptionKey: keyData, for: identifier)
            } else if let url = URL(string: video.playbackURL) {
                self?.parsePlaylist(url, identifier: identifier, accessToken: accessToken)
            }
        }
    }
    
    private func parsePlaylist(_ playlistURL: URL, identifier: String, accessToken: String?) {
        let headers = makeAuthHeaders(accessToken: accessToken)
        var finalURL = addTokenToURL(playlistURL, accessToken: accessToken) ?? playlistURL
        
        AF.request(finalURL, headers: headers).responseData { [weak self] response in
            guard let data = response.data,
                  let content = String(data: data, encoding: .utf8) else { return }
            
            if content.contains("#EXT-X-STREAM-INF") {
                self?.handleVariantPlaylist(content, baseURL: playlistURL, identifier: identifier, accessToken: accessToken)
                return
            }
            
            self?.extractAndSaveKey(from: content, identifier: identifier, baseURL: playlistURL, accessToken: accessToken)
        }
    }
    
    private func handleVariantPlaylist(_ content: String, baseURL: URL, identifier: String, accessToken: String?) {
        guard let variantLine = content.components(separatedBy: .newlines)
            .first(where: { $0.contains(".m3u8") && !$0.hasPrefix("#") }),
              let variantURL = URL(string: variantLine.trimmingCharacters(in: .whitespaces), relativeTo: baseURL) else {
            return
        }
        parsePlaylist(variantURL, identifier: identifier, accessToken: accessToken)
    }
    
    private func extractAndSaveKey(from content: String, identifier: String, baseURL: URL, accessToken: String?) {
        guard let keyURL = extractKeyURL(from: content, baseURL: baseURL) else { return }
        
        fetchKey(url: keyURL, accessToken: accessToken) { [weak self] data in
            if let data = data {
                self?.save(encryptionKey: data, for: identifier)
            }
        }
    }
    
    private func extractKeyURL(from content: String, baseURL: URL) -> URL? {
        let pattern = "#EXT-X-KEY:METHOD=AES-128,URI=\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
              let uriRange = Range(match.range(at: 1), in: content) else {
            return nil
        }
        let uri = String(content[uriRange])
        return URL(string: uri, relativeTo: baseURL)
    }
    
    func fetchKey(assetId: String? = nil, url: URL? = nil, accessToken: String?, completion: @escaping (Data?) -> Void) {
        guard let requestURL = buildRequestURL(assetId: assetId, url: url) else {
            completion(nil)
            return
        }
        
        var finalURL = addTokenToURL(requestURL, accessToken: accessToken) ?? requestURL
        let headers = makeAuthHeaders(accessToken: accessToken)
        
        AF.request(finalURL, headers: headers).responseData { response in
            completion(try? response.result.get())
        }
    }
    
    private func buildRequestURL(assetId: String?, url: URL?) -> URL? {
        if let url = url { return url }
        
        guard let assetId = assetId,
              let org = TPStreamsSDK.orgCode else { return nil }
        
        let template = TPStreamsSDK.provider.API.AES_ENCRYPTION_KEY_API
        return URL(string: String(format: template, org, assetId))
    }
    
    private func addTokenToURL(_ url: URL, accessToken: String?) -> URL? {
        guard let token = accessToken, !token.isEmpty,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return url
        }
        
        var items = components.queryItems ?? []
        if !items.contains(where: { $0.name == "access_token" }) {
            items.append(URLQueryItem(name: "access_token", value: token))
            components.queryItems = items
        }
        return components.url
    }
    
    private func makeAuthHeaders(accessToken: String?) -> HTTPHeaders {
        if let token = TPStreamsSDK.authToken {
            return ["Authorization": "JWT \(token)"]
        }
        return [:]
    }
}
