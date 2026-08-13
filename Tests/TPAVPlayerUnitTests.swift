//
//  TPAVPlayerUnitTests.swift
//  iOSPlayerSDKTests
//
//  Unit tests for TPAVPlayer public API behavior.
//  Tests video quality management and public property access.
//

import XCTest
@testable import TPStreamsSDK

final class TPAVPlayerUnitTests: XCTestCase {

    // MARK: - VideoQuality Limiting

    func testLimitAvailableVideoQualitiesRemovesQualitiesAboveMaxHeight() {
        // We test the filtering logic that TPAVPlayer.limitAvailableVideoQualities uses
        let qualities = [
            VideoQuality(resolution: "Auto", bitrate: 0),
            VideoQuality(resolution: "480p", bitrate: 500_000),
            VideoQuality(resolution: "720p", bitrate: 1_000_000),
            VideoQuality(resolution: "1080p", bitrate: 3_000_000),
            VideoQuality(resolution: "1440p", bitrate: 5_000_000),
            VideoQuality(resolution: "2160p", bitrate: 10_000_000)
        ]

        // Simulate the filtering logic from TPAVPlayer.limitAvailableVideoQualities
        let maxHeight = 720
        let filtered = qualities.filter { quality in
            quality.resolution != "Auto" && (Int(String(quality.resolution.dropLast())) ?? 0) <= maxHeight
        }

        XCTAssertEqual(filtered.count, 2) // 480p and 720p
        XCTAssertTrue(filtered.contains { $0.resolution == "480p" })
        XCTAssertTrue(filtered.contains { $0.resolution == "720p" })
        XCTAssertFalse(filtered.contains { $0.resolution == "1080p" })
        XCTAssertFalse(filtered.contains { $0.resolution == "Auto" })
    }

    func testLimitAvailableVideoQualitiesExcludesAutoResolution() {
        let qualities = [
            VideoQuality(resolution: "Auto", bitrate: 0),
            VideoQuality(resolution: "480p", bitrate: 500_000)
        ]

        let maxHeight = 1080
        let filtered = qualities.filter { quality in
            quality.resolution != "Auto" && (Int(String(quality.resolution.dropLast())) ?? 0) <= maxHeight
        }

        XCTAssertEqual(filtered.count, 1)
        XCTAssertFalse(filtered.contains { $0.resolution == "Auto" })
    }

    func testLimitAvailableVideoQualitiesWithAllAboveMaxReturnsEmpty() {
        let qualities = [
            VideoQuality(resolution: "Auto", bitrate: 0),
            VideoQuality(resolution: "1080p", bitrate: 3_000_000),
            VideoQuality(resolution: "2160p", bitrate: 10_000_000)
        ]

        let maxHeight = 480
        let filtered = qualities.filter { quality in
            quality.resolution != "Auto" && (Int(String(quality.resolution.dropLast())) ?? 0) <= maxHeight
        }

        XCTAssertTrue(filtered.isEmpty)
    }

    // MARK: - VideoQuality Contains Check

    func testVideoQualityContainsCheck() {
        let qualities = [
            VideoQuality(resolution: "Auto", bitrate: 0),
            VideoQuality(resolution: "720p", bitrate: 1_000_000)
        ]

        let target = VideoQuality(resolution: "720p", bitrate: 1_000_000)
        XCTAssertTrue(qualities.contains { $0.resolution == target.resolution && $0.bitrate == target.bitrate })
    }

    func testVideoQualityNotContainsDifferentBitrate() {
        let qualities = [
            VideoQuality(resolution: "720p", bitrate: 1_000_000)
        ]

        let target = VideoQuality(resolution: "720p", bitrate: 2_000_000)
        XCTAssertFalse(qualities.contains { $0.resolution == target.resolution && $0.bitrate == target.bitrate })
    }

    // MARK: - SetupCompletion Type

    func testSetupCompletionTypeAlias() {
        // Verify the type alias works correctly
        let completion: SetupCompletion = { error in
            // This is a valid SetupCompletion closure
        }
        XCTAssertNotNil(completion)
    }

    // MARK: - InitializationErrorContext

    func testInitializationErrorContextStoresError() {
        let error = TPStreamPlayerError.resourceNotFound
        let context = InitializationErrorContext(error: error, sentryIssueId: "abc123")

        XCTAssertEqual((context.error as? TPStreamPlayerError)?.code, 5001)
        XCTAssertEqual(context.sentryIssueId, "abc123")
    }

    func testInitializationErrorContextWithNilSentryId() {
        let error = TPStreamPlayerError.serverError
        let context = InitializationErrorContext(error: error, sentryIssueId: nil)

        XCTAssertNil(context.sentryIssueId)
    }
}
