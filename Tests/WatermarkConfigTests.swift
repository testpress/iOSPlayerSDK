//
//  WatermarkConfigTests.swift
//  iOSPlayerSDKTests
//
//  Tests for WatermarkConfig and WatermarkAnimation models.
//

import XCTest
@testable import TPStreamsSDK

final class WatermarkConfigTests: XCTestCase {

    // MARK: - Default Values

    func testDefaultXIsZero() {
        let config = WatermarkConfig(text: "Test")
        XCTAssertEqual(config.x, 0)
    }

    func testDefaultYIsZero() {
        let config = WatermarkConfig(text: "Test")
        XCTAssertEqual(config.y, 0)
    }

    func testDefaultColorIsWhite() {
        let config = WatermarkConfig(text: "Test")
        XCTAssertEqual(config.color, 0xFFFFFFFF)
    }

    func testDefaultTextSizeIs14() {
        let config = WatermarkConfig(text: "Test")
        XCTAssertEqual(config.textSize, 14)
    }

    func testDefaultOpacityIs03() {
        let config = WatermarkConfig(text: "Test")
        XCTAssertEqual(config.opacity, 0.3, accuracy: 0.001)
    }

    func testDefaultAnimationIsNil() {
        let config = WatermarkConfig(text: "Test")
        XCTAssertNil(config.animation)
    }

    // MARK: - Custom Values

    func testCustomPosition() {
        let config = WatermarkConfig(text: "Test", x: 50, y: 75)
        XCTAssertEqual(config.x, 50)
        XCTAssertEqual(config.y, 75)
    }

    func testCustomColor() {
        let config = WatermarkConfig(text: "Test", color: 0xFF0000FF)
        XCTAssertEqual(config.color, 0xFF0000FF)
    }

    func testCustomTextSize() {
        let config = WatermarkConfig(text: "Test", textSize: 24)
        XCTAssertEqual(config.textSize, 24)
    }

    func testCustomOpacity() {
        let config = WatermarkConfig(text: "Test", opacity: 0.8)
        XCTAssertEqual(config.opacity, 0.8, accuracy: 0.001)
    }

    // MARK: - Text Property

    func testTextIsStored() {
        let config = WatermarkConfig(text: "My Watermark")
        XCTAssertEqual(config.text, "My Watermark")
    }

    func testEmptyTextIsAllowed() {
        let config = WatermarkConfig(text: "")
        XCTAssertEqual(config.text, "")
    }

    // MARK: - Equatable

    func testEqualConfigsAreEqual() {
        let c1 = WatermarkConfig(text: "Test", x: 10, y: 20)
        let c2 = WatermarkConfig(text: "Test", x: 10, y: 20)
        XCTAssertEqual(c1, c2)
    }

    func testDifferentConfigsAreNotEqual() {
        let c1 = WatermarkConfig(text: "Test", x: 10, y: 20)
        let c2 = WatermarkConfig(text: "Test", x: 30, y: 20)
        XCTAssertNotEqual(c1, c2)
    }

    func testDifferentTextNotEqual() {
        let c1 = WatermarkConfig(text: "A")
        let c2 = WatermarkConfig(text: "B")
        XCTAssertNotEqual(c1, c2)
    }

    func testDifferentOpacityNotEqual() {
        let c1 = WatermarkConfig(text: "Test", opacity: 0.5)
        let c2 = WatermarkConfig(text: "Test", opacity: 0.8)
        XCTAssertNotEqual(c1, c2)
    }

    // MARK: - WatermarkAnimation

    func testWatermarkAnimationInit() {
        let anim = WatermarkAnimation(type: .pingPong, duration: 5000)
        XCTAssertEqual(anim.type, .pingPong)
        XCTAssertEqual(anim.duration, 5000)
    }

    func testWatermarkAnimationDefaultDuration() {
        let anim = WatermarkAnimation(type: .pingPong)
        XCTAssertEqual(anim.duration, 10000)
    }

    func testWatermarkAnimationEquatable() {
        let a1 = WatermarkAnimation(type: .pingPong, duration: 5000)
        let a2 = WatermarkAnimation(type: .pingPong, duration: 5000)
        XCTAssertEqual(a1, a2)
    }

    func testWatermarkAnimationNotEqualDifferentDuration() {
        let a1 = WatermarkAnimation(type: .pingPong, duration: 5000)
        let a2 = WatermarkAnimation(type: .pingPong, duration: 10000)
        XCTAssertNotEqual(a1, a2)
    }

    // MARK: - WatermarkAnimationType

    func testPingPongTypeEquality() {
        XCTAssertEqual(WatermarkAnimationType.pingPong, WatermarkAnimationType.pingPong)
    }

    // MARK: - Config with Animation

    func testConfigWithAnimation() {
        let anim = WatermarkAnimation(type: .pingPong, duration: 8000)
        let config = WatermarkConfig(text: "Moving", animation: anim)
        XCTAssertNotNil(config.animation)
        XCTAssertEqual(config.animation?.type, .pingPong)
        XCTAssertEqual(config.animation?.duration, 8000)
    }
}
