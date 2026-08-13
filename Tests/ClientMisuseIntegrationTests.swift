//
//  ClientMisuseIntegrationTests.swift
//  iOSPlayerSDKTests
//
//  Tests edge cases that real clients may accidentally trigger.
//  Uses only public TPStreamsSDK APIs.
//

import XCTest
import TPStreamsSDK

final class ClientMisuseIntegrationTests: XCTestCase {

    private let orgCode = "integration-test-org"

    override func setUp() {
        super.setUp()
        TPStreamsSDK.initialize(for: .tpstreams, withOrgCode: orgCode)
    }

    // MARK: - Configuration Edge Cases

    func testConfigurationWithAllOptions() {
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

    func testConfigurationWithMinimalOptions() {
        let config = TPStreamPlayerConfigurationBuilder()
            .enableCaptions(true)
            .setUserId("test-user")
            .build()
        XCTAssertNotNil(config)
    }
}
