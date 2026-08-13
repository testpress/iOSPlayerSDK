//
//  MockURLProtocol.swift
//  SampleAppIntegrationTests
//
//  URLProtocol subclass that intercepts network requests and returns
//  fixture responses, simulating the TPStreams backend.
//
//  This enables integration tests to exercise the full SDK client path
//  without depending on production servers.
//

import Foundation
import XCTest
import AVFoundation
import TPStreamsSDK

/// A URLProtocol that intercepts HTTP requests and returns configured fixture responses.
class MockURLProtocol: URLProtocol {

    static var requestHandler: ((URLRequest) throws -> (Data, HTTPURLResponse)?)?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
            return
        }
        do {
            guard let (data, response) = try handler(request) else {
                client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
                return
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Test Video Generation

/// Creates a minimal valid mp4 video file at the given URL using AVFoundation.
/// - Parameter url: File URL where the video should be written.
/// - Returns: true if the video was generated successfully.
func generateTestVideo(at url: URL) -> Bool {
    // If file already exists, return true
    if FileManager.default.fileExists(atPath: url.path) { return true }

    do {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 160,
            AVVideoHeightKey: 90,
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = true
        guard writer.canAdd(input) else { return false }
        writer.add(input)

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        guard writer.startWriting() else { return false }
        writer.startSession(atSourceTime: .zero)

        var pixelBuffer: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pixelBuffer) == kCVReturnSuccess,
              let pb = pixelBuffer else { return false }

        // Write 10 frames at 2fps = 5 second video
        for frame in 0..<10 {
            while !input.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.005)
            }
            let time = CMTime(value: CMTimeValue(frame), timescale: 2)
            adaptor.append(pb, withPresentationTime: time)
        }
        input.markAsFinished()

        let sem = DispatchSemaphore(value: 0)
        var success = false
        writer.finishWriting {
            success = writer.status == .completed
            sem.signal()
        }
        sem.wait()
        return success
    } catch {
        return false
    }
}

// MARK: - XCTestCase Helpers

extension XCTestCase {

    /// Sets up the mock network layer with default fixture responses.
    /// Generates a test video file in the app's Documents directory for playback tests.
    func setupMockNetwork(assetResponse: [String: Any]? = nil) {
        // Generate test video in app Documents directory (works on simulator)
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videoURL = documentsDir.appendingPathComponent("test_video.mp4")
        if !FileManager.default.fileExists(atPath: videoURL.path) {
            guard generateTestVideo(at: videoURL) else {
                XCTFail("Could not generate test video")
                return
            }
        }
        guard let loadedVideoData = try? Data(contentsOf: videoURL) else {
            XCTFail("Could not load generated test video")
            return
        }

        var config = MockConfig()
        config.testVideoData = loadedVideoData
        if let customResponse = assetResponse {
            config.assetResponse = customResponse
        }

        MockURLProtocol.requestHandler = { request in
            guard let url = request.url else { return nil }
            return MockResponses.response(for: url, config: config)
        }
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    /// Removes the mock network layer.
    func teardownMockNetwork() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.requestHandler = nil
    }

    /// Creates a TPAVPlayer and waits for initialization. Uses only public SDK API.
    func createInitializedPlayer(
        assetID: String = "integration-test-asset",
        accessToken: String = "test-access-token",
        timeout: TimeInterval = 30.0
    ) -> TPAVPlayer? {
        let ready = XCTestExpectation(description: "Player ready")
        var capturedError: Error?

        var player: TPAVPlayer!
        player = TPAVPlayer(assetID: assetID, accessToken: accessToken) { error in
            capturedError = error
            ready.fulfill()
        }

        let result = XCTWaiter.wait(for: [ready], timeout: timeout)
        guard result == .completed, capturedError == nil else {
            return nil
        }
        return player
    }

    /// Plays the player and waits for playback time to advance.
    @discardableResult
    func playAndVerifyPlayback(_ player: TPAVPlayer, timeout: TimeInterval = 15.0) -> Bool {
        let timeBefore = player.currentTime()
        player.play()

        let advanced = XCTestExpectation(description: "Playback advanced")
        var observer: Any?
        observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 10),
                                                    queue: .main) { time in
            if time.seconds > timeBefore.seconds + 0.2 {
                advanced.fulfill()
                if let obs = observer { player.removeTimeObserver(obs) }
            }
        }

        let result = XCTWaiter.wait(for: [advanced], timeout: timeout)
        if let obs = observer { player.removeTimeObserver(obs) }
        return result == .completed
    }
}
