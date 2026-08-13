//
//  TpstreamsAssetDataTests.swift
//  iOSPlayerSDKTests
//
//  Tests for TpstreamsAssetData network client.
//

import XCTest
@testable import TPStreamsSDK

final class TpstreamsAssetDataTests: XCTestCase {

    private let assetData = TpstreamsAssetData()

    override func setUp() {
        super.setUp()
        // Ensure orgCode is set for body construction
        TPStreamsSDK.orgCode = "test-org"
    }

    override func tearDown() {
        TPStreamsSDK.orgCode = nil
        super.tearDown()
    }

    // MARK: - Response parsing (via fetchLastWatchedPosition)

    func testFetchLastWatchedPositionReturnsNilForEmptyResponse() {
        let expectation = XCTestExpectation(description: "Fetch position")
        assetData.fetchLastWatchedPosition(userId: "user-1", assetID: "asset-1") { position in
            // Network call will fail since there's no server — should return nil
            XCTAssertNil(position)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
    }

    func testFetchLastWatchedPositionDoesNotCrash() {
        let expectation = XCTestExpectation(description: "Fetch position no-crash")
        assetData.fetchLastWatchedPosition(userId: "", assetID: "") { _ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Update/delete (no-crash tests)

    func testUpdateLastWatchedPositionDoesNotCrash() {
        assetData.updateLastWatchedPosition(30.0, userId: "user-1", assetID: "asset-1")
        // Network call is fire-and-forget — just verify no crash
    }

    func testDeleteLastWatchedPositionDoesNotCrash() {
        assetData.deleteLastWatchedPosition(userId: "user-1", assetID: "asset-1")
        // Network call is fire-and-forget — just verify no crash
    }
}
