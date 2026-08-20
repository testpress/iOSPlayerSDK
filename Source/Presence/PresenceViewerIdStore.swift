import Foundation

protocol PresenceKeyValueStore {
    func getString(forKey key: String) -> String?
    func setString(_ value: String, forKey key: String)
}

final class KeychainPresenceKeyValueStore: PresenceKeyValueStore {
    private static let service = "com.tpstream.player.presence"

    func getString(forKey key: String) -> String? {
        guard let data = KeychainUtil.get(service: Self.service, account: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func setString(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        KeychainUtil.save(data: data, service: Self.service, account: key)
    }
}

// Generated once and persisted, so the same value can be forwarded as the
// viewer_id query param when requesting playback and resent on every
// heartbeat/leave call after — same purpose as the web SDK's
// getOrCreatePersistentViewerId(), backed by the Keychain (rather than
// UserDefaults) so it survives not just app restarts but reinstalls too,
// matching localStorage's own survive-a-reload intent as closely as this
// platform allows.
final class PresenceViewerIdStore {
    private static let viewerIdKey = "viewer_id"

    private let store: PresenceKeyValueStore

    init(store: PresenceKeyValueStore = KeychainPresenceKeyValueStore()) {
        self.store = store
    }

    func getOrCreate() -> String {
        if let existing = store.getString(forKey: Self.viewerIdKey) {
            return existing
        }
        let generated = UUID().uuidString
        store.setString(generated, forKey: Self.viewerIdKey)
        return generated
    }
}
