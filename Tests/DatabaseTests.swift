//
//  DatabaseTests.swift
//  iOSPlayerSDKTests
//
//  Tests for ObjectManager, LocalOfflineAsset, and OfflineAsset model.
//

import XCTest
import RealmSwift
@testable import TPStreamsSDK

final class DatabaseTests: XCTestCase {

    override func setUp() {
        super.setUp()
        configureInMemoryRealm(for: self)
    }

    override func tearDown() {
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
        super.tearDown()
    }

    // MARK: - ObjectManager: Add and Get

    func testAddAndGetObject() {
        let asset = LocalOfflineAsset.make(assetId: "test-1", title: "Test Video")
        LocalOfflineAsset.manager.add(object: asset)

        let retrieved = LocalOfflineAsset.manager.get(id: "test-1")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.assetId, "test-1")
        XCTAssertEqual(retrieved?.title, "Test Video")
    }

    func testGetNonExistentObjectReturnsNil() {
        let retrieved = LocalOfflineAsset.manager.get(id: "non-existent")
        XCTAssertNil(retrieved)
    }

    // MARK: - ObjectManager: Exists

    func testExistsReturnsTrueForExistingObject() {
        let asset = LocalOfflineAsset.make(assetId: "test-1")
        LocalOfflineAsset.manager.add(object: asset)
        XCTAssertTrue(LocalOfflineAsset.manager.exists(id: "test-1"))
    }

    func testExistsReturnsFalseForNonExistentObject() {
        XCTAssertFalse(LocalOfflineAsset.manager.exists(id: "non-existent"))
    }

    // MARK: - ObjectManager: GetAll

    func testGetAllReturnsAllObjects() {
        let asset1 = LocalOfflineAsset.make(assetId: "a1", title: "Video 1")
        let asset2 = LocalOfflineAsset.make(assetId: "a2", title: "Video 2")
        let asset3 = LocalOfflineAsset.make(assetId: "a3", title: "Video 3")
        LocalOfflineAsset.manager.add(object: asset1)
        LocalOfflineAsset.manager.add(object: asset2)
        LocalOfflineAsset.manager.add(object: asset3)

        let all = LocalOfflineAsset.manager.getAll()
        XCTAssertEqual(all.count, 3)
    }

    func testGetAllReturnsEmptyWhenNoObjects() {
        let all = LocalOfflineAsset.manager.getAll()
        XCTAssertEqual(all.count, 0)
    }

    // MARK: - ObjectManager: Update

    func testUpdateExistingObject() {
        let asset = LocalOfflineAsset.make(assetId: "test-1", title: "Original Title")
        LocalOfflineAsset.manager.add(object: asset)

        LocalOfflineAsset.manager.update(id: "test-1", with: ["title": "Updated Title"])

        let retrieved = LocalOfflineAsset.manager.get(id: "test-1")
        XCTAssertEqual(retrieved?.title, "Updated Title")
    }

    func testUpdateNonExistentObjectDoesNotCrash() {
        // Should not crash when updating non-existent object
        LocalOfflineAsset.manager.update(id: "non-existent", with: ["title": "New"])
    }

    func testUpdateStatus() {
        let asset = LocalOfflineAsset.make(assetId: "test-1", status: Status.notStarted.rawValue)
        LocalOfflineAsset.manager.add(object: asset)

        LocalOfflineAsset.manager.update(id: "test-1", with: ["status": Status.inProgress.rawValue])

        let retrieved = LocalOfflineAsset.manager.get(id: "test-1")
        XCTAssertEqual(retrieved?.status, Status.inProgress.rawValue)
    }

    // MARK: - ObjectManager: Delete

    func testDeleteExistingObject() {
        let asset = LocalOfflineAsset.make(assetId: "test-1")
        LocalOfflineAsset.manager.add(object: asset)
        XCTAssertTrue(LocalOfflineAsset.manager.exists(id: "test-1"))

        LocalOfflineAsset.manager.delete(id: "test-1")
        XCTAssertFalse(LocalOfflineAsset.manager.exists(id: "test-1"))
    }

    func testDeleteNonExistentObjectDoesNotCrash() {
        // Should not crash
        LocalOfflineAsset.manager.delete(id: "non-existent")
    }

    // MARK: - LocalOfflineAsset: Create Factory

    func testCreateLocalOfflineAsset() {
        let asset = LocalOfflineAsset.make(
            assetId: "asset-1",
            title: "Test Video",
            srcURL: "https://example.com/video.m3u8",
            resolution: "720p",
            duration: 3600,
            bitRate: 1_000_000
        )

        XCTAssertEqual(asset.assetId, "asset-1")
        XCTAssertEqual(asset.title, "Test Video")
        XCTAssertEqual(asset.srcURL, "https://example.com/video.m3u8")
        XCTAssertEqual(asset.resolution, "720p")
        XCTAssertEqual(asset.duration, 3600)
        XCTAssertEqual(asset.bitRate, 1_000_000)
    }

    func testCreateLocalOfflineAssetSizeCalculation() {
        let asset = LocalOfflineAsset.make(
            assetId: "asset-1",
            duration: 60,
            bitRate: 1_000_000
        )
        // size = bitRate * duration = 1_000_000 * 60 = 60_000_000
        XCTAssertEqual(asset.size, 60_000_000, accuracy: 1)
    }

    func testCreateLocalOfflineAssetDefaultStatus() {
        let asset = LocalOfflineAsset.make(assetId: "asset-1")
        // Realm Object @Persisted default values only apply when object is managed
        // When unmanaged, the property is set by the factory method
        XCTAssertFalse(asset.status.isEmpty, "Status should not be empty")
    }

    // MARK: - LocalOfflineAsset: asOfflineAsset

    func testAsOfflineAssetCopiesFields() {
        let local = LocalOfflineAsset.make(
            assetId: "asset-1",
            title: "Test Video",
            resolution: "1080p",
            duration: 120,
            bitRate: 2_000_000
        )

        let offline = local.asOfflineAsset()
        XCTAssertEqual(offline.assetId, "asset-1")
        XCTAssertEqual(offline.title, "Test Video")
        XCTAssertEqual(offline.resolution, "1080p")
        XCTAssertEqual(offline.duration, 120)
        XCTAssertEqual(offline.bitRate, 2_000_000)
    }

    // MARK: - LocalOfflineAsset: asAsset

    func testAsAssetCreatesVideoWithDownloadedURL() {
        let local = LocalOfflineAsset.make(
            assetId: "asset-1",
            title: "Test Video",
            duration: 120
        )
        local.downloadedPath = "path/to/file"

        let asset = local.asAsset()
        XCTAssertEqual(asset.id, "asset-1")
        XCTAssertEqual(asset.title, "Test Video")
        XCTAssertNotNil(asset.video)
        XCTAssertTrue(asset.playbackURL?.contains("file://") ?? false)
    }

    func testAsAssetSetsDRMEncryptedWhenDRMContentIdExists() {
        let local = LocalOfflineAsset.make(
            assetId: "asset-1",
            drmContentId: "drm-123"
        )
        local.downloadedPath = "path/to/file"

        let asset = local.asAsset()
        XCTAssertTrue(asset.video?.drmEncrypted ?? false)
        XCTAssertEqual(asset.drmContentId, "drm-123")
    }

    func testAsAssetNotDRMWhenNoDRMContentId() {
        let local = LocalOfflineAsset.make(
            assetId: "asset-1",
            drmContentId: nil
        )
        local.downloadedPath = "path/to/file"

        let asset = local.asAsset()
        XCTAssertFalse(asset.video?.drmEncrypted ?? true)
    }

    // MARK: - LocalOfflineAsset: downloadedFileURL

    func testDownloadedFileURLReturnsNilWhenPathEmpty() {
        let local = LocalOfflineAsset.make(assetId: "asset-1")
        local.downloadedPath = ""
        XCTAssertNil(local.downloadedFileURL)
    }

    func testDownloadedFileURLReturnsURLWhenPathExists() {
        let local = LocalOfflineAsset.make(assetId: "asset-1")
        local.downloadedPath = "path/to/file.m3u8"
        let url = local.downloadedFileURL
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.path.contains("path/to/file.m3u8") ?? false)
    }

    // MARK: - LocalOfflineAsset: isOfflineLicenseExpired

    func testIsOfflineLicenseExpiredWhenNoExpiryDate() {
        let local = LocalOfflineAsset.make(assetId: "asset-1")
        local.licenseExpiryDate = nil
        XCTAssertTrue(local.isOfflineLicenseExpired())
    }

    func testIsOfflineLicenseExpiredWhenExpiryDateInPast() {
        let local = LocalOfflineAsset.make(assetId: "asset-1")
        local.licenseExpiryDate = Date().addingTimeInterval(-3600) // 1 hour ago
        XCTAssertTrue(local.isOfflineLicenseExpired())
    }

    func testIsOfflineLicenseNotExpiredWhenExpiryDateInFuture() {
        let local = LocalOfflineAsset.make(assetId: "asset-1")
        local.licenseExpiryDate = Date().addingTimeInterval(3600) // 1 hour from now
        XCTAssertFalse(local.isOfflineLicenseExpired())
    }

    // MARK: - OfflineAsset Model

    func testOfflineAssetEquality() {
        let a1 = OfflineAsset(assetId: "1", title: "Video 1")
        let a2 = OfflineAsset(assetId: "1", title: "Video 2") // Different title, same ID
        XCTAssertEqual(a1, a2, "OfflineAsset equality should be based on assetId")
    }

    func testOfflineAssetInequality() {
        let a1 = OfflineAsset(assetId: "1", title: "Video 1")
        let a2 = OfflineAsset(assetId: "2", title: "Video 1")
        XCTAssertNotEqual(a1, a2)
    }

    func testOfflineAssetHashable() {
        let a1 = OfflineAsset(assetId: "1", title: "Video 1")
        let a2 = OfflineAsset(assetId: "1", title: "Video 2")
        var set = Set<OfflineAsset>()
        set.insert(a1)
        set.insert(a2)
        XCTAssertEqual(set.count, 1, "Same assetId should result in same hash")
    }

    // MARK: - Status Enum

    func testStatusRawValues() {
        XCTAssertEqual(Status.notStarted.rawValue, "notStarted")
        XCTAssertEqual(Status.inProgress.rawValue, "inProgress")
        XCTAssertEqual(Status.paused.rawValue, "paused")
        XCTAssertEqual(Status.finished.rawValue, "finished")
        XCTAssertEqual(Status.failed.rawValue, "failed")
        XCTAssertEqual(Status.deleted.rawValue, "deleted")
    }
}
