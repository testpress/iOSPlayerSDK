//
//  VideoQualityUtilsTests.swift
//  iOSPlayerSDKTests
//
//  Tests for VideoQualityUtils display labels and closest quality selection.
//

import XCTest
@testable import TPStreamsSDK

final class VideoQualityUtilsTests: XCTestCase {

    // MARK: - Display Labels

    func testAutoQualityDisplaysAsAuto() {
        let quality = VideoQuality(resolution: "Auto", bitrate: 0)
        XCTAssertEqual(VideoQualityUtils.getDisplayLabel(for: quality), "Auto")
    }

    func testNonAutoQualityDisplaysWithUpTo() {
        let quality = VideoQuality(resolution: "720p", bitrate: 1_000_000)
        XCTAssertEqual(VideoQualityUtils.getDisplayLabel(for: quality), "Up to 720p")
    }

    func test1080pQualityDisplaysCorrectly() {
        let quality = VideoQuality(resolution: "1080p", bitrate: 3_000_000)
        XCTAssertEqual(VideoQualityUtils.getDisplayLabel(for: quality), "Up to 1080p")
    }

    func test480pQualityDisplaysCorrectly() {
        let quality = VideoQuality(resolution: "480p", bitrate: 500_000)
        XCTAssertEqual(VideoQualityUtils.getDisplayLabel(for: quality), "Up to 480p")
    }

    // MARK: - Select Closest Quality: Exact Match

    func testExactMatchReturnsExactQuality() {
        let qualities = [
            VideoQuality(resolution: "480p", bitrate: 500_000),
            VideoQuality(resolution: "720p", bitrate: 1_000_000),
            VideoQuality(resolution: "1080p", bitrate: 3_000_000)
        ]
        let result = VideoQualityUtils.selectClosestQuality(in: qualities, for: "720p", allowFallback: true)
        XCTAssertEqual(result?.resolution, "720p")
        XCTAssertEqual(result?.bitrate, 1_000_000)
    }

    // MARK: - Select Closest Quality: Fallback

    func testFallbackFindsClosestHigherResolution() {
        let qualities = [
            VideoQuality(resolution: "480p", bitrate: 500_000),
            VideoQuality(resolution: "720p", bitrate: 1_000_000),
            VideoQuality(resolution: "1080p", bitrate: 3_000_000)
        ]
        let result = VideoQualityUtils.selectClosestQuality(in: qualities, for: "540p", allowFallback: true)
        XCTAssertNotNil(result)
        // 540p is between 480 and 720; 540-480=60, 720-540=180; closer to 480p
        XCTAssertEqual(result?.resolution, "480p")
    }

    func testFallbackFindsClosestLowerResolution() {
        let qualities = [
            VideoQuality(resolution: "480p", bitrate: 500_000),
            VideoQuality(resolution: "720p", bitrate: 1_000_000),
            VideoQuality(resolution: "1080p", bitrate: 3_000_000)
        ]
        let result = VideoQualityUtils.selectClosestQuality(in: qualities, for: "710p", allowFallback: true)
        XCTAssertNotNil(result)
        // 710p is between 480 and 720; 710-480=230, 720-710=10; closer to 720p
        XCTAssertEqual(result?.resolution, "720p")
    }

    // MARK: - Select Closest Quality: No Match, No Fallback

    func testNoExactMatchAndFallbackDisabledReturnsNil() {
        let qualities = [
            VideoQuality(resolution: "480p", bitrate: 500_000),
            VideoQuality(resolution: "720p", bitrate: 1_000_000)
        ]
        let result = VideoQualityUtils.selectClosestQuality(in: qualities, for: "1080p", allowFallback: false)
        XCTAssertNil(result)
    }

    // MARK: - Select Closest Quality: Empty List

    func testEmptyQualitiesReturnsNil() {
        let result = VideoQualityUtils.selectClosestQuality(in: [], for: "720p", allowFallback: true)
        XCTAssertNil(result)
    }

    // MARK: - Select Closest Quality: Equal Distance

    func testEqualDistancePrefersLowerResolution() {
        let qualities = [
            VideoQuality(resolution: "480p", bitrate: 500_000),
            VideoQuality(resolution: "720p", bitrate: 1_000_000),
            VideoQuality(resolution: "1080p", bitrate: 3_000_000)
        ]
        // 600 is equidistant from 480 (120) and 720 (120)
        let result = VideoQualityUtils.selectClosestQuality(in: qualities, for: "600p", allowFallback: true)
        XCTAssertEqual(result?.resolution, "480p", "Equal distance should prefer lower resolution")
    }

    // MARK: - Resolution Height

    func testResolutionHeightReturnsInteger() {
        let quality = VideoQuality(resolution: "720p", bitrate: 1_000_000)
        XCTAssertEqual(quality.resolutionHeight, 720)
    }

    func testResolutionHeightForAutoReturnsNil() {
        let quality = VideoQuality(resolution: "Auto", bitrate: 0)
        XCTAssertNil(quality.resolutionHeight)
    }

    func testResolutionHeightFor480p() {
        let quality = VideoQuality(resolution: "480p", bitrate: 500_000)
        XCTAssertEqual(quality.resolutionHeight, 480)
    }

    func testResolutionHeightFor1080p() {
        let quality = VideoQuality(resolution: "1080p", bitrate: 3_000_000)
        XCTAssertEqual(quality.resolutionHeight, 1080)
    }
}
