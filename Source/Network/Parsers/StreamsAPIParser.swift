//
//  StreamsAPIParser.swift
//  TPStreamsSDK
//
//  Created by Testpress on 13/06/24.
//

import Foundation

class StreamsAPIParser: APIParser {
    func parseAsset(data: Data) throws -> Asset {
        guard let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let video = responseDict["video"] as? [String: Any],
              let id = responseDict["id"] as? String,
              let title = responseDict["title"] as? String,
              let playbackURL = video["playback_url"] as? String,
              let status = video["status"] as? String,
              let content_protection_type = video["content_protection_type"] as? String else {
            throw NSError(domain: "InvalidResponseError", code: 0)
        }
        
        return Asset(
            id: id,
            title: title,
            video: Video(
                playbackURL: playbackURL,
                status: status,
                drmEncrypted: content_protection_type == "drm"
            )
        )
    }
}
