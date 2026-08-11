//
//  TPStreamsSDKTests.swift
//  iOSPlayerSDKTests
//
//  Tests for TPStreamsSDK initialization and provider configuration.
//

import XCTest
@testable import TPStreamsSDK

final class TPStreamsSDKInitializationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset SDK state before each test
        TPStreamsSDK.orgCode = nil
        TPStreamsSDK.authToken = nil
    }

    override func tearDown() {
        // Reset SDK state after each test
        TPStreamsSDK.orgCode = nil
        TPStreamsSDK.authToken = nil
        super.tearDown()
    }

    // MARK: - Provider Selection

    func testInitializeTestpressProvider() throws {
        TPStreamsSDK.initialize(for: .testpress, withOrgCode: "testpress-org")
        XCTAssertEqual(TPStreamsSDK.orgCode, "testpress-org")
        XCTAssertEqual(TPStreamsSDK.provider, .testpress)
    }

    func testInitializeTPStreamsProvider() throws {
        TPStreamsSDK.initialize(for: .tpstreams, withOrgCode: "tpstreams-org")
        XCTAssertEqual(TPStreamsSDK.orgCode, "tpstreams-org")
        XCTAssertEqual(TPStreamsSDK.provider, .tpstreams)
    }

    // MARK: - Provider API Mapping

    func testTestpressProviderUsesTestpressAPI() {
        let apiType = Provider.testpress.API
        XCTAssertTrue(apiType == TestpressAPI.self)
    }

    func testTPStreamsProviderUsesStreamsAPI() {
        let apiType = Provider.tpstreams.API
        XCTAssertTrue(apiType == StreamsAPI.self)
    }

    // MARK: - hasTestpressAuthToken

    func testHasTestpressAuthTokenTrueWhenTestpressAndTokenProvided() {
        TPStreamsSDK.provider = .testpress
        TPStreamsSDK.orgCode = "org"
        TPStreamsSDK.authToken = "test-token"
        XCTAssertTrue(TPStreamsSDK.hasTestpressAuthToken)
    }

    func testHasTestpressAuthTokenFalseWhenTPStreamsProvider() {
        // Set properties directly to avoid side effects of initialize()
        TPStreamsSDK.provider = .tpstreams
        TPStreamsSDK.orgCode = "org"
        TPStreamsSDK.authToken = nil
        XCTAssertFalse(TPStreamsSDK.hasTestpressAuthToken)
    }

    func testHasTestpressAuthTokenFalseWhenNoAuthToken() {
        // Set properties directly to avoid side effects of initialize()
        TPStreamsSDK.provider = .testpress
        TPStreamsSDK.orgCode = "org"
        TPStreamsSDK.authToken = nil
        XCTAssertFalse(TPStreamsSDK.hasTestpressAuthToken)
    }

    func testHasTestpressAuthTokenFalseWhenEmptyAuthToken() {
        // Set properties directly to avoid side effects of initialize()
        TPStreamsSDK.provider = .testpress
        TPStreamsSDK.orgCode = "org"
        TPStreamsSDK.authToken = ""
        XCTAssertFalse(TPStreamsSDK.hasTestpressAuthToken)
    }
}
