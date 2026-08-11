//
//  SDKInitIntegrationTests.swift
//  iOSPlayerSDKTests
//
//  Client-style integration tests for SDK initialization.
//  Uses only public TPStreamsSDK APIs.
//

import XCTest
import TPStreamsSDK

final class SDKInitIntegrationTests: XCTestCase {

    private let orgCode = "integration-test-org"

    override func setUp() {
        super.setUp()
        TPStreamsSDK.initialize(for: .tpstreams, withOrgCode: orgCode)
    }

    // MARK: - SDK Init

    func testSDKInitDoesNotCrash() {
        XCTAssertNoThrow(TPStreamsSDK.initialize(for: .tpstreams, withOrgCode: orgCode))
    }

    func testSDKInitMultipleTimesDoesNotCrash() {
        TPStreamsSDK.initialize(for: .testpress, withOrgCode: orgCode)
        TPStreamsSDK.initialize(for: .tpstreams, withOrgCode: orgCode)
    }

    // MARK: - Configuration Builder

    func testConfigurationBuilderWorks() {
        let config = TPStreamPlayerConfigurationBuilder()
            .enableCaptions(true)
            .autoSelectFirstSubtitle(true)
            .enableFullscreen(false)
            .enablePlaybackSpeed(true)
            .showResolutionOptions(true)
            .enableSeekButtons(true)
            .setUserId("test-user")
            .build()
        XCTAssertNotNil(config)
    }

    func testConfigurationBuilderAllOptions() {
        let config = TPStreamPlayerConfigurationBuilder()
            .setPreferredForwardDuration(30)
            .setPreferredRewindDuration(10)
            .setprogressBarThumbColor(.red)
            .setwatchedProgressTrackColor(.blue)
            .showDownloadOption()
            .setStartInFullscreen(true)
            .enableFullscreen(true)
            .enablePlaybackSpeed(true)
            .showResolutionOptions(true)
            .enableSeekButtons(true)
            .enableCaptions(true)
            .autoSelectFirstSubtitle(true)
            .setUserId("test-user")
            .build()
        XCTAssertNotNil(config)
    }
}
