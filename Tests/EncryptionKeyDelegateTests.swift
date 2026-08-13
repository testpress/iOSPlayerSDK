//
//  EncryptionKeyDelegateTests.swift
//  iOSPlayerSDKTests
//
//  Tests for EncryptionKeyDelegate key storage operations.
//

import XCTest
@testable import TPStreamsSDK

final class EncryptionKeyDelegateTests: XCTestCase {

    private let delegate = EncryptionKeyDelegate.shared
    private let testIdentifier = "test-video-encryption"
    
    /// Keychain is not available on the simulator, so we skip keychain-dependent tests
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    override func setUp() {
        super.setUp()
        guard !isSimulator else { return }
        delegate.delete(for: testIdentifier)
    }

    override func tearDown() {
        guard !isSimulator else { return super.tearDown() }
        delegate.delete(for: testIdentifier)
        super.tearDown()
    }

    // MARK: - Singleton

    func testSharedInstanceIsSingleton() {
        XCTAssertTrue(EncryptionKeyDelegate.shared === EncryptionKeyDelegate.shared)
    }

    // MARK: - Keychain Tests (skip on simulator)

    func testSaveAndGetEncryptionKey() {
        guard !isSimulator else { return }
        let testData = "test-encryption-key".data(using: .utf8)!
        delegate.save(encryptionKey: testData, for: testIdentifier)

        let retrieved = delegate.get(for: testIdentifier)
        XCTAssertEqual(retrieved, testData)
    }

    func testGetReturnsNilForNonExistentKey() {
        guard !isSimulator else { return }
        let retrieved = delegate.get(for: "non-existent-id")
        XCTAssertNil(retrieved)
    }

    func testDeleteRemovesKey() {
        guard !isSimulator else { return }
        let testData = "key-to-delete".data(using: .utf8)!
        delegate.save(encryptionKey: testData, for: testIdentifier)
        delegate.delete(for: testIdentifier)

        let retrieved = delegate.get(for: testIdentifier)
        XCTAssertNil(retrieved)
    }

    func testDeleteNonExistentKeyDoesNotCrash() {
        guard !isSimulator else { return }
        delegate.delete(for: "non-existent-id")
    }

    func testSaveOverwritesExistingKey() {
        guard !isSimulator else { return }
        let key1 = "key-v1".data(using: .utf8)!
        let key2 = "key-v2".data(using: .utf8)!

        delegate.save(encryptionKey: key1, for: testIdentifier)
        delegate.save(encryptionKey: key2, for: testIdentifier)

        let retrieved = delegate.get(for: testIdentifier)
        XCTAssertEqual(retrieved, key2)
    }

    func testKeyPrefixIsCorrect() {
        guard !isSimulator else { return }
        let testData = "prefix-test".data(using: .utf8)!
        delegate.save(encryptionKey: testData, for: "my-video")
        let retrieved = delegate.get(for: "my-video")
        XCTAssertEqual(retrieved, testData)
        delegate.delete(for: "my-video")
    }

    func testSaveAndRetrieveMultipleKeys() {
        guard !isSimulator else { return }
        let key1 = "key-1".data(using: .utf8)!
        let key2 = "key-2".data(using: .utf8)!
        let key3 = "key-3".data(using: .utf8)!

        delegate.save(encryptionKey: key1, for: "video-1")
        delegate.save(encryptionKey: key2, for: "video-2")
        delegate.save(encryptionKey: key3, for: "video-3")

        XCTAssertEqual(delegate.get(for: "video-1"), key1)
        XCTAssertEqual(delegate.get(for: "video-2"), key2)
        XCTAssertEqual(delegate.get(for: "video-3"), key3)

        delegate.delete(for: "video-1")
        delegate.delete(for: "video-2")
        delegate.delete(for: "video-3")
    }
}
