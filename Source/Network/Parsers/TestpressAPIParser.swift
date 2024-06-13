//
//  TestpressAPIParser.swift
//  TPStreamsSDK
//
//  Created by Testpress on 13/06/24.
//

import Foundation

class TestpressAPIParser: APIParser {
    func parseAsset(data: Data) throws -> Asset {
        guard let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = responseDict["id"] as? String,
              let title = responseDict["title"] as? String,
              let playbackURL = responseDict["hls_url"] as? String ?? responseDict["url"] as? String,
              let status = responseDict["transcoding_status"] as? String,
              let drmEncrypted = responseDict["drm_enabled"] as? Bool else {
            throw NSError(domain: "InvalidResponseError", code: 0)
        }
        let video = Video(playbackURL: playbackURL, status: status, drmEncrypted: drmEncrypted)
        return Asset(id: id, title: title, video: video)
    }
}
