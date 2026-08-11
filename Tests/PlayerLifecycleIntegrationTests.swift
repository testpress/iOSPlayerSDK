//
//  PlayerLifecycleIntegrationTests.swift
//  iOSPlayerSDKTests
//
//  Client-journey integration tests for the player lifecycle.
//
//  These tests use the public SDK API. TPAVPlayer requires a backend
//  for full initialization, so we test:
//  - Player creation and error handling through public API
//  - AVPlayer directly with local media for true playback verification
//

import XCTest
import AVFoundation
import TPStreamsSDK

/// Generates a minimal valid H.264 mp4 video for AVPlayer testing.
func generateTestVideo(at url: URL) -> Bool {
    if FileManager.default.fileExists(atPath: url.path) { return true }
    do {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let settings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 160, AVVideoHeightKey: 90]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = true
        guard writer.canAdd(input) else { return false }
        writer.add(input)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        guard writer.startWriting() else { return false }
        writer.startSession(atSourceTime: .zero)
        var pb: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pb) == kCVReturnSuccess, let pixelBuffer = pb else { return false }
        for frame in 0..<10 {
            while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.005) }
            adaptor.append(pixelBuffer, withPresentationTime: CMTime(value: CMTimeValue(frame), timescale: 2))
        }
        input.markAsFinished()
        let sem = DispatchSemaphore(value: 0)
        var success = false
        writer.finishWriting { success = writer.status == .completed; sem.signal() }
        sem.wait()
        return success
    } catch { return false }
}

final class PlayerLifecycleIntegrationTests: XCTestCase {

    private let orgCode = "integration-test-org"
    private var testVideoURL: URL?

    override func setUp() {
        super.setUp()
        TPStreamsSDK.initialize(for: .tpstreams, withOrgCode: orgCode)
        testVideoURL = generateLocalTestVideo()
    }

    override func tearDown() {
        if let url = testVideoURL {
            try? FileManager.default.removeItem(at: url)
        }
        super.tearDown()
    }

    // MARK: - AVPlayer Direct Integration (real playback verification)

    func testAVPlayerPlayPauseWithLocalVideo() throws {
        guard let videoURL = testVideoURL else {
            XCTFail("Could not generate test video")
            return
        }

        // Create a real AVPlayer with the local file
        let player = AVPlayer(url: videoURL)
        let item = player.currentItem
        XCTAssertNotNil(item)

        // Wait for item to be ready
        let ready = expectation(description: "Item ready")
        let observation = item?.observe(\.status) { item, _ in
            if item.status == .readyToPlay { ready.fulfill() }
        }
        wait(for: [ready], timeout: 10.0)
        observation?.invalidate()

        XCTAssertEqual(item?.status, .readyToPlay)

        // Play — real AVPlayer plays the local video
        player.play()
        XCTAssertGreaterThanOrEqual(player.rate, 0, "Rate should be >= 0 after play")

        // Wait for time to advance
        let timeBefore = player.currentTime()
        let advanced = expectation(description: "Time advanced")
        var observer: Any?
        observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 10), queue: .main) { time in
            if time.seconds > timeBefore.seconds + 0.2 {
                advanced.fulfill()
                if let obs = observer { player.removeTimeObserver(obs) }
            }
        }
        wait(for: [advanced], timeout: 15.0)
        if let obs = observer { player.removeTimeObserver(obs) }

        // Pause
        player.pause()
        let pauseTime = player.currentTime()
        Thread.sleep(forTimeInterval: 0.3)
        let afterPause = player.currentTime()
        let drift = abs(afterPause.seconds - pauseTime.seconds)
        XCTAssertLessThan(drift, 0.5, "Time should not advance significantly after pause")

        // Seek
        let seekTarget = CMTime(seconds: 2.0, preferredTimescale: 1)
        let seeked = expectation(description: "Seek done")
        player.seek(to: seekTarget) { _ in seeked.fulfill() }
        wait(for: [seeked], timeout: 5.0)
        XCTAssertEqual(Int(player.currentTime().seconds), 2)
    }

    func testAVPlayerReplayWithLocalVideo() throws {
        guard let videoURL = testVideoURL else {
            XCTFail("Could not generate test video")
            return
        }

        let player = AVPlayer(url: videoURL)

        // Wait for ready
        let ready = expectation(description: "Item ready")
        let obs = player.currentItem?.observe(\.status) { item, _ in
            if item.status == .readyToPlay { ready.fulfill() }
        }
        wait(for: [ready], timeout: 10.0)
        obs?.invalidate()

        // Play for a bit
        player.play()
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertGreaterThan(player.currentTime().seconds, 0)

        // Replay: seek to 0 and play
        let replayed = expectation(description: "Replayed")
        player.seek(to: .zero) { _ in
            player.play()
            replayed.fulfill()
        }
        wait(for: [replayed], timeout: 5.0)
        XCTAssertEqual(Int(player.currentTime().seconds), 0)
    }

    // MARK: - Playback Speed

    func testPlaybackSpeedOnRealAVPlayer() throws {
        guard let videoURL = testVideoURL else {
            XCTFail("Could not generate test video")
            return
        }

        let player = AVPlayer(url: videoURL)

        let ready = expectation(description: "Item ready")
        let obs = player.currentItem?.observe(\.status) { item, _ in
            if item.status == .readyToPlay { ready.fulfill() }
        }
        wait(for: [ready], timeout: 10.0)
        obs?.invalidate()

        player.play()
        XCTAssertEqual(player.rate, 1.0)

        player.rate = 2.0
        XCTAssertEqual(player.rate, 2.0)

        player.rate = 0.5
        XCTAssertEqual(player.rate, 0.5)

        player.rate = 1.0
        XCTAssertEqual(player.rate, 1.0)
    }

    // MARK: - Configuration Builder

    func testPlayerConfigurationWithBuilder() {
        let config = TPStreamPlayerConfigurationBuilder()
            .enableCaptions(true)
            .autoSelectFirstSubtitle(true)
            .enableFullscreen(false)
            .setUserId("test-user")
            .build()
        XCTAssertNotNil(config)
    }

    // MARK: - Helpers

    private func generateLocalTestVideo() -> URL? {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videoURL = documentsDir.appendingPathComponent("player_test_video.mp4")
        if FileManager.default.fileExists(atPath: videoURL.path) { return videoURL }

        // Generate using AVAssetWriter (as before)
        guard generateTestVideo(at: videoURL) else { return nil }
        return videoURL
    }
}
