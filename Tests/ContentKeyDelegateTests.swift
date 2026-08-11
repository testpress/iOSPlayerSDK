//
//  ContentKeyDelegateTests.swift
//  iOSPlayerSDKTests
//
//  Tests for ContentKeyDelegate key management and file operations.
//

import XCTest
@testable import TPStreamsSDK

final class ContentKeyDelegateTests: XCTestCase {

    private var delegate: ContentKeyDelegate!

    override func setUp() {
        super.setUp()
        delegate = ContentKeyDelegate()
    }

    override func tearDown() {
        // Clean up any test keys
        delegate.cleanupPersistentContentKey()
        delegate = nil
        super.tearDown()
    }

    // MARK: - Content Key File Name

    func testPersistentContentKeyFileNameForContentID() {
        let fileName = ContentKeyDelegate.persistentContentKeyFileName(for: "content-123")
        XCTAssertEqual(fileName, "content-123-Key")
    }

    func testPersistentContentKeyFileNameForDifferentContentID() {
        let fileName = ContentKeyDelegate.persistentContentKeyFileName(for: "drm-content-456")
        XCTAssertEqual(fileName, "drm-content-456-Key")
    }

    func testPersistentContentKeyFileNameForEmptyContentID() {
        let fileName = ContentKeyDelegate.persistentContentKeyFileName(for: "")
        XCTAssertEqual(fileName, "-Key")
    }

    // MARK: - setAssetDetails

    func testSetAssetDetailsUpdatesProperties() {
        delegate.setAssetDetails("asset-1", "token-abc", true, 3600)

        XCTAssertEqual(delegate.assetID, "asset-1")
        XCTAssertEqual(delegate.accessToken, "token-abc")
        XCTAssertTrue(delegate.forOfflinePlayback)
        XCTAssertEqual(delegate.licenseDurationSeconds, 3600)
    }

    func testSetAssetDetailsWithDefaults() {
        delegate.setAssetDetails("asset-1", nil)

        XCTAssertEqual(delegate.assetID, "asset-1")
        XCTAssertNil(delegate.accessToken)
        XCTAssertFalse(delegate.forOfflinePlayback)
        XCTAssertNil(delegate.licenseDurationSeconds)
    }

    // MARK: - Content Key Directory

    func testContentKeyDirectoryIsCreated() {
        let dir = delegate.contentKeyDirectory
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }

    // MARK: - Persistent Content Key URL

    func testGetPersistentContentKeyURLReturnsNilWithoutContentID() {
        delegate.contentID = nil
        let url = delegate.getPersistentContentKeyURL()
        XCTAssertNil(url)
    }

    func testGetPersistentContentKeyURLReturnsURLWithContentID() {
        delegate.contentID = "test-content-id"
        let url = delegate.getPersistentContentKeyURL()
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.path.contains("test-content-id-Key") ?? false)
    }

    // MARK: - Persistent Content Key Exists

    func testIsPersistentContentKeyExistsOnDiskReturnsFalseWhenNoKey() {
        delegate.contentID = "non-existent-key"
        XCTAssertFalse(delegate.isPersistentContentKeyExistsOnDisk())
    }

    // MARK: - Store and Load

    func testStoreAndLoadPersistentContentKey() throws {
        delegate.contentID = "store-test-content"
        let testData = "test-key-data".data(using: .utf8)!
        let expiryDate = Date().addingTimeInterval(86400)

        try delegate.storePersistentContentKey(contentKey: testData, expiryDate: expiryDate)

        // Verify key exists on disk
        XCTAssertTrue(delegate.isPersistentContentKeyExistsOnDisk())
        
        // Verify key can be loaded via URL
        if let url = delegate.getPersistentContentKeyURL() {
            let loaded = delegate.getPersistentContentKey(url)
            XCTAssertEqual(loaded, testData)
        } else {
            XCTFail("Should have a valid content key URL")
        }
    }

    func testLoadOfflineContentKeyReturnsNilWhenNoKey() {
        delegate.contentID = "no-key-exists"
        XCTAssertFalse(delegate.isPersistentContentKeyExistsOnDisk())
    }

    // MARK: - Cleanup

    func testCleanupDoesNotCrashWithNilContentID() {
        delegate.contentID = nil
        delegate.cleanupPersistentContentKey()
        // Cleanup with nil contentID should not crash
        XCTAssertTrue(true)
    }
    
    func testIsPersistentContentKeyExistsOnDiskReturnsFalseWhenContentIDNil() {
        delegate.contentID = nil
        XCTAssertFalse(delegate.isPersistentContentKeyExistsOnDisk())
    }

    // MARK: - Default License Expiry

    func testDefaultLicenseExpirySeconds() {
        XCTAssertEqual(DEFAULT_LICENSE_EXPIRY_SECONDS, 15 * 24 * 60 * 60, accuracy: 1)
    }
}
