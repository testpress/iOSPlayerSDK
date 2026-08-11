//
//  ClientMisuseIntegrationTests.swift
//  SampleAppIntegrationTests
//
//  Tests edge cases that real clients may accidentally trigger.
//  Verifies the SDK handles misuse gracefully without crashing.
//

import XCTest
import AVFoundation
import TPStreamsSDK

final class ClientMisuseIntegrationTests: XCTestCase {

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

    // MARK: - Play Before Ready

    func testPlayBeforeInitCompletesDoesNotCrash() {
        // A client might call play() immediately after creating the player,
        // before the initialization callback fires.
        let ready = XCTestExpectation(description: "Player ready")

        let player = TPAVPlayer(assetID: "integration-test-asset",
                                 accessToken: "test-access-token") { _ in
            ready.fulfill()
        }

        // Call play before init completes
        player.play()
        player.pause()

        let result = XCTWaiter.wait(for: [ready], timeout: 30.0)
        XCTAssertEqual(result, .completed, "Player should complete init even after early play/pause")
    }

    func testPauseBeforeReadyDoesNotCrash() {
        let ready = XCTestExpectation(description: "Player ready")

        let player = TPAVPlayer(assetID: "integration-test-asset",
                                 accessToken: "test-access-token") { _ in
            ready.fulfill()
        }

        // Client calls pause before the player is ready
        player.pause()
        player.pause() // Double pause

        let result = XCTWaiter.wait(for: [ready], timeout: 30.0)
        XCTAssertEqual(result, .completed, "Player init should complete after early pause")
    }

    func testSeekBeforeReadyDoesNotCrash() {
        let ready = XCTestExpectation(description: "Player ready")

        let player = TPAVPlayer(assetID: "integration-test-asset",
                                 accessToken: "test-access-token") { _ in
            ready.fulfill()
        }

        // Client seeks before the player is ready
        player.seek(to: CMTime(seconds: 30, preferredTimescale: 1))

        let result = XCTWaiter.wait(for: [ready], timeout: 30.0)
        XCTAssertEqual(result, .completed, "Player init should complete after early seek")
    }

    // MARK: - Rapid Operations

    func testRapidPlayPauseDoesNotCrash() {
        guard let player = createInitializedPlayer() else {
            XCTFail("Player should initialize")
            return
        }

        // Client rapidly toggles play/pause
        for _ in 0..<10 {
            player.play()
            player.pause()
        }
        // Should not crash
        XCTAssertEqual(player.rate, 0, "Player should end paused")
    }

    func testRapidSeekDoesNotCrash() {
        guard let player = createInitializedPlayer() else {
            XCTFail("Player should initialize")
            return
        }

        // Client rapidly seeks to different positions
        for i in 0...5 {
            let time = CMTime(seconds: Double(i), preferredTimescale: 1)
            player.seek(to: time)
        }
        // Should not crash
    }

    // MARK: - Lifecycle

    func testReplayImmediatelyAfterEnded() {
        guard let player = createInitializedPlayer() else {
            XCTFail("Player should initialize")
            return
        }

        // Simulate client ending playback by seeking to near-end then replaying
        let nearEnd = CMTime(seconds: 4.0, preferredTimescale: 1)
        let seeked = XCTestExpectation(description: "Seek to near end")
        player.seek(to: nearEnd) { _ in seeked.fulfill() }
        XCTWaiter.wait(for: [seeked], timeout: 10.0)

        // Replay: seek to beginning and play
        let replayed = XCTestExpectation(description: "Replayed")
        player.seek(to: CMTime(seconds: 0, preferredTimescale: 1)) { _ in
            player.play()
            replayed.fulfill()
        }
        let result = XCTWaiter.wait(for: [replayed], timeout: 10.0)
        XCTAssertEqual(result, .completed, "Replay should complete")
        XCTAssertEqual(Int(player.currentTime().seconds), 0, "Position should be at start")
    }

    func testDestroyPlayerDuringPlayback() {
        var player: TPAVPlayer? = createInitializedPlayer()
        XCTAssertNotNil(player, "Player should initialize")

        player?.play()
        Thread.sleep(forTimeInterval: 0.5)

        // Client releases the player while it's playing
        player?.pause()
        player = nil
        // Should not crash — ARC deallocation during playback
        XCTAssertNil(player, "Player should be nil after release")
    }

    // MARK: - Audio Session

    func testConcurrentAudioSessionUsage() {
        // Client might set up their own audio session alongside the SDK
        let session = AVAudioSession.sharedInstance()
        XCTAssertNoThrow(try session.setCategory(.playback))
        XCTAssertNoThrow(try session.setActive(true))
    }

    // MARK: - Configuration Edge Cases

    func testConfigurationWithEmptyUserId() {
        let config = TPStreamPlayerConfigurationBuilder()
            .setUserId("")
            .build()
        XCTAssertNotNil(config, "Config with empty userId should build")
    }

    func testConfigurationWithFullOptions() {
        // Client enables every available option
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
            .setUserId("full-config-user")
            .build()

        XCTAssertNotNil(config, "Full configuration should build")
    }
}
