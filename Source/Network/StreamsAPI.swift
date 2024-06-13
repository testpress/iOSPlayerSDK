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
    
    override class var parser: APIParser {
        return StreamsAPIParser()
    }
}
