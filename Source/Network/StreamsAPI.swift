//
//  Client.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 31/05/23.
//

import Foundation

class StreamsAPI: BaseAPI {
    class override var VIDEO_DETAIL_API: String {
        return "https://app.tpstreams.com/api/v1/%@/assets/%@/?access_token=%@"
    }
    
    class override var DRM_LICENSE_API: String {
        return "https://app.tpstreams.com/api/v1/%@/assets/%@/drm_license/?access_token=%@&drm_type=fairplay"
    }
    
    override class func parseAsset(data: Data) throws -> Asset {
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
