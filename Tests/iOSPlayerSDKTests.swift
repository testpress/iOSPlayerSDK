//
//  iOSPlayerSDKTests.swift
//  iOSPlayerSDKTests
//
//  Created by Bharath on 30/05/23.
//

import XCTest
@testable import TPStreamsSDK

final class iOSPlayerSDKTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset SDK state before each test
        TPStreamsSDK.orgCode = nil
        TPStreamsSDK.authToken = nil
    }
    
    override func tearDown() {
        TPStreamsSDK.orgCode = nil
        TPStreamsSDK.authToken = nil
        super.tearDown()
    }

    func testInitializeTestpress() throws {
        // Set properties directly to avoid side effects of initialize()
        TPStreamsSDK.provider = .testpress
        TPStreamsSDK.orgCode = "testpress"

        XCTAssertEqual(TPStreamsSDK.orgCode, "testpress")
        XCTAssertEqual(TPStreamsSDK.provider, .testpress)
    }
    
    func testInitializeTPStreams() throws {
        // Set properties directly to avoid side effects of initialize()
        TPStreamsSDK.provider = .tpstreams
        TPStreamsSDK.orgCode = "tpstreams"

        XCTAssertEqual(TPStreamsSDK.orgCode, "tpstreams")
        XCTAssertEqual(TPStreamsSDK.provider, .tpstreams)
    }
}
