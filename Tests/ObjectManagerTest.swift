//
//  ObjectManagerTest.swift
//  iOSPlayerSDKTests
//
//  Created by Prithuvi on 10/01/24.
//

import XCTest

import XCTest
@testable import TPStreamsSDK
import RealmSwift

final class ObjectManagerTest: XCTestCase {

    override func setUp() {
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
    }

    func testAddAndGetObject() throws {
        let offlineAsset = OfflineAsset()
        offlineAsset.assetId = "test"
        offlineAsset.srcURL = "https://www.test.com.m3u8"
        // Add object
        OfflineAsset.manager.add(object: offlineAsset)
        // Get object
        let retrivedOfflineAsset = OfflineAsset.manager.get(assetId: "test")

        XCTAssert(retrivedOfflineAsset!.assetId == "test")
        XCTAssert(retrivedOfflineAsset!.srcURL == "https://www.test.com.m3u8")
    }

}
