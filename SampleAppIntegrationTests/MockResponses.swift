//
//  MockResponses.swift
//  SampleAppIntegrationTests
//
//  Fixture response data for the mock backend.
//  Matches the exact JSON format the SDK expects from the real API.
//

import Foundation

/// Configuration for the mock backend.
/// Set properties before calling `registerMockNetwork()`.
struct MockConfig {
    var assetResponse: [String: Any] = MockResponses.standardVideo
    var orgCode: String = "integration-test-org"
    var assetId: String = "integration-test-asset"
    var simulateNetworkFailure: Bool = false
    var testVideoData: Data?
    var testVideoURL: String = "http://mock.test/media/test-video.mp4"
    var hlsManifestURL: String = "http://mock.test/media/test-manifest.m3u8"
}

/// Pre-built fixture responses matching the StreamsAPI and TestpressAPI formats.
enum MockResponses {

    /// Standard video response (StreamsAPI format, non-DRM).
    /// The playback_url points to an HLS master playlist served by the mock.
    /// The M3U8Kit parser expects valid HLS format; AVPlayer also plays HLS.
    static var standardVideo: [String: Any] {
        [
            "id": "integration-test-asset",
            "title": "Integration Test Video",
            "type": "video",
            "folder_tree": "Integration/Tests",
            "drm_content_id": "",
            "video": [
                "id": "test-video-id",
                "playback_url": "http://mock.test/media/master.m3u8",
                "status": "Ready",
                "duration": 5.0,
                "cover_thumbnail_url": "https://example.com/thumb.jpg",
                "content_protection_type": "none",
                "tracks": [
                    ["language": "en", "url": "http://mock.test/subtitles/en.vtt", "subtitle_type": "Manual"],
                    ["language": "es", "url": "http://mock.test/subtitles/es.vtt", "subtitle_type": "Auto Generated"]
                ]
            ] as [String: Any]
        ]
    }

    /// Live stream response.
    static let liveStream: [String: Any] = [
        "id": "integration-test-live",
        "title": "Integration Test Live Stream",
        "type": "live",
        "live_stream": [
            "status": "Streaming",
            "hls_url": "http://mock.test/media/live.m3u8",
            "transcode_recorded_video": true,
            "chat_embed_url": "https://example.com/chat",
            "notice_message": "Welcome to the test stream!",
            "enable_drm": false
        ]
    ]

    /// DRM-encrypted video response.
    static var drmVideo: [String: Any] {
        [
            "id": "integration-test-drm",
            "title": "DRM Test Video",
            "type": "video",
            "folder_tree": "Integration/Tests",
            "drm_content_id": "drm-content-mock",
            "video": [
                "id": "test-drm-video-id",
                "playback_url": "http://mock.test/media/master.m3u8",
                "status": "Ready",
                "duration": 5.0,
                "cover_thumbnail_url": "https://example.com/thumb.jpg",
                "content_protection_type": "drm",
                "tracks": [] as [[String: String]]
            ] as [String: Any]
        ]
    }

    /// Malformed response — missing required fields.
    static let malformedResponse: [String: Any] = [
        "some_field": "some_value"
    ]

    // MARK: - URL Routing

    /// Returns a fixture response for the given URL, or nil for network failure simulation.
    static func response(for url: URL, config: MockConfig) -> (Data, HTTPURLResponse)? {
        let absoluteString = url.absoluteString

        // StreamsAPI: https://app.tpstreams.com/api/v1/{org}/assets/{id}/
        if absoluteString.contains("tpstreams.com/api/v1/") && absoluteString.contains("/assets/") {
            return jsonResponse(config.assetResponse)
        }

        // TestpressAPI: https://{org}.testpress.in/api/v2.5/video_info/{id}/
        if absoluteString.contains("testpress.in/api/v2.5/video_info/") {
            return jsonResponse(config.assetResponse)
        }

        // DRM license endpoint
        if absoluteString.contains("drm_license") || absoluteString.contains("drm_license_key") {
            return jsonResponse(["license": "mock-ckc-data-base64=="])
        }

        // HLS master playlist — return a valid manifest that M3U8Kit can parse
        if absoluteString.contains("master.m3u8") {
            let manifest = MockResponses.hlsMasterPlaylist
            return (manifest.data(using: .utf8)!, HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/vnd.apple.mpegurl"])!)
        }
        
        // HLS variant playlist — return a valid media playlist
        if absoluteString.contains("variant.m3u8") {
            let manifest = MockResponses.hlsVariantPlaylist
            return (manifest.data(using: .utf8)!, HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/vnd.apple.mpegurl"])!)
        }

        // HLS segment request — serve the test video data
        if absoluteString.contains("mock.test/media/segment") {
            if let videoData = config.testVideoData {
                return (videoData, HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "video/mp2t"])!)
            }
            return nil
        }

        // Subtitle VTT files
        if absoluteString.contains(".vtt") {
            return (MockResponses.subtitleVTT.data(using: .utf8)!, HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "text/vtt"])!)
        }

        // Unknown URL — simulate network failure
        return nil
    }

    // MARK: - Subtitle Fixture

    static let subtitleVTT = """
    WEBVTT

    00:00:01.000 --> 00:00:03.000
    Hello from the integration test

    00:00:04.000 --> 00:00:06.000
    This is a second subtitle cue

    00:00:07.000 --> 00:00:10.000
    Subtitles continue here with a longer line
    that demonstrates the two-line limit behavior
    """

    // MARK: - HLS Fixtures

    /// Valid HLS master playlist referencing a single variant.
    static let hlsMasterPlaylist = """
    #EXTM3U
    #EXT-X-STREAM-INF:BANDWIDTH=1000000,RESOLUTION=320x180
    http://mock.test/media/variant.m3u8
    """

    /// Valid HLS variant/media playlist with one segment pointing to the test video.
    static let hlsVariantPlaylist = """
    #EXTM3U
    #EXT-X-VERSION:3
    #EXT-X-TARGETDURATION:10
    #EXT-X-PLAYLIST-TYPE:VOD
    #EXTINF:5.0,
    http://mock.test/media/segment0.ts
    #EXT-X-ENDLIST
    """

    // MARK: - Helpers

    private static func jsonResponse(_ dict: [String: Any]) -> (Data, HTTPURLResponse)? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        let response = HTTPURLResponse(url: URL(string: "https://mock.test")!,
                                        statusCode: 200,
                                        httpVersion: nil,
                                        headerFields: nil)!
        return (data, response)
    }
}
