//
//  ObjectManagerTest.swift
//  iOSPlayerSDKTests
//
//  Created by Prithuvi on 07/10/24.
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
        let localOfflineAsset = LocalOfflineAsset()
        localOfflineAsset.assetId = "test"
        localOfflineAsset.srcURL = "https://www.test.com.m3u8"
        // Add object
        LocalOfflineAsset.manager.add(object: localOfflineAsset)
        // Get object
        let retrivedLocalOfflineAsset = LocalOfflineAsset.manager.get(id: "test")

        XCTAssert(retrivedLocalOfflineAsset!.assetId == "test")
        XCTAssert(retrivedLocalOfflineAsset!.srcURL == "https://www.test.com.m3u8")
    }

}
