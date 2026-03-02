//
//  AESKeyManager.swift
//  TPStreamsSDK
//
//  Created by Testpress on 13/06/24.
//

import Foundation
import Alamofire

public class AESKeyManager {
    
    // MARK: - Public API
    
    /// Prefetch AES encryption key for offline playback
    /// Strategy: 
    /// 1. Primary: Fetch from dedicated key API endpoint
    /// 2. Fallback: Extract from playlist (only if API fails)
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
        
        let finalURL: URL = {
            guard let token = accessToken, !token.isEmpty,
                  var comp = URLComponents(url: playlistURL, resolvingAgainstBaseURL: true) else { return playlistURL }
            var items = comp.queryItems ?? []
            if !items.contains(where: { $0.name == "access_token" }) {
                items.append(URLQueryItem(name: "access_token", value: token))
                comp.queryItems = items
            }
            return comp.url ?? playlistURL
        }()

        AF.request(finalURL, headers: headers).responseData { response in
            guard let data = response.data, let playlistContent = String(data: data, encoding: .utf8) else { return }

            // Handle Master Playlist (Variants)
            if playlistContent.contains("#EXT-X-STREAM-INF") {
                handleMasterPlaylist(playlistContent, playlistURL, identifier, accessToken)
                return
            }

            // Handle Media Playlist (Encryption Keys)
            handleMediaPlaylist(playlistContent, playlistURL, identifier, accessToken)
        }
    }

    private static func handleMasterPlaylist(_ content: String, _ baseURL: URL, _ identifier: String, _ accessToken: String?) {
        let variant = content.components(separatedBy: .newlines).first(where: { $0.contains(".m3u8") && !$0.hasPrefix("#") })
        if let url = variant.flatMap({ URL(string: $0.trimmingCharacters(in: .whitespaces), relativeTo: baseURL) }) {
            parsePlaylistForEncryptionKey(url, identifier, accessToken: accessToken)
        }
    }

    private static func handleMediaPlaylist(_ content: String, _ baseURL: URL, _ identifier: String, _ accessToken: String?) {
        let pattern = "#EXT-X-KEY:.*URI=\"([^\"]+)\""
        guard let keyLineRange = content.range(of: pattern, options: .regularExpression),
              let uriStartRange = content[keyLineRange].range(of: "URI=\"") else { return }
        
        let uri = content[uriStartRange.upperBound...].split(separator: "\"").first.map(String.init)
        guard let keyURL = uri.flatMap({ URL(string: $0, relativeTo: baseURL) }) else { return }
        
        fetchEncryptionKey(url: keyURL, accessToken: accessToken) { data in
            if let data = data { EncryptionKeyRepository.shared.save(encryptionKey: data, for: identifier) }
        }
    }

    internal static func fetchEncryptionKey(videoId: String? = nil, url: URL? = nil, accessToken: String?, completion: @escaping (Data?) -> Void) {
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
