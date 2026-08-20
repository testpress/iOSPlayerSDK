import XCTest
@testable import TPStreamsSDK

private final class InMemoryPresenceKeyValueStore: PresenceKeyValueStore {
    private var values: [String: String] = [:]

    func getString(forKey key: String) -> String? {
        return values[key]
    }

    func setString(_ value: String, forKey key: String) {
        values[key] = value
    }
}

final class PresenceViewerIdStoreTests: XCTestCase {

    func testGeneratesAUUIDShapedId() {
        let id = PresenceViewerIdStore(store: InMemoryPresenceKeyValueStore()).getOrCreate()

        XCTAssertNotNil(UUID(uuidString: id))
    }

    func testPersistsTheGeneratedIdInTheUnderlyingStore() {
        let store = InMemoryPresenceKeyValueStore()

        let id = PresenceViewerIdStore(store: store).getOrCreate()

        XCTAssertEqual(id, store.getString(forKey: "viewer_id"))
    }

    func testReturnsTheSameIdOnALaterCallAgainstTheSameStoreAsAcrossAnAppRestart() {
        let store = InMemoryPresenceKeyValueStore()

        let first = PresenceViewerIdStore(store: store).getOrCreate()
        let second = PresenceViewerIdStore(store: store).getOrCreate()

        XCTAssertEqual(first, second)
    }

    func testReturnsDifferentIdsForIndependentStores() {
        let first = PresenceViewerIdStore(store: InMemoryPresenceKeyValueStore()).getOrCreate()
        let second = PresenceViewerIdStore(store: InMemoryPresenceKeyValueStore()).getOrCreate()

        XCTAssertNotEqual(first, second)
    }
}
