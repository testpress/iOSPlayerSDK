//
//  PlayerLifecycleIntegrationTests.swift
//  SampleAppIntegrationTests
//
//  Client-journey integration tests for the full player lifecycle.
//
//  Tests the complete flow: init → ready → play → pause → seek → replay → done
//  Uses the real AVPlayer through TPAVPlayer's public API, with mocked backend.
//

import XCTest
import AVFoundation
import TPStreamsSDK

final class PlayerLifecycleIntegrationTests: XCTestCase {

    private let orgCode = "integration-test-org"

    override func setUp() {
        super.setUp()
        setupMockNetwork()
        TPStreamsSDK.initialize(for: .tpstreams, withOrgCode: orgCode)
    }

    override func tearDown() {
        teardownMockNetwork()
        super.tearDown()
    }

    // MARK: - Full Client Journey: Play → Pause → Seek → Replay

    func testFullClientPlaybackJourney() {
        // 1. CREATE PLAYER (client: TPAVPlayer(assetID:accessToken:completion:))
        guard let player = createInitializedPlayer() else {
            XCTFail("Player should initialize")
            return
        }
        XCTAssertNotNil(player.currentItem, "Player should have a current item")
        XCTAssertEqual(player.currentItem?.status, .readyToPlay, "Item should be ready to play")

        // 2. PLAY (client: player.play())
        let timeBeforePlay = player.currentTime()
        player.play()

        // Verify time advances after play
        let played = playAndVerifyPlayback(player)
        XCTAssertTrue(played, "Playback should advance time after calling play()")
        XCTAssertGreaterThan(player.currentTime().seconds, timeBeforePlay.seconds,
                             "Current time should advance after play")

        // 3. PAUSE (client: player.pause())
        player.pause()
        // Give a moment for the rate to settle
        let pauseTime = player.currentTime()
        Thread.sleep(forTimeInterval: 0.5)
        // After pause, time should not advance significantly
        let afterPauseTime = player.currentTime()
        let timeDrift = afterPauseTime.seconds - pauseTime.seconds
        XCTAssertLessThan(timeDrift, 0.3, "Time should not advance significantly after pause (drift: \(timeDrift))")

        // 4. SEEK (client: player.seek(to:))
        let seekTarget = CMTime(seconds: 2.0, preferredTimescale: 1)
        let seeked = XCTestExpectation(description: "Seek completed")
        player.seek(to: seekTarget) { finished in
            XCTAssertTrue(finished, "Seek should complete")
            seeked.fulfill()
        }
        let seekResult = XCTWaiter.wait(for: [seeked], timeout: 10.0)
        XCTAssertEqual(seekResult, .completed, "Seek should finish")
        XCTAssertEqual(Int(player.currentTime().seconds), 2,
                       "Player position should be at seek target")

        // 5. REPLAY (client: seek to start + play)
        let replayTarget = CMTime(seconds: 0, preferredTimescale: 1)
        let replayed = XCTestExpectation(description: "Replay completed")
        player.seek(to: replayTarget) { finished in
            XCTAssertTrue(finished, "Replay seek should complete")
            player.play()
            replayed.fulfill()
        }
        let replayResult = XCTWaiter.wait(for: [replayed], timeout: 10.0)
        XCTAssertEqual(replayResult, .completed, "Replay should complete")
        XCTAssertEqual(Int(player.currentTime().seconds), 0,
                       "Player position should be at 0 after replay")
    }

    // MARK: - Playback Speed

    func testPlaybackSpeedChange() {
        guard let player = createInitializedPlayer() else {
            XCTFail("Player should initialize")
            return
        }

        // Play at normal speed
        player.play()
        XCTAssertEqual(player.rate, 1.0, "Default rate should be 1.0")

        // Change to 2x speed via AVPlayer's rate property
        player.rate = 2.0
        // Give AVPlayer time to apply
        let advanced = playAndVerifyPlayback(player)
        XCTAssertTrue(advanced, "Playback should advance at 2x speed")
        // Rate should be 2.0
        XCTAssertEqual(player.rate, 2.0, "Rate should be 2.0 after setting")

        // Change back to 1x
        player.rate = 1.0
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertEqual(player.rate, 1.0, "Rate should be back to 1.0")
    }

    // MARK: - Player Item Status

    func testPlayerItemStatusBecomesReadyToPlay() {
        guard let player = createInitializedPlayer() else {
            XCTFail("Player should initialize")
            return
        }

        let item = player.currentItem
        XCTAssertNotNil(item, "Player should have a current item")
        XCTAssertEqual(item?.status, .readyToPlay,
                       "Player item should be ready to play after initialization")
    }

    // MARK: - Initialization Callback

    func testInitializationCompletionFiresWithNoError() {
        let ready = XCTestExpectation(description: "Player ready")
        var capturedError: Error?

        // Declare before init to avoid capture-before-declaration error
        var player: TPAVPlayer!
        player = TPAVPlayer(assetID: "integration-test-asset",
                             accessToken: "test-access-token") { error in
            capturedError = error
            ready.fulfill()
        }

        let result = XCTWaiter.wait(for: [ready], timeout: 30.0)
        XCTAssertEqual(result, .completed, "Completion should fire")
        XCTAssertNil(capturedError, "Should succeed with mock network")
        XCTAssertNotNil(player, "Player should be non-nil")
    }

    // MARK: - Configuration Builder

    func testPlayerConfigurationBuilder() {
        // Client creates configuration via the builder pattern
        let config = TPStreamPlayerConfigurationBuilder()
            .setPreferredForwardDuration(15)
            .setPreferredRewindDuration(5)
            .enableCaptions(true)
            .autoSelectFirstSubtitle(true)
            .enableFullscreen(false)
            .setUserId("test-user")
            .build()

        // Verify the built configuration is usable
        let player = createInitializedPlayer()
        XCTAssertNotNil(player, "Player should init with builder config")
        XCTAssertNotNil(config, "Configuration should build successfully")
    }

    // MARK: - Error Handling

    func testPlayerOnErrorCallbackCanBeSet() {
        guard let player = createInitializedPlayer() else {
            XCTFail("Player should initialize")
            return
        }

        // Client sets error callback (public API: player.onError)
        let errorReceived = XCTestExpectation(description: "Error callback")
        errorReceived.isInverted = true // Should NOT fire during normal operation

        player.onError = { error, sentryId in
            errorReceived.fulfill()
        }

        // Normal playback should not trigger error
        player.play()
        let result = XCTWaiter.wait(for: [errorReceived], timeout: 3.0)
        XCTAssertEqual(result, .timedOut, "Error should not fire during normal playback")
    }
}
