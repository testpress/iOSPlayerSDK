import Foundation
import Alamofire

final class EncryptionKeyService {
    static let shared = EncryptionKeyService()
    
    private let repository = EncryptionKeyRepository.shared
    
    private init() {}
    
    func prefetchKey(for video: Video, identifier: String, accessToken: String?) {
        fetchKey(videoId: identifier, accessToken: accessToken) { [weak self] keyData in
            if let keyData = keyData {
                self?.repository.save(encryptionKey: keyData, for: identifier)
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
                self?.repository.save(encryptionKey: data, for: identifier)
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
    
    func fetchKey(videoId: String? = nil, url: URL? = nil, accessToken: String?, completion: @escaping (Data?) -> Void) {
        guard let requestURL = buildRequestURL(videoId: videoId, url: url) else {
            completion(nil)
            return
        }
        
        var finalURL = addTokenToURL(requestURL, accessToken: accessToken) ?? requestURL
        let headers = makeAuthHeaders(accessToken: accessToken)
        
        AF.request(finalURL, headers: headers).responseData { response in
            completion(try? response.result.get())
        }
    }
    
    private func buildRequestURL(videoId: String?, url: URL?) -> URL? {
        if let url = url { return url }
        
        guard let videoId = videoId,
              let org = TPStreamsSDK.orgCode else { return nil }
        
        let template = TPStreamsSDK.provider.API.AES_ENCRYPTION_KEY_API
        return URL(string: String(format: template, org, videoId))
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
