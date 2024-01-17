//
//  TestpressAPI.swift
//  TPStreamsSDK
//
//  Created by Testpress on 03/06/23.
//

import Foundation

class TestpressAPI: BaseAPI {
    class override var VIDEO_DETAIL_API: String { 
        return "https://%@.testpress.in/api/v2.5/video_info/%@" 
    }

    class override var DRM_LICENSE_API: String { 
        return "https://%@.testpress.in/api/v2.5/drm_license_key/%@/&drm_type=fairplay"
    }
    
    class override var AUTH_TOKEN_PREFIX: String {
        return "JWT"
    }

    override class func parseAsset(data: Data) throws -> Asset {
        guard let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = responseDict["id"] as? String,
              let title = responseDict["title"] as? String,
              let playbackURL = responseDict["hls_url"] as? String ?? responseDict["url"] as? String,
              let status = responseDict["transcoding_status"] as? String else {
            throw NSError(domain: "InvalidResponseError", code: 0)
        }
        let video = Asset.Video(playbackURL: playbackURL, status: status)
        return Asset(id: id, title: title, video: video)
    }
}
