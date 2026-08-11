//
//  AssetModelTests.swift
//  iOSPlayerSDKTests
//
//  Tests for Asset, Video, LiveStream, and ContentProtectionType models.
//

import XCTest
@testable import TPStreamsSDK

final class AssetModelTests: XCTestCase {

    // MARK: - Asset

    func testAssetPlaybackURLReturnsVideoURL() {
        let asset = Asset.make(playbackURL: "https://example.com/video.m3u8")
        XCTAssertEqual(asset.playbackURL, "https://example.com/video.m3u8")
    }

    func testAssetPlaybackURLReturnsLiveStreamHLSURL() {
        let asset = Asset.makeLive(hlsUrl: "https://example.com/live.m3u8")
        XCTAssertEqual(asset.playbackURL, "https://example.com/live.m3u8")
    }

    func testAssetPlaybackURLReturnsNilWhenNoVideoOrLiveStream() {
        let asset = Asset(
            id: "1",
            title: "Empty",
            contentType: "video",
            video: nil,
            liveStream: nil,
            folderTree: nil,
            drmContentId: nil
        )
        XCTAssertNil(asset.playbackURL)
    }

    func testAssetIsDrmEncryptedWhenVideoHasDRM() {
        let asset = Asset.make(isDrmEncrypted: true)
        XCTAssertTrue(asset.isDrmEncrypted)
    }

    func testAssetIsNotDrmEncryptedWhenVideoHasNoDRM() {
        let asset = Asset.make(isDrmEncrypted: false)
        XCTAssertFalse(asset.isDrmEncrypted)
    }

    func testAssetIsDrmEncryptedWhenLiveStreamHasDRM() {
        let asset = Asset.makeLive(enableDRM: true)
        XCTAssertTrue(asset.isDrmEncrypted)
    }

    func testAssetIsNotDrmEncryptedWhenLiveStreamHasNoDRM() {
        let asset = Asset.makeLive(enableDRM: false)
        XCTAssertFalse(asset.isDrmEncrypted)
    }

    func testAssetKeyIdentifierReturnsAssetID() {
        let asset = Asset.make(id: "custom-id")
        XCTAssertEqual(asset.keyIdentifier, "custom-id")
    }

    // MARK: - Video

    func testVideoIsAESEncryptedWhenContentTypeIsAES() {
        let video = Video(
            id: "v1",
            playbackURL: "https://example.com/video.m3u8",
            status: "Ready",
            drmEncrypted: false,
            duration: 120,
            thumbnailURL: nil,
            contentProtectionType: .aes,
            tracks: []
        )
        XCTAssertTrue(video.isAESEncrypted)
    }

    func testVideoIsNotAESEncryptedWhenContentTypeIsDRM() {
        let video = Video(
            id: "v1",
            playbackURL: "https://example.com/video.m3u8",
            status: "Ready",
            drmEncrypted: true,
            duration: 120,
            thumbnailURL: nil,
            contentProtectionType: .drm,
            tracks: []
        )
        XCTAssertFalse(video.isAESEncrypted)
    }

    func testVideoIsNotAESEncryptedWhenContentTypeIsNil() {
        let video = Video(
            id: "v1",
            playbackURL: "https://example.com/video.m3u8",
            status: "Ready",
            drmEncrypted: false,
            duration: 120,
            thumbnailURL: nil,
            contentProtectionType: nil,
            tracks: []
        )
        XCTAssertFalse(video.isAESEncrypted)
    }

    func testVideoKeyIdentifierReturnsVideoID() {
        let video = Video(
            id: "video-123",
            playbackURL: "https://example.com/video.m3u8",
            status: "Ready",
            drmEncrypted: false,
            duration: 120,
            thumbnailURL: nil,
            contentProtectionType: nil,
            tracks: []
        )
        XCTAssertEqual(video.keyIdentifier, "video-123")
    }

    func testVideoKeyIdentifierReturnsNilWhenIDIsNil() {
        let video = Video(
            id: nil,
            playbackURL: "https://example.com/video.m3u8",
            status: "Ready",
            drmEncrypted: false,
            duration: 120,
            thumbnailURL: nil,
            contentProtectionType: nil,
            tracks: []
        )
        XCTAssertNil(video.keyIdentifier)
    }

    // MARK: - ContentProtectionType

    func testContentProtectionTypeDRMFromValidString() {
        XCTAssertEqual(ContentProtectionType.fromString("drm"), .drm)
    }

    func testContentProtectionTypeAESFromValidString() {
        XCTAssertEqual(ContentProtectionType.fromString("aes"), .aes)
    }

    func testContentProtectionTypeFromNilString() {
        XCTAssertNil(ContentProtectionType.fromString(nil))
    }

    func testContentProtectionTypeFromInvalidString() {
        XCTAssertNil(ContentProtectionType.fromString("unknown"))
    }

    func testContentProtectionTypeFromUppercaseString() {
        XCTAssertEqual(ContentProtectionType.fromString("DRM"), .drm)
        XCTAssertEqual(ContentProtectionType.fromString("AES"), .aes)
    }

    func testContentProtectionTypeFromMixedCaseString() {
        XCTAssertEqual(ContentProtectionType.fromString("Drm"), .drm)
        XCTAssertEqual(ContentProtectionType.fromString("Aes"), .aes)
    }

    func testContentProtectionTypeFromEmptyString() {
        XCTAssertNil(ContentProtectionType.fromString(""))
    }

    // MARK: - LiveStream

    func testLiveStreamIsStreamingWhenStatusIsStreaming() {
        let stream = LiveStream(
            status: "Streaming",
            hlsUrl: "https://example.com/live.m3u8",
            transcodeRecordedVideo: false,
            chatEmbedUrl: "",
            noticeMessage: nil,
            enableDRM: false
        )
        XCTAssertTrue(stream.isStreaming)
    }

    func testLiveStreamIsStreamingWhenStatusIsRunning() {
        let stream = LiveStream(
            status: "Running",
            hlsUrl: "https://example.com/live.m3u8",
            transcodeRecordedVideo: false,
            chatEmbedUrl: "",
            noticeMessage: nil,
            enableDRM: false
        )
        XCTAssertTrue(stream.isStreaming)
    }

    func testLiveStreamIsNotStreamingWhenStatusIsEnded() {
        let stream = LiveStream(
            status: "Ended",
            hlsUrl: "https://example.com/live.m3u8",
            transcodeRecordedVideo: false,
            chatEmbedUrl: "",
            noticeMessage: nil,
            enableDRM: false
        )
        XCTAssertFalse(stream.isStreaming)
    }

    func testLiveStreamIsNotStreamingWhenStatusIsPending() {
        let stream = LiveStream(
            status: "Pending",
            hlsUrl: "https://example.com/live.m3u8",
            transcodeRecordedVideo: false,
            chatEmbedUrl: "",
            noticeMessage: nil,
            enableDRM: false
        )
        XCTAssertFalse(stream.isStreaming)
    }

    // MARK: - VideoQuality

    func testVideoQualityInit() {
        let quality = VideoQuality(resolution: "720p", bitrate: 1_000_000)
        XCTAssertEqual(quality.resolution, "720p")
        XCTAssertEqual(quality.bitrate, 1_000_000, accuracy: 1)
    }
}
