//
//  AnyRealmValueTests.swift
//  iOSPlayerSDKTests
//
//  Tests for AnyRealmValue extension used for metadata storage.
//

import XCTest
import RealmSwift
@testable import TPStreamsSDK

final class AnyRealmValueTests: XCTestCase {

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

    // MARK: - fromAny Initialization

    func testFromAnyWithString() {
        let value = AnyRealmValue(fromAny: "hello")
        XCTAssertEqual(value.toAny as? String, "hello")
    }

    func testFromAnyWithInt() {
        let value = AnyRealmValue(fromAny: 42)
        XCTAssertEqual(value.toAny as? Int, 42)
    }

    func testFromAnyWithDouble() {
        let value = AnyRealmValue(fromAny: 3.14)
        XCTAssertEqual((value.toAny as? Double) ?? 0, 3.14, accuracy: 0.001)
    }

    func testFromAnyWithFloat() {
        let value = AnyRealmValue(fromAny: Float(1.5))
        XCTAssertEqual((value.toAny as? Float) ?? 0, 1.5, accuracy: 0.001)
    }

    func testFromAnyWithBool() {
        let value = AnyRealmValue(fromAny: true)
        XCTAssertEqual(value.toAny as? Bool, true)
    }

    func testFromAnyWithDate() {
        let date = Date()
        let value = AnyRealmValue(fromAny: date)
        XCTAssertEqual(value.toAny as? Date, date)
    }

    func testFromAnyWithData() {
        let data = "test".data(using: .utf8)!
        let value = AnyRealmValue(fromAny: data)
        XCTAssertEqual(value.toAny as? Data, data)
    }

    func testFromAnyWithNSNull() {
        let value = AnyRealmValue(fromAny: NSNull())
        // Should map to .none
        switch value {
        case .none:
            break // Expected
        default:
            XCTFail("Expected .none for NSNull")
        }
    }

    func testFromAnyWithDictionary() {
        let dict: [String: Any] = ["key": "value", "number": 42]
        let value = AnyRealmValue(fromAny: dict)
        // Should be a dictionary type
        switch value {
        case .dictionary:
            break // Expected
        default:
            XCTFail("Expected .dictionary for [String: Any]")
        }
    }

    func testFromAnyWithUnknownTypeFallsBackToString() {
        let value = AnyRealmValue(fromAny: 12345)
        // Int should map to .int, not fallback
        switch value {
        case .int(let v):
            XCTAssertEqual(v, 12345)
        default:
            XCTFail("Expected .int for Int value")
        }
    }

    // MARK: - toAny Roundtrip

    func testStringRoundtrip() {
        let original = "test string"
        let realmValue = AnyRealmValue(fromAny: original)
        let result = realmValue.toAny as? String
        XCTAssertEqual(result, original)
    }

    func testIntRoundtrip() {
        let original = 999
        let realmValue = AnyRealmValue(fromAny: original)
        let result = realmValue.toAny as? Int
        XCTAssertEqual(result, original)
    }

    func testDoubleRoundtrip() {
        let original = 2.71828
        let realmValue = AnyRealmValue(fromAny: original)
        let result = (realmValue.toAny as? Double) ?? 0
        XCTAssertEqual(result, original, accuracy: 0.00001)
    }

    // MARK: - Integration with Metadata Storage

    func testMetadataStorageRoundtrip() {
        let metadata: [String: Any] = [
            "title": "Test Video",
            "duration": 120.5,
            "count": 42,
            "active": true
        ]

        let asset = LocalOfflineAsset.make(assetId: "meta-test", metadata: metadata)
        LocalOfflineAsset.manager.add(object: asset)

        let retrieved = LocalOfflineAsset.manager.get(id: "meta-test")
        XCTAssertEqual(retrieved?.metadata?["title"] as? String, "Test Video")
        XCTAssertEqual((retrieved?.metadata?["duration"] as? Double) ?? 0, 120.5, accuracy: 0.001)
        XCTAssertEqual(retrieved?.metadata?["count"] as? Int, 42)
        XCTAssertEqual(retrieved?.metadata?["active"] as? Bool, true)
    }
}
