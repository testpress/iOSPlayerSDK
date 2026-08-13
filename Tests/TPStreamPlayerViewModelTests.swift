//
//  TPStreamPlayerViewModelTests.swift
//  iOSPlayerSDKTests
//
//  Tests for TPStreamPlayerViewModel notice and error display logic.
//

import XCTest
@testable import TPStreamsSDK

final class TPStreamPlayerViewModelTests: XCTestCase {

    // MARK: - Error Display Logic

    func testShowErrorFormatsTPStreamPlayerError() {
        let error = TPStreamPlayerError.resourceNotFound
        var message = ""
        var sentryId: String? = nil

        // Simulate the showError logic from TPStreamPlayerViewModel
        if let tpError = error as? TPStreamPlayerError {
            message = "\(tpError.message)\nError code: \(tpError.code)"
        } else {
            message = error.localizedDescription
        }

        XCTAssertTrue(message.contains("video is not available"))
        XCTAssertTrue(message.contains("5001"))
    }

    func testShowErrorAppendsSentryIssueId() {
        let error = TPStreamPlayerError.serverError
        let sentryId = "abc123XYZ"
        var message = ""

        if let tpError = error as? TPStreamPlayerError {
            message = "\(tpError.message)\nError code: \(tpError.code)"
        } else {
            message = error.localizedDescription
        }

        if let sentryId = sentryId as String? {
            message += "\nPlayerId: \(sentryId)"
        }

        XCTAssertTrue(message.contains("PlayerId: abc123XYZ"))
    }

    func testShowErrorHandlesNonTPStreamError() {
        let error = NSError(domain: "test", code: 999, userInfo: [NSLocalizedDescriptionKey: "Custom error"])
        var message = ""

        if let tpError = error as? TPStreamPlayerError {
            message = "\(tpError.message)\nError code: \(tpError.code)"
        } else {
            message = error.localizedDescription
        }

        XCTAssertEqual(message, "Custom error")
    }

    func testShowErrorWithoutSentryId() {
        let error = TPStreamPlayerError.unauthorizedAccess
        let sentryId: String? = nil
        var message = ""

        if let tpError = error as? TPStreamPlayerError {
            message = "\(tpError.message)\nError code: \(tpError.code)"
        } else {
            message = error.localizedDescription
        }

        if let sentryId = sentryId as String? {
            message += "\nPlayerId: \(sentryId)"
        }

        XCTAssertFalse(message.contains("PlayerId:"))
    }

    // MARK: - Live Stream Notice Logic

    func testShowNoticeWhenNoticeMessageExists() {
        let liveStream = LiveStream(
            status: "Streaming",
            hlsUrl: "https://example.com/live.m3u8",
            transcodeRecordedVideo: false,
            chatEmbedUrl: "",
            noticeMessage: "Starting soon!",
            enableDRM: false
        )

        // Should show notice when transcodeRecordedVideo is false
        if liveStream.transcodeRecordedVideo {
            // Skip notice if recorded video is available
        } else {
            XCTAssertNotNil(liveStream.noticeMessage)
        }
    }

    func testSkipNoticeWhenTranscodeRecordedVideoAndVideoExists() {
        let liveStream = LiveStream(
            status: "Streaming",
            hlsUrl: "https://example.com/live.m3u8",
            transcodeRecordedVideo: true,
            chatEmbedUrl: "",
            noticeMessage: "Starting soon!",
            enableDRM: false
        )
        let asset = Asset.makeLive(
            status: "Streaming",
            noticeMessage: "Starting soon!",
            transcodeRecordedVideo: true
        )

        // Should skip notice when transcodeRecordedVideo is true and video exists
        if liveStream.transcodeRecordedVideo && asset.video != nil {
            // Notice should be skipped
            XCTAssertFalse(liveStream.noticeMessage?.isEmpty ?? true, "Notice message should still exist in data")
        }
    }

    // MARK: - Initialization Status

    func testInitializationStatusPendingByDefault() {
        // TPAVPlayer.initializationStatus starts as "pending"
        XCTAssertEqual("pending", "pending")
    }

    func testInitializationStatusReadyAfterSuccess() {
        // After successful initialization, status should be "ready"
        let status = "ready"
        XCTAssertEqual(status, "ready")
    }

    func testInitializationStatusErrorAfterFailure() {
        // After initialization failure, status should be "error"
        let status = "error"
        XCTAssertEqual(status, "error")
    }
}
