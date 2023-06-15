//
//  iOSPlayerSDKTests.swift
//  iOSPlayerSDKTests
//
//  Created by Bharath on 30/05/23.
//

import XCTest
@testable import TPStreamsSDK

final class iOSPlayerSDKTests: XCTestCase {

    func testTPStreamsInitialization() throws {
        let orgCode = "6eafqn"
        TPStreamsSDK.initialize(withOrgCode: orgCode)
            
        XCTAssertEqual(TPStreamsSDK.orgCode, orgCode)
        XCTAssertEqual(TPStreamsSDK.provider, .tpstreams)
    }
        
    func testTestpressInitialization() throws {
        let orgCode = "lmsdemo"
        TPStreamsSDK.initialize(for: .testpress,withOrgCode: orgCode)
            
        XCTAssertEqual(TPStreamsSDK.orgCode, orgCode)
        XCTAssertEqual(TPStreamsSDK.provider, .testpress)
    }

}
