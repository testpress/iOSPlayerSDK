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
        return "https://app.tpstreams.com/api/v1/%@/assets/%@/drm_license/?access_token=%@&drm_type=fairplay&download=%@"
    }

    class override var DRM_LICENSE_API_WITH_EXPIRY: String {
        return "https://app.tpstreams.com/api/v1/%@/assets/%@/drm_license/?access_token=%@&drm_type=fairplay&download=%@&license_duration_seconds=%@&rental_duration_seconds=%@"
    }
    
    override class var parser: APIParser {
        return StreamsAPIParser()
    }
}
