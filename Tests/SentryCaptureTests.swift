//
//  SentryCaptureTests.swift
//  iOSPlayerSDKTests
//
//  Tests for Sentry error capture utility functions.
//

import XCTest
@testable import TPStreamsSDK

final class SentryCaptureTests: XCTestCase {

    // MARK: - generateRandomString

    func testGenerateRandomStringDefaultLength() {
        let result = generateRandomString()
        XCTAssertEqual(result.count, 11)
    }

    func testGenerateRandomStringCustomLength() {
        let result = generateRandomString(length: 20)
        XCTAssertEqual(result.count, 20)
    }

    func testGenerateRandomStringWithZeroLength() {
        let result = generateRandomString(length: 0)
        XCTAssertEqual(result.count, 0)
    }

    func testGenerateRandomStringContainsOnlyValidCharacters() {
        let validCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        let result = generateRandomString(length: 100)
        let scalars = result.unicodeScalars
        for scalar in scalars {
            XCTAssertTrue(validCharacters.contains(scalar), "Character \(scalar) should be in valid set")
        }
    }

    func testGenerateRandomStringIsRandom() {
        let result1 = generateRandomString()
        let result2 = generateRandomString()
        // With 62^11 possible strings, collision is astronomically unlikely
        // This test is not 100% deterministic but practically always passes
        XCTAssertNotEqual(result1, result2, "Two random strings should almost certainly be different")
    }
}
