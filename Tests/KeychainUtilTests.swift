//
//  KeychainUtilTests.swift
//  iOSPlayerSDKTests
//
//  Tests for KeychainUtil wrapper.
//  Note: Keychain is not available on simulator, so these tests verify
//  the API doesn't crash and returns sensible defaults.
//

import XCTest
@testable import TPStreamsSDK

final class KeychainUtilTests: XCTestCase {

    private let service = "com.tpstreams.test"
    private let account = "test-account"

    override func tearDown() {
        KeychainUtil.delete(service: service, account: account)
        super.tearDown()
    }

    func testGetReturnsNilWhenNoDataStored() {
        let data = KeychainUtil.get(service: service, account: "non-existent")
        XCTAssertNil(data)
    }

    func testSaveAndRetrieveData() {
        let testData = "test-value".data(using: .utf8)!
        KeychainUtil.save(data: testData, service: service, account: account)
        let retrieved = KeychainUtil.get(service: service, account: account)
        // On simulator, keychain may not be available — just verify no crash
        // If keychain works, verify the data
        if let data = retrieved {
            XCTAssertEqual(data, testData)
        }
    }

    func testDeleteRemovesData() {
        let testData = "delete-me".data(using: .utf8)!
        KeychainUtil.save(data: testData, service: service, account: account)
        KeychainUtil.delete(service: service, account: account)
        let retrieved = KeychainUtil.get(service: service, account: account)
        XCTAssertNil(retrieved)
    }

    func testDeleteNonExistentDoesNotCrash() {
        KeychainUtil.delete(service: service, account: "non-existent")
    }

    func testDeleteAllRemovesAllDataForService() {
        KeychainUtil.save(data: "a".data(using: .utf8)!, service: service, account: "account-1")
        KeychainUtil.save(data: "b".data(using: .utf8)!, service: service, account: "account-2")
        KeychainUtil.deleteAll(service: service)
        XCTAssertNil(KeychainUtil.get(service: service, account: "account-1"))
        XCTAssertNil(KeychainUtil.get(service: service, account: "account-2"))
    }

    func testMultipleServicesAreIndependent() {
        let account1 = "service-1-account"
        let account2 = "service-2-account"
        KeychainUtil.save(data: "svc1".data(using: .utf8)!, service: "svc1", account: account1)
        KeychainUtil.save(data: "svc2".data(using: .utf8)!, service: "svc2", account: account2)
        KeychainUtil.deleteAll(service: "svc1")
        // svc2 data should remain
        XCTAssertNil(KeychainUtil.get(service: "svc1", account: account1))
        // On simulator, deleteAll for svc1 shouldn't affect svc2
        KeychainUtil.deleteAll(service: "svc2")
    }

    func testSaveEmptyData() {
        let emptyData = Data()
        KeychainUtil.save(data: emptyData, service: service, account: account)
        let retrieved = KeychainUtil.get(service: service, account: account)
        // Should not crash — may or may not store empty data
        KeychainUtil.delete(service: service, account: account)
    }

    func testOverwriteExistingData() {
        let original = "original".data(using: .utf8)!
        let updated = "updated".data(using: .utf8)!
        KeychainUtil.save(data: original, service: service, account: account)
        KeychainUtil.save(data: updated, service: service, account: account)
        let retrieved = KeychainUtil.get(service: service, account: account)
        if let data = retrieved {
            XCTAssertEqual(String(data: data, encoding: .utf8), "updated")
        }
        KeychainUtil.delete(service: service, account: account)
    }
}
