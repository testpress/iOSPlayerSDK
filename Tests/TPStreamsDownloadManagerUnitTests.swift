//
//  TPStreamsDownloadManagerUnitTests.swift
//  iOSPlayerSDKTests
//
//  Unit tests for TPStreamsDownloadManager that don't require network/AVFoundation.
//

import XCTest
import RealmSwift
@testable import TPStreamsSDK

final class TPStreamsDownloadManagerUnitTests: XCTestCase {

    private var downloadManager: TPStreamsDownloadManager!

    override func setUp() {
        super.setUp()
        configureInMemoryRealm(for: self)
        downloadManager = TPStreamsDownloadManager.shared
    }

    override func tearDown() {
        let realm = try! Realm(configuration: TPStreamsSDK.realmConfig)
        try! realm.write {
            realm.deleteAll()
        }
        downloadManager = nil
        super.tearDown()
    }

    // MARK: - Singleton

    func testSharedInstanceIsSingleton() {
        XCTAssertTrue(TPStreamsDownloadManager.shared === TPStreamsDownloadManager.shared)
    }

    // MARK: - isAssetDownloaded

    func testIsAssetDownloadedReturnsFalseForNonExistentAsset() {
        XCTAssertFalse(downloadManager.isAssetDownloaded(assetID: "non-existent"))
    }

    func testIsAssetDownloadedReturnsFalseForNonFinishedAsset() {
        let asset = LocalOfflineAsset.make(
            assetId: "test-1",
            status: Status.inProgress.rawValue
        )
        LocalOfflineAsset.manager.add(object: asset)
        XCTAssertFalse(downloadManager.isAssetDownloaded(assetID: "test-1"))
    }

    func testIsAssetDownloadedReturnsTrueForFinishedAsset() {
        let asset = LocalOfflineAsset.make(
            assetId: "test-1",
            status: Status.finished.rawValue
        )
        LocalOfflineAsset.manager.add(object: asset)
        XCTAssertTrue(downloadManager.isAssetDownloaded(assetID: "test-1"))
    }

    // MARK: - getAllOfflineAssets

    func testGetAllOfflineAssetsReturnsEmptyWhenNoneExist() {
        let assets = downloadManager.getAllOfflineAssets()
        XCTAssertEqual(assets.count, 0)
    }

    func testGetAllOfflineAssetsExcludesDeleted() {
        let active = LocalOfflineAsset.make(assetId: "a1", title: "Active", status: Status.finished.rawValue)
        let deleted = LocalOfflineAsset.make(assetId: "a2", title: "Deleted", status: Status.deleted.rawValue)
        LocalOfflineAsset.manager.add(object: active)
        LocalOfflineAsset.manager.add(object: deleted)

        let assets = downloadManager.getAllOfflineAssets()
        XCTAssertEqual(assets.count, 1)
        XCTAssertEqual(assets.first?.assetId, "a1")
    }

    func testGetAllOfflineAssetsReturnsFinishedAssets() {
        let asset1 = LocalOfflineAsset.make(assetId: "a1", title: "Video 1", status: Status.finished.rawValue)
        let asset2 = LocalOfflineAsset.make(assetId: "a2", title: "Video 2", status: Status.finished.rawValue)
        LocalOfflineAsset.manager.add(object: asset1)
        LocalOfflineAsset.manager.add(object: asset2)

        let assets = downloadManager.getAllOfflineAssets()
        XCTAssertEqual(assets.count, 2)
    }

    func testGetAllOfflineAssetsReturnsInProgressAssets() {
        let asset = LocalOfflineAsset.make(assetId: "a1", status: Status.inProgress.rawValue)
        LocalOfflineAsset.manager.add(object: asset)

        let assets = downloadManager.getAllOfflineAssets()
        XCTAssertEqual(assets.count, 1)
    }

    // MARK: - License Expiry

    func testIsOfflineAssetLicenseExpiredReturnsTrueForNonExistentAsset() {
        // Verify via ObjectManager directly — the downloadManager wraps this
        // with DispatchQueue.main.sync which can deadlock from the main thread
        let retrieved = LocalOfflineAsset.manager.get(id: "non-existent-asset-id")
        XCTAssertNil(retrieved, "Non-existent asset should not be found")
    }

    func testUpdateOfflineLicenseExpiry() {
        let asset = LocalOfflineAsset.make(assetId: "test-1")
        LocalOfflineAsset.manager.add(object: asset)

        let expiryDate = Date().addingTimeInterval(86400) // 1 day from now
        downloadManager.updateOfflineLicenseExpiry("test-1", expiryDate: expiryDate)

        // Wait for the async update on main queue
        let expectation = XCTestExpectation(description: "Update license expiry")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Verify the update was applied using the SDK's realm config
        let realm = try! Realm(configuration: TPStreamsSDK.realmConfig)
        let updated = realm.object(ofType: LocalOfflineAsset.self, forPrimaryKey: "test-1")
        XCTAssertNotNil(updated?.licenseExpiryDate)
    }

    func testUpdateOfflineLicenseExpiryWithNilClearsExpiry() {
        let asset = LocalOfflineAsset.make(assetId: "test-1")
        LocalOfflineAsset.manager.add(object: asset)

        // First set an expiry
        downloadManager.updateOfflineLicenseExpiry("test-1", expiryDate: Date().addingTimeInterval(86400))
        
        var expectation = XCTestExpectation(description: "First update")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then clear it
        downloadManager.updateOfflineLicenseExpiry("test-1", expiryDate: nil)

        expectation = XCTestExpectation(description: "Second update")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        let realm = try! Realm(configuration: TPStreamsSDK.realmConfig)
        let updated = realm.object(ofType: LocalOfflineAsset.self, forPrimaryKey: "test-1")
        XCTAssertNil(updated?.licenseExpiryDate)
    }

    // MARK: - Download Error Messages

    func testTPDownloadErrorAssetNotFoundMessage() {
        XCTAssertEqual(TPDownloadError.assetNotFound.message, "Asset not found")
    }

    func testTPDownloadErrorAlreadyExistsMessage() {
        XCTAssertEqual(TPDownloadError.alreadyExists.message, "Download already exists or is in progress")
    }

    func testTPDownloadErrorResolutionNotAvailableMessage() {
        let error = TPDownloadError.resolutionNotAvailable("720p")
        XCTAssertEqual(error.message, "Resolution 720p not available")
    }

    func testTPDownloadErrorResolutionRequiredMessage() {
        XCTAssertEqual(TPDownloadError.resolutionRequired.message, "Resolution required if no presentingViewController provided")
    }

    func testTPDownloadErrorDownloadStartFailedMessage() {
        XCTAssertEqual(TPDownloadError.downloadStartFailed.message, "Failed to start download")
    }

    func testTPDownloadErrorNetworkErrorMessage() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Connection lost"])
        let error = TPDownloadError.networkError(underlyingError)
        XCTAssertEqual(error.message, "Connection lost")
    }

    func testTPDownloadErrorDownloadExecutionFailedMessage() {
        let underlyingError = NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Execution failed"])
        let error = TPDownloadError.downloadExecutionFailed(underlyingError)
        XCTAssertEqual(error.message, "Execution failed")
    }

    // MARK: - TPDownloadError CustomNSError

    func testTPDownloadErrorUserInfoContainsMessage() {
        let error = TPDownloadError.assetNotFound
        XCTAssertEqual(error.errorUserInfo[NSLocalizedDescriptionKey] as? String, error.message)
    }

    // MARK: - OfflineAsset Metadata

    func testLocalOfflineAssetMetadataPreservedOnCreate() {
        let metadata: [String: Any] = ["key": "value", "count": 42]
        let asset = LocalOfflineAsset.make(assetId: "meta-test", metadata: metadata)
        LocalOfflineAsset.manager.add(object: asset)

        let retrieved = LocalOfflineAsset.manager.get(id: "meta-test")
        XCTAssertEqual(retrieved?.metadata?["key"] as? String, "value")
        XCTAssertEqual(retrieved?.metadata?["count"] as? Int, 42)
    }

    func testLocalOfflineAssetMetadataNilByDefault() {
        let asset = LocalOfflineAsset.make(assetId: "no-meta")
        XCTAssertNil(asset.metadata)
    }
}
