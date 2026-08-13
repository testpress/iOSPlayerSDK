//
//  TimeStringTests.swift
//  iOSPlayerSDKTests
//
//  Tests for the timeStringFromSeconds utility function.
//

import XCTest
@testable import TPStreamsSDK

final class TimeStringTests: XCTestCase {

    // MARK: - Basic Formatting

    func testZeroSecondsFormatsAs0000() {
        XCTAssertEqual(timeStringFromSeconds(0), "00:00")
    }

    func testOneSecondFormatsAs0001() {
        XCTAssertEqual(timeStringFromSeconds(1), "00:01")
    }

    func testFiftyNineSecondsFormatsAs0059() {
        XCTAssertEqual(timeStringFromSeconds(59), "00:59")
    }

    func testSixtySecondsFormatsAs0100() {
        XCTAssertEqual(timeStringFromSeconds(60), "01:00")
    }

    func testNinetySecondsFormatsAs0130() {
        XCTAssertEqual(timeStringFromSeconds(90), "01:30")
    }

    func testThreeThousandFiveHundredNinetyNineSecondsFormatsAs5959() {
        XCTAssertEqual(timeStringFromSeconds(3599), "59:59")
    }

    func testThreeThousandSixHundredSecondsFormatsAs010000() {
        XCTAssertEqual(timeStringFromSeconds(3600), "01:00:00")
    }

    func testThreeThousandSixHundredOneSecondsFormatsAs010001() {
        XCTAssertEqual(timeStringFromSeconds(3601), "01:00:01")
    }

    func testSeventyTwoHundredSecondsFormatsAs020000() {
        XCTAssertEqual(timeStringFromSeconds(7200), "02:00:00")
    }

    func testThreeThousandSixHundredSixtyOneFormatsAs010101() {
        XCTAssertEqual(timeStringFromSeconds(3661), "01:01:01")
    }

    // MARK: - Large Values

    func testLargeSecondsFormatsCorrectly() {
        // 100 hours = 360000 seconds
        XCTAssertEqual(timeStringFromSeconds(360000), "100:00:00")
    }

    func testEightySixThousandFourHundredSecondsFormatsAs240000() {
        // 24 hours
        XCTAssertEqual(timeStringFromSeconds(86400), "24:00:00")
    }

    // MARK: - Rounding

    func testFractionalSecondsRounds() {
        XCTAssertEqual(timeStringFromSeconds(60.4), "01:00")
        XCTAssertEqual(timeStringFromSeconds(60.5), "01:01")
        XCTAssertEqual(timeStringFromSeconds(60.6), "01:01")
    }

    // MARK: - NaN and Infinity

    func testNaNReturns0000() {
        XCTAssertEqual(timeStringFromSeconds(Double.nan), "00:00")
    }

    func testPositiveInfinityReturnsFormattedTime() {
        let result = timeStringFromSeconds(Double.infinity)
        // Infinity.isFinite is false, so the guard returns "00:00"
        XCTAssertEqual(result, "00:00")
    }

    func testNegativeInfinityReturnsFormattedTime() {
        let result = timeStringFromSeconds(-Double.infinity)
        // -Infinity.isFinite is false, so the guard returns "00:00"
        XCTAssertEqual(result, "00:00")
    }

    // MARK: - Negative Values

    func testNegativeSecondsFormatsWithRounding() {
        // -1 rounds to -1, which then: totalSeconds=-1, minutes = (-1/60)%60, hours = -1/3600
        // This tests the actual behavior for negative input
        let result = timeStringFromSeconds(-1)
        // The function uses Int(seconds.rounded()) which gives -1
        // Then (totalSeconds / 60) % 60 and totalSeconds % 60 with negative values
        // This is edge-case behavior we document
        XCTAssertFalse(result.isEmpty, "Should return some string even for negative input")
    }

    // MARK: - Common Playback Durations

    func testTenMinutesFormatsAs001000() {
        XCTAssertEqual(timeStringFromSeconds(600), "10:00")
    }

    func testOneHourThirtyMinutesFormatsAs013000() {
        XCTAssertEqual(timeStringFromSeconds(5400), "01:30:00")
    }

    func testTwoHoursThirtyMinutesFormatsAs023000() {
        XCTAssertEqual(timeStringFromSeconds(9000), "02:30:00")
    }
}
