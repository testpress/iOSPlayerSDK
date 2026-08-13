//
//  TPStreamPlayerConfigurationTests.swift
//  iOSPlayerSDKTests
//
//  Tests for TPStreamPlayerConfiguration defaults, builder, and computed properties.
//

import XCTest
@testable import TPStreamsSDK

final class TPStreamPlayerConfigurationTests: XCTestCase {

    // MARK: - Default Values

    func testDefaultPreferredForwardDuration() {
        let config = TPStreamPlayerConfiguration()
        XCTAssertEqual(config.preferredForwardDuration, 10.0)
    }

    func testDefaultPreferredRewindDuration() {
        let config = TPStreamPlayerConfiguration()
        XCTAssertEqual(config.preferredRewindDuration, 10.0)
    }

    func testDefaultShowDownloadOption() {
        let config = TPStreamPlayerConfiguration()
        XCTAssertFalse(config.showDownloadOption)
    }

    func testDefaultDownloadMetadata() {
        let config = TPStreamPlayerConfiguration()
        XCTAssertNil(config.downloadMetadata)
    }

    func testDefaultLicenseDurationSeconds() {
        let config = TPStreamPlayerConfiguration()
        XCTAssertNil(config.licenseDurationSeconds)
    }

    func testDefaultStartInFullscreen() {
        let config = TPStreamPlayerConfiguration()
        XCTAssertFalse(config.startInFullscreen)
    }

    func testDefaultEnableFullscreen() {
        let config = TPStreamPlayerConfiguration()
        XCTAssertTrue(config.enableFullscreen)
    }

    func testDefaultEnablePlaybackSpeed() {
        let config = TPStreamPlayerConfiguration()
        XCTAssertTrue(config.enablePlaybackSpeed)
    }

    func testDefaultShowResolutionOptions() {
        let config = TPStreamPlayerConfiguration()
        XCTAssertTrue(config.showResolutionOptions)
    }

    func testDefaultEnableSeekButtons() {
        let config = TPStreamPlayerConfiguration()
        XCTAssertTrue(config.enableSeekButtons)
    }

    func testDefaultEnableCaptions() {
        let config = TPStreamPlayerConfiguration()
        XCTAssertFalse(config.enableCaptions)
    }

    func testDefaultAutoSelectFirstSubtitle() {
        let config = TPStreamPlayerConfiguration()
        XCTAssertFalse(config.autoSelectFirstSubtitle)
    }

    func testDefaultUserId() {
        let config = TPStreamPlayerConfiguration()
        XCTAssertNil(config.userId)
    }

    // MARK: - Computed Property: showSettingsButton

    func testShowSettingsButtonTrueWhenPlaybackSpeedEnabled() {
        var config = TPStreamPlayerConfiguration()
        config.enablePlaybackSpeed = true
        config.showResolutionOptions = false
        config.showDownloadOption = false
        config.enableCaptions = false
        XCTAssertTrue(config.showSettingsButton)
    }

    func testShowSettingsButtonTrueWhenResolutionOptionsShown() {
        var config = TPStreamPlayerConfiguration()
        config.enablePlaybackSpeed = false
        config.showResolutionOptions = true
        config.showDownloadOption = false
        config.enableCaptions = false
        XCTAssertTrue(config.showSettingsButton)
    }

    func testShowSettingsButtonTrueWhenDownloadOptionShown() {
        var config = TPStreamPlayerConfiguration()
        config.enablePlaybackSpeed = false
        config.showResolutionOptions = false
        config.showDownloadOption = true
        config.enableCaptions = false
        XCTAssertTrue(config.showSettingsButton)
    }

    func testShowSettingsButtonTrueWhenCaptionsEnabled() {
        var config = TPStreamPlayerConfiguration()
        config.enablePlaybackSpeed = false
        config.showResolutionOptions = false
        config.showDownloadOption = false
        config.enableCaptions = true
        XCTAssertTrue(config.showSettingsButton)
    }

    func testShowSettingsButtonFalseWhenNothingEnabled() {
        var config = TPStreamPlayerConfiguration()
        config.enablePlaybackSpeed = false
        config.showResolutionOptions = false
        config.showDownloadOption = false
        config.enableCaptions = false
        XCTAssertFalse(config.showSettingsButton)
    }

    // MARK: - Builder

    func testBuilderSetsForwardDuration() {
        let config = TPStreamPlayerConfigurationBuilder()
            .setPreferredForwardDuration(15.0)
            .build()
        XCTAssertEqual(config.preferredForwardDuration, 15.0)
    }

    func testBuilderSetsRewindDuration() {
        let config = TPStreamPlayerConfigurationBuilder()
            .setPreferredRewindDuration(5.0)
            .build()
        XCTAssertEqual(config.preferredRewindDuration, 5.0)
    }

    func testBuilderShowDownloadOption() {
        let config = TPStreamPlayerConfigurationBuilder()
            .showDownloadOption()
            .build()
        XCTAssertTrue(config.showDownloadOption)
    }

    func testBuilderSetsDownloadMetadata() {
        let metadata: [String: Any] = ["key": "value"]
        let config = TPStreamPlayerConfigurationBuilder()
            .setDownloadMetadata(metadata)
            .build()
        XCTAssertNotNil(config.downloadMetadata)
    }

    func testBuilderSetsLicenseDuration() {
        let config = TPStreamPlayerConfigurationBuilder()
            .setLicenseDurationSeconds(86400)
            .build()
        XCTAssertEqual(config.licenseDurationSeconds, 86400)
    }

    func testBuilderSetsStartInFullscreen() {
        let config = TPStreamPlayerConfigurationBuilder()
            .setStartInFullscreen(true)
            .build()
        XCTAssertTrue(config.startInFullscreen)
    }

    func testBuilderEnableFullscreenFalse() {
        let config = TPStreamPlayerConfigurationBuilder()
            .enableFullscreen(false)
            .build()
        XCTAssertFalse(config.enableFullscreen)
    }

    func testBuilderEnablePlaybackSpeedFalse() {
        let config = TPStreamPlayerConfigurationBuilder()
            .enablePlaybackSpeed(false)
            .build()
        XCTAssertFalse(config.enablePlaybackSpeed)
    }

    func testBuilderShowResolutionOptionsFalse() {
        let config = TPStreamPlayerConfigurationBuilder()
            .showResolutionOptions(false)
            .build()
        XCTAssertFalse(config.showResolutionOptions)
    }

    func testBuilderEnableSeekButtonsFalse() {
        let config = TPStreamPlayerConfigurationBuilder()
            .enableSeekButtons(false)
            .build()
        XCTAssertFalse(config.enableSeekButtons)
    }

    func testBuilderEnableCaptionsTrue() {
        let config = TPStreamPlayerConfigurationBuilder()
            .enableCaptions(true)
            .build()
        XCTAssertTrue(config.enableCaptions)
    }

    func testBuilderAutoSelectFirstSubtitleTrue() {
        let config = TPStreamPlayerConfigurationBuilder()
            .autoSelectFirstSubtitle(true)
            .build()
        XCTAssertTrue(config.autoSelectFirstSubtitle)
    }

    func testBuilderSetsUserId() {
        let config = TPStreamPlayerConfigurationBuilder()
            .setUserId("user-123")
            .build()
        XCTAssertEqual(config.userId, "user-123")
    }

    func testBuilderChainingReturnsSameType() {
        let builder = TPStreamPlayerConfigurationBuilder()
            .setPreferredForwardDuration(20)
            .setPreferredRewindDuration(5)
            .enableFullscreen(false)
            .enableCaptions(true)
        XCTAssertTrue(type(of: builder) == TPStreamPlayerConfigurationBuilder.self)
    }

    func testBuilderBuildReturnsConfiguration() {
        let config = TPStreamPlayerConfigurationBuilder().build()
        XCTAssertTrue(type(of: config) == TPStreamPlayerConfiguration.self)
    }

    func testBuilderWithAllOptions() {
        let config = TPStreamPlayerConfigurationBuilder()
            .setPreferredForwardDuration(30)
            .setPreferredRewindDuration(15)
            .showDownloadOption()
            .setLicenseDurationSeconds(604800)
            .setStartInFullscreen(true)
            .enableFullscreen(false)
            .enablePlaybackSpeed(false)
            .showResolutionOptions(false)
            .enableSeekButtons(false)
            .enableCaptions(true)
            .autoSelectFirstSubtitle(true)
            .setUserId("test-user")
            .build()

        XCTAssertEqual(config.preferredForwardDuration, 30)
        XCTAssertEqual(config.preferredRewindDuration, 15)
        XCTAssertTrue(config.showDownloadOption)
        XCTAssertEqual(config.licenseDurationSeconds, 604800)
        XCTAssertTrue(config.startInFullscreen)
        XCTAssertFalse(config.enableFullscreen)
        XCTAssertFalse(config.enablePlaybackSpeed)
        XCTAssertFalse(config.showResolutionOptions)
        XCTAssertFalse(config.enableSeekButtons)
        XCTAssertTrue(config.enableCaptions)
        XCTAssertTrue(config.autoSelectFirstSubtitle)
        XCTAssertEqual(config.userId, "test-user")
    }
}
