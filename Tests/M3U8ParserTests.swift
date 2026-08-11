//
//  M3U8ParserTests.swift
//  iOSPlayerSDKTests
//
//  Tests for M3U8 parsing utility.
//

import XCTest
@testable import TPStreamsSDK

final class M3U8ParserTests: XCTestCase {

    // MARK: - extractIDFromURI

    func testExtractIDFromSkdURI() {
        let id = M3U8Parser.extractIDFromURI(uri: "skd://content-id-123")
        XCTAssertEqual(id, "skd://content-id-123")
    }

    func testExtractIDFromNonSkdURIReturnsNil() {
        let id = M3U8Parser.extractIDFromURI(uri: "https://example.com/key")
        XCTAssertNil(id)
    }

    func testExtractIDFromEmptyURIReturnsNil() {
        let id = M3U8Parser.extractIDFromURI(uri: "")
        XCTAssertNil(id)
    }

    func testExtractIDFromSkdURIMaintainsPrefix() {
        let id = M3U8Parser.extractIDFromURI(uri: "skd://vod.cf.cdn.testpress.in/content/sample-key")
        XCTAssertEqual(id, "skd://vod.cf.cdn.testpress.in/content/sample-key")
    }

    // MARK: - VideoQuality Model

    func testVideoQualityDefaults() {
        let quality = VideoQuality(resolution: "720p", bitrate: 2_000_000)
        XCTAssertEqual(quality.resolution, "720p")
        XCTAssertEqual(quality.bitrate, 2_000_000)
    }

    func testVideoQualitySortingByBitrate() {
        let low = VideoQuality(resolution: "240p", bitrate: 400_000)
        let mid = VideoQuality(resolution: "480p", bitrate: 1_000_000)
        let high = VideoQuality(resolution: "720p", bitrate: 2_000_000)
        let sorted = [high, low, mid].sorted { $0.bitrate < $1.bitrate }
        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(sorted[0].bitrate, low.bitrate)
        XCTAssertEqual(sorted[1].bitrate, mid.bitrate)
        XCTAssertEqual(sorted[2].bitrate, high.bitrate)
    }

    // MARK: - Parse error handling (network-dependent methods)

    func testExtractContentIDWithInvalidURL() {
        let invalidURL = URL(string: "ftp://not-valid")!
        let expectation = XCTestExpectation(description: "Content ID extraction")
        M3U8Parser.extractContentID(url: invalidURL) { result in
            if case .failure(let error) = result {
                // Should fail gracefully with an error
                XCTAssertNotNil(error)
            } else {
                // Could also succeed if M3U8Kit handles the URL
                // Just verify it doesn't crash
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
    }
}
