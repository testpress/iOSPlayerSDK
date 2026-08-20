import XCTest
@testable import TPStreamsSDK

final class StreamsAPIParserPresenceTests: XCTestCase {
    private let parser = StreamsAPIParser()

    private func liveStreamDict(presence: [String: Any]?) -> [String: Any] {
        var dict: [String: Any] = [
            "status": "Streaming",
            "hls_url": "https://example.com/live.m3u8",
            "transcode_recorded_video": true,
            "chat_embed_url": "https://example.com/chat",
        ]
        if let presence = presence {
            dict["presence"] = presence
        }
        return dict
    }

    func testParsesAPresentPresenceConfig() {
        let liveStream = parser.parseLiveStream(from: liveStreamDict(presence: [
            "token": "presence-token-abc",
            "vid": "irrelevant-to-the-client",
            "base_url": "https://presence.tpstreams.test",
        ]))

        XCTAssertEqual(liveStream?.presence?.token, "presence-token-abc")
        XCTAssertEqual(liveStream?.presence?.baseUrl, "https://presence.tpstreams.test")
    }

    func testAbsentPresenceKeyParsesAsNoPresence() {
        // What every organization not yet opted into the rollout actually
        // gets back — must parse cleanly rather than error.
        let liveStream = parser.parseLiveStream(from: liveStreamDict(presence: nil))

        XCTAssertNil(liveStream?.presence)
        XCTAssertNotNil(liveStream) // the rest of the live stream still parses
    }

    // A malformed presence (missing token or base_url) is treated the same as
    // no presence at all, rather than letting a half-populated config reach
    // the heartbeat manager — presence is a bolt-on feature that must never
    // be able to break asset parsing.
    func testPresenceMissingItsTokenParsesAsNoPresence() {
        let liveStream = parser.parseLiveStream(from: liveStreamDict(presence: [
            "base_url": "https://presence.tpstreams.test"
        ]))

        XCTAssertNil(liveStream?.presence)
    }

    func testPresenceMissingItsBaseUrlParsesAsNoPresence() {
        let liveStream = parser.parseLiveStream(from: liveStreamDict(presence: [
            "token": "presence-token-abc"
        ]))

        XCTAssertNil(liveStream?.presence)
    }
}

final class ProviderPresenceScopeTests: XCTestCase {
    // Presence/live-viewer-count is a TPStreams-only feature — the legacy
    // TestPress provider's backend has no support for it.
    func testStreamsAPISupportsPresence() {
        XCTAssertTrue(StreamsAPI.supportsPresence)
    }

    func testTestpressAPIDoesNotSupportPresence() {
        XCTAssertFalse(TestpressAPI.supportsPresence)
    }
}
