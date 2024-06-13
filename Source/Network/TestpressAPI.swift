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
    
    override class var parser: APIParser {
        return TestpressAPIParser()
    }
}
