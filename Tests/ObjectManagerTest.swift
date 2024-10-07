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
        let localOfflineAsset1 = getSampleObject(id: "1")
        let localOfflineAsset2 = getSampleObject(id: "2")
        let localOfflineAsset3 = getSampleObject(id: "3")
        // Add object
        LocalOfflineAsset.manager.add(object: localOfflineAsset1)
        LocalOfflineAsset.manager.add(object: localOfflineAsset2)
        LocalOfflineAsset.manager.add(object: localOfflineAsset3)
        // Get object
        let retrivedlocalOfflineAsset = LocalOfflineAsset.manager.get(id: "Sample1")

        XCTAssert(retrivedlocalOfflineAsset!.assetId == "Sample1")
        XCTAssert(retrivedlocalOfflineAsset!.srcURL == "https://www.Sample1.com.m3u8")
    }
    
    func testObjectExists() throws {
        let isExists1 = LocalOfflineAsset.manager.exists(id: "Sample1")
        let isExists2 = LocalOfflineAsset.manager.exists(id: "Sample5")

        XCTAssert(isExists1 == true)
        XCTAssert(isExists2 == false)
    }
    
    func testgetAll() throws {
        let localOfflineAsset = LocalOfflineAsset.manager.getAll()

        XCTAssert(localOfflineAsset.count == 3)
        XCTAssert(localOfflineAsset[0].assetId == "Sample1")
        XCTAssert(localOfflineAsset[1].srcURL == "https://www.Sample2.com.m3u8")
        XCTAssert(localOfflineAsset[2].title == "Sample Title 3")
    }
    
    private func getSampleObject(id: String) -> LocalOfflineAsset {
        return LocalOfflineAsset.create(                             // id = 1
            assetId: "Sample\(id)",                             // Sample1
            srcURL: "https://www.Sample\(id).com.m3u8",         // https://www.Sample1.com.m3u8
            title: "Sample Title \(id)",                        // Sample Title 1
            resolution: "720p",                                 // 720p
            duration: 3600,                                     // 3600
            bitRate: 100000,                                    // 100000
            folderTree: "folderTree"                            // folderTree
        )
    }

}

