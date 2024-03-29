//
//  TestpressAPI.swift
//  TPStreamsSDK
//
//  Created by Testpress on 03/06/23.
//

import Foundation

class TestpressAPI: BaseAPI {
    class override var VIDEO_DETAIL_API: String { 
        return "https://%@.testpress.in/api/v2.5/video_info/%@?access_token=%@" 
    }
    
    class override var DRM_LICENSE_API: String { 
        return "https://%@.testpress.in/api/v2.5/drm_license_key/%@/?access_token=%@&drm_type=fairplay" 
    }
    
    override class func parseAsset(data: Data) throws -> Asset {
        guard let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = responseDict["id"] as? String,
              let title = responseDict["title"] as? String,
              let playbackURL = responseDict["hls_url"] as? String ?? responseDict["url"] as? String,
              let duration = responseDict["duration"] as? Double,
              let status = responseDict["transcoding_status"] as? String,
              let drm_encrypted = responseDict["drm_enabled"] as? Bool else {
            throw NSError(domain: "InvalidResponseError", code: 0)
        }
        let video = Asset.Video(playbackURL: playbackURL, status: status, duration: duration, drm_encrypted: drm_encrypted)
        return Asset(id: id, title: title, video: video)
    }
}
