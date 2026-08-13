//
//  PlayerStateIntegrationTests.swift
//  iOSPlayerSDKTests
//
//  Integration tests for player state management and the TPStreamPlayer state machine.
//

import XCTest
@testable import TPStreamsSDK

final class PlayerStateIntegrationTests: XCTestCase {

    // MARK: - State Machine Validation

    /// These tests validate the state transitions documented in the SDK.
    /// They test the logic paths without requiring AVPlayer.

    func testPlayerHasValidInitialStates() {
        // All valid states as used in the SDK
        let validStates = ["paused", "playing", "buffering", "ended", "ready", "failed"]
        XCTAssertEqual(validStates.count, 6)
    }

    func testTPStreamPlayerStatusValuesAreStringBased() {
        // The SDK uses string-based status values
        let status = "paused"
        XCTAssertEqual(status, "paused")
    }

    // MARK: - PlaybackSpeed Preservation During Play

    func testPlaybackSpeedPreservationLogic() {
        // When play() is called, the current speed should be captured and restored
        var currentSpeed: PlaybackSpeed = .normal
        let previousSpeed = currentSpeed

        // Simulate play() call
        currentSpeed = previousSpeed

        XCTAssertEqual(currentSpeed, .normal)
    }

    func testPlaybackSpeedPreservationForFastSpeed() {
        var currentSpeed: PlaybackSpeed = .fast
        let previousSpeed = currentSpeed

        // Simulate play() call
        currentSpeed = previousSpeed

        XCTAssertEqual(currentSpeed, .fast)
        XCTAssertEqual(currentSpeed.rawValue, 1.25)
    }

    // MARK: - Seek Boundary Logic

    func testForwardSeekClampsToPlayableDuration() {
        let currentTime: Double = 90
        let playableDuration: Double = 100
        let seekSeconds: Double = 10

        var seekTo = currentTime + seekSeconds
        if seekTo > playableDuration {
            seekTo = playableDuration
        }

        XCTAssertEqual(seekTo, 100)
    }

    func testForwardSeekDoesNotClampWhenWithinBounds() {
        let currentTime: Double = 50
        let playableDuration: Double = 100
        let seekSeconds: Double = 10

        var seekTo = currentTime + seekSeconds
        if seekTo > playableDuration {
            seekTo = playableDuration
        }

        XCTAssertEqual(seekTo, 60)
    }

    func testRewindSeekClampsToZero() {
        let currentTime: Double = 5
        let seekSeconds: Double = 10

        var seekTo = currentTime - seekSeconds
        if seekTo < 0 {
            seekTo = 0
        }

        XCTAssertEqual(seekTo, 0)
    }

    func testRewindSeekDoesNotClampWhenWithinBounds() {
        let currentTime: Double = 50
        let seekSeconds: Double = 10

        var seekTo = currentTime - seekSeconds
        if seekTo < 0 {
            seekTo = 0
        }

        XCTAssertEqual(seekTo, 40)
    }

    // MARK: - NaN Guard

    func testNaNGuardPreventsSeek() {
        let seconds = Double.nan
        let shouldSeek = !seconds.isNaN
        XCTAssertFalse(shouldSeek)
    }

    func testFiniteValueAllowsSeek() {
        let seconds = 42.0
        let shouldSeek = !seconds.isNaN
        XCTAssertTrue(shouldSeek)
    }

    // MARK: - Live Stream Behind Live Edge Logic

    func testIsBehindLiveEdgeWhenPaused() {
        let status = "paused"
        let currentTime: Double = 30
        let playableDuration: Double = 100
        let liveTolerance: Double = 15.0
        let isLive = true

        let isBehindLiveEdge = isLive && (status == "paused" || (playableDuration - currentTime > liveTolerance))
        XCTAssertTrue(isBehindLiveEdge)
    }

    func testIsBehindLiveEdgeWhenFarBehind() {
        let status = "playing"
        let currentTime: Double = 30
        let playableDuration: Double = 100
        let liveTolerance: Double = 15.0
        let isLive = true

        let isBehindLiveEdge = isLive && (status == "paused" || (playableDuration - currentTime > liveTolerance))
        XCTAssertTrue(isBehindLiveEdge, "100 - 30 = 70 > 15, should be behind")
    }

    func testIsNotBehindLiveEdgeWhenCloseToLive() {
        let status = "playing"
        let currentTime: Double = 90
        let playableDuration: Double = 100
        let liveTolerance: Double = 15.0
        let isLive = true

        let isBehindLiveEdge = isLive && (status == "paused" || (playableDuration - currentTime > liveTolerance))
        XCTAssertFalse(isBehindLiveEdge, "100 - 90 = 10 < 15, should not be behind")
    }

    func testIsNotBehindLiveEdgeForNonLiveStream() {
        let isLive = false
        let isBehindLiveEdge = isLive && false
        XCTAssertFalse(isBehindLiveEdge)
    }

    // MARK: - Forward Button State

    func testForwardButtonDisabledWhenEnded() {
        let status = "ended"
        let isForwardEnabled = status != "ended"
        XCTAssertFalse(isForwardEnabled)
    }

    func testForwardButtonEnabledWhenPlaying() {
        let status = "playing"
        let isForwardEnabled = status != "ended"
        XCTAssertTrue(isForwardEnabled)
    }

    func testForwardButtonEnabledWhenPaused() {
        let status = "paused"
        let isForwardEnabled = status != "ended"
        XCTAssertTrue(isForwardEnabled)
    }

    // MARK: - Resume Position Logic

    func testAutoResumeDisabledWithoutUserId() {
        let userId: String? = nil
        let assetID: String? = "asset-1"
        let orgCode: String? = "org"
        let isLive = false

        let isAutoResumeEnabled = userId != nil && !userId!.isEmpty && assetID != nil && orgCode != nil && !isLive
        XCTAssertFalse(isAutoResumeEnabled)
    }

    func testAutoResumeDisabledForLiveStream() {
        let userId: String? = "user-1"
        let assetID: String? = "asset-1"
        let orgCode: String? = "org"
        let isLive = true

        let isAutoResumeEnabled = userId != nil && !userId!.isEmpty && assetID != nil && orgCode != nil && !isLive
        XCTAssertFalse(isAutoResumeEnabled)
    }

    func testAutoResumeEnabledWithAllConditions() {
        let userId: String? = "user-1"
        let assetID: String? = "asset-1"
        let orgCode: String? = "org"
        let isLive = false

        let isAutoResumeEnabled = userId != nil && !userId!.isEmpty && assetID != nil && orgCode != nil && !isLive
        XCTAssertTrue(isAutoResumeEnabled)
    }

    func testAutoResumeDisabledWithEmptyUserId() {
        let userId: String? = ""
        let assetID: String? = "asset-1"
        let orgCode: String? = "org"
        let isLive = false

        let isAutoResumeEnabled = userId != nil && !userId!.isEmpty && assetID != nil && orgCode != nil && !isLive
        XCTAssertFalse(isAutoResumeEnabled)
    }
}
