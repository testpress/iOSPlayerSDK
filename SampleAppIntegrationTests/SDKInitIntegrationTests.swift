//
//  SDKInitIntegrationTests.swift
//  SampleAppIntegrationTests
//
//  Client-style integration tests for SDK initialization.
//  Uses only public TPStreamsSDK APIs — exactly as a real client does.
//

import XCTest
import TPStreamsSDK

final class SDKInitIntegrationTests: XCTestCase {

    private let orgCode = "integration-test-org"

    override func setUp() {
        super.setUp()
        // Mock must be set up before any SDK calls (including Sentry init)
        setupMockNetwork()
        // Initialize the SDK as a real client would
        TPStreamsSDK.initialize(for: .tpstreams, withOrgCode: orgCode)
    }

    override func tearDown() {
        teardownMockNetwork()
        super.tearDown()
    }

    // MARK: - SDK Init

    func testSDKInitDoesNotCrash() {
        // Calling initialize again should not crash
        XCTAssertNoThrow(TPStreamsSDK.initialize(for: .tpstreams, withOrgCode: orgCode))
    }

    func testSDKInitMultipleProvidersDoesNotCrash() {
        TPStreamsSDK.initialize(for: .testpress, withOrgCode: orgCode)
        TPStreamsSDK.initialize(for: .tpstreams, withOrgCode: orgCode)
        // Should not crash from multiple Sentry init or audio session conflicts
    }

    // MARK: - Player Creation

    func testCreatePlayerSucceeds() {
        guard let player = createInitializedPlayer() else {
            XCTFail("Player should initialize with mock network")
            return
        }
        XCTAssertNotNil(player.currentItem, "Player should have a current item")
    }

    func testCreatePlayerWithMultipleInstances() {
        let p1 = createInitializedPlayer(assetID: "integration-test-asset", accessToken: "token-1")
        let p2 = createInitializedPlayer(assetID: "integration-test-asset", accessToken: "token-2")

        XCTAssertNotNil(p1, "First player should initialize")
        XCTAssertNotNil(p2, "Second player should initialize")
        XCTAssertNotIdentical(p1, p2, "Should be distinct instances")
    }
}
