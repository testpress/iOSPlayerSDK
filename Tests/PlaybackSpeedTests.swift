//
//  PlaybackSpeedTests.swift
//  iOSPlayerSDKTests
//
//  Tests for PlaybackSpeed enum values, labels, and CaseIterable conformance.
//

import XCTest
@testable import TPStreamsSDK

final class PlaybackSpeedTests: XCTestCase {

    // MARK: - All Cases

    func testAllCasesCount() {
        XCTAssertEqual(PlaybackSpeed.allCases.count, 6)
    }

    func testAllCasesContainsExpectedSpeeds() {
        let speeds = PlaybackSpeed.allCases.map { $0.rawValue }
        XCTAssertTrue(speeds.contains(0.5))
        XCTAssertTrue(speeds.contains(0.75))
        XCTAssertTrue(speeds.contains(1.0))
        XCTAssertTrue(speeds.contains(1.25))
        XCTAssertTrue(speeds.contains(1.5))
        XCTAssertTrue(speeds.contains(2.0))
    }

    // MARK: - Individual Speed Labels

    func testVerySlowLabel() {
        XCTAssertEqual(PlaybackSpeed.verySlow.label, "0.5x")
    }

    func testSlowLabel() {
        XCTAssertEqual(PlaybackSpeed.slow.label, "0.75x")
    }

    func testNormalLabel() {
        XCTAssertEqual(PlaybackSpeed.normal.label, "Normal")
    }

    func testFastLabel() {
        XCTAssertEqual(PlaybackSpeed.fast.label, "1.25x")
    }

    func testVeryFastLabel() {
        XCTAssertEqual(PlaybackSpeed.veryFast.label, "1.5x")
    }

    func testDoubleLabel() {
        XCTAssertEqual(PlaybackSpeed.double.label, "2x")
    }

    // MARK: - Individual Raw Values

    func testVerySlowRawValue() {
        XCTAssertEqual(PlaybackSpeed.verySlow.rawValue, 0.5, accuracy: 0.001)
    }

    func testSlowRawValue() {
        XCTAssertEqual(PlaybackSpeed.slow.rawValue, 0.75, accuracy: 0.001)
    }

    func testNormalRawValue() {
        XCTAssertEqual(PlaybackSpeed.normal.rawValue, 1.0, accuracy: 0.001)
    }

    func testFastRawValue() {
        XCTAssertEqual(PlaybackSpeed.fast.rawValue, 1.25, accuracy: 0.001)
    }

    func testVeryFastRawValue() {
        XCTAssertEqual(PlaybackSpeed.veryFast.rawValue, 1.5, accuracy: 0.001)
    }

    func testDoubleRawValue() {
        XCTAssertEqual(PlaybackSpeed.double.rawValue, 2.0, accuracy: 0.001)
    }

    // MARK: - Init from Raw Value

    func testInitFromValidRawValue() {
        XCTAssertEqual(PlaybackSpeed(rawValue: 1.0), .normal)
        XCTAssertEqual(PlaybackSpeed(rawValue: 0.5), .verySlow)
        XCTAssertEqual(PlaybackSpeed(rawValue: 2.0), .double)
    }

    func testInitFromInvalidRawValueReturnsNil() {
        XCTAssertNil(PlaybackSpeed(rawValue: 0.0))
        XCTAssertNil(PlaybackSpeed(rawValue: 3.0))
        XCTAssertNil(PlaybackSpeed(rawValue: -1.0))
    }

    // MARK: - Labels Are Unique

    func testAllLabelsAreUnique() {
        let labels = PlaybackSpeed.allCases.map { $0.label }
        XCTAssertEqual(labels.count, Set(labels).count, "All labels should be unique")
    }

    // MARK: - Labels Are Non-Empty

    func testAllLabelsAreNonEmpty() {
        for speed in PlaybackSpeed.allCases {
            XCTAssertFalse(speed.label.isEmpty, "Label for \(speed) should not be empty")
        }
    }
}
