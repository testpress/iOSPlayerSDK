//
//  TestpressAPI.swift
//  TPStreamsSDK
//
//  Created by Testpress on 03/06/23.
//

import Foundation

class TestpressAPI: BaseAPI {

    private static let testpressiOSAppIdentifier = "ios-app"
    
    class override var VIDEO_DETAIL_API: String { 
        return "https://%@.testpress.in/api/v2.5/video_info/%@/?access_token=%@&v=2"
    }
    
    class override var DRM_LICENSE_API: String { 
        return "https://%@.testpress.in/api/v2.5/drm_license_key/%@/?access_token=%@&drm_type=fairplay&download=%@" 
    }
    
    override class var parser: APIParser {
        return TestpressAPIParser()
    }
    
    override class var userAgentPrefix: String? {
        return testpressiOSAppIdentifier
    }
}
