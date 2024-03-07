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
        let offlineAsset1 = getSampleObject(id: "1")
        let offlineAsset2 = getSampleObject(id: "2")
        let offlineAsset3 = getSampleObject(id: "3")
        // Add object
        OfflineAsset.manager.add(object: offlineAsset1)
        OfflineAsset.manager.add(object: offlineAsset2)
        OfflineAsset.manager.add(object: offlineAsset3)
        // Get object
        let retrivedOfflineAsset = OfflineAsset.manager.get(id: "Sample1")

        XCTAssert(retrivedOfflineAsset!.assetId == "Sample1")
        XCTAssert(retrivedOfflineAsset!.srcURL == "https://www.Sample1.com.m3u8")
    }
    
    func testObjectExists() throws {
        let isExists1 = OfflineAsset.manager.exists(id: "Sample1")
        let isExists2 = OfflineAsset.manager.exists(id: "Sample5")

        XCTAssert(isExists1 == true)
        XCTAssert(isExists2 == false)
    }
    
    func testgetAll() throws {
        let offlineAssets = OfflineAsset.manager.getAll()

        XCTAssert(offlineAssets.count == 3)
        XCTAssert(offlineAssets[0].assetId == "Sample1")
        XCTAssert(offlineAssets[1].srcURL == "https://www.Sample2.com.m3u8")
        XCTAssert(offlineAssets[2].title == "Sample Title 3")
    }
    
    private func getSampleObject(id: String) -> OfflineAsset {
        return OfflineAsset.create(                             // id = 1
            assetId: "Sample\(id)",                             // Sample1
            srcURL: "https://www.Sample\(id).com.m3u8",         // https://www.Sample1.com.m3u8
            title: "Sample Title \(id)",                        // Sample Title 1
            resolution: "720p",                                 // 720p
            duration: 3600,                                     // 3600
            bitRate: 100000                                     // 100000
        )
    }

}
