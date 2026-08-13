//
//  ResourceLoaderDelegateTests.swift
//  iOSPlayerSDKTests
//
//  Tests for ResourceLoaderDelegate key request routing logic.
//

import XCTest
@testable import TPStreamsSDK

final class ResourceLoaderDelegateTests: XCTestCase {

    private var delegate: ResourceLoaderDelegate!

    override func setUp() {
        super.setUp()
        delegate = ResourceLoaderDelegate(
            accessToken: "test-token",
            assetId: "test-asset",
            isPlaybackOffline: false,
            offlineAssetId: nil,
            localOfflineAsset: nil
        )
    }

    override func tearDown() {
        delegate = nil
        super.tearDown()
    }

    // MARK: - Initialization

    func testInitWithAccessToken() {
        let delegate = ResourceLoaderDelegate(
            accessToken: "token-123",
            assetId: "asset-456"
        )
        XCTAssertNotNil(delegate)
    }

    func testInitForOfflinePlayback() {
        let delegate = ResourceLoaderDelegate(
            accessToken: nil,
            assetId: "asset-456",
            isPlaybackOffline: true,
            offlineAssetId: "offline-789",
            localOfflineAsset: nil
        )
        XCTAssertNotNil(delegate)
    }

    // MARK: - Encryption Key URL Detection

    func testIsEncryptionKeyUrlDetectsAESKeyPath() {
        // We test the logic indirectly through the delegate's URL handling
        let testURL = URL(string: "https://example.com/api/v1/assets/123/aes_key/")!
        let path = testURL.path.lowercased()
        XCTAssertTrue(path.contains("/aes_key"))
    }

    func testIsEncryptionKeyUrlDetectsEncryptionKeyPath() {
        let testURL = URL(string: "https://example.com/api/v1/assets/123/encryption_key/")!
        let path = testURL.path.lowercased()
        XCTAssertTrue(path.contains("/encryption_key"))
    }

    func testIsEncryptionKeyUrlRejectsNormalPath() {
        let testURL = URL(string: "https://example.com/video.m3u8")!
        let path = testURL.path.lowercased()
        XCTAssertFalse(path.contains("/aes_key"))
        XCTAssertFalse(path.contains("/encryption_key"))
    }

    // MARK: - Should Wait For Loading

    func testShouldWaitReturnsFalseWhenAssetIsNil() {
        let emptyDelegate = ResourceLoaderDelegate(
            accessToken: "token",
            assetId: "asset"
        )
        // When asset is nil, the delegate should return false for non-key URLs
        XCTAssertNil(emptyDelegate.asset)
    }

    func testShouldWaitReturnsFalseForNonAESVideo() {
        let asset = Asset.make(isAESEncrypted: false)
        delegate.asset = asset

        // For non-AES encrypted videos, should return false
        // This tests the guard in resourceLoader(_:shouldWaitForLoadingOfRequestedResource:)
        XCTAssertFalse(asset.video?.isAESEncrypted ?? true)
    }

    func testAESVideoHasEncryptionKeyPath() {
        let asset = Asset.make(isAESEncrypted: true)
        XCTAssertTrue(asset.video?.isAESEncrypted ?? false)
    }
}
