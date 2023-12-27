//
//  iOSPlayerSDKTests.swift
//  iOSPlayerSDKTests
//
//  Created by Bharath on 30/05/23.
//

import XCTest
@testable import TPStreamsSDK

final class iOSPlayerSDKTests: XCTestCase {

    func testInitializeTestpress() throws {
        TPStreamsSDK.initialize(for: .testpress, withOrgCode: "testpress")

        XCTAssertEqual(TPStreamsSDK.orgCode, "testpress")
        XCTAssertEqual(TPStreamsSDK.provider, .testpress)
    }
    
    func testInitializeTPStreams() throws {
        TPStreamsSDK.initialize(for: .tpstreams, withOrgCode: "tpstreams")

        XCTAssertEqual(TPStreamsSDK.orgCode, "tpstreams")
        XCTAssertEqual(TPStreamsSDK.provider, .tpstreams)
    }

}
