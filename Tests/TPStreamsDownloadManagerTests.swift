//
//  TPStreamsDownloadManagerTests.swift
//  iOSPlayerSDKTests
//
//  Created by Prithuvi on 07/10/24.
//

import XCTest
@testable import TPStreamsSDK

final class TPStreamsDownloadManagerTests: XCTestCase {

    var downloadManager: TPStreamsDownloadManager!

    override func setUp() {
        super.setUp()
        downloadManager = TPStreamsDownloadManager.shared
    }

    override func tearDown() {
        downloadManager = nil
        super.tearDown()
    }

    func testSharedInstance() {
        XCTAssertTrue(TPStreamsDownloadManager.shared === TPStreamsDownloadManager.shared, "Shared instance should be a singleton")
    }

}
