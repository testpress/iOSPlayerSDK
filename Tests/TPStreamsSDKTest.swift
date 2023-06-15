//
//  TPStreamsSDKTest.swift
//  iOSPlayerSDKTests
//
//  Created by Prithuvi on 15/06/23.
//

import XCTest
@testable import TPStreamsSDK

final class TPStreamsSDKTest: XCTestCase {

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
    
    func testInitTPAVPlayer() throws {
        let player = TPAVPlayer(assetID: "1234567890", accessToken: "abc123")
        XCTAssertNotNil(player)
    }
}
