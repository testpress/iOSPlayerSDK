//
//  APIURLConstructionTests.swift
//  iOSPlayerSDKTests
//
//  Tests for API URL template construction.
//

import XCTest
@testable import TPStreamsSDK

final class APIURLConstructionTests: XCTestCase {

    // MARK: - StreamsAPI URLs

    func testStreamsVideoDetailAPIFormat() {
        let template = StreamsAPI.VIDEO_DETAIL_API
        let url = String(format: template, "org123", "asset456", "token789")
        XCTAssertEqual(url, "https://app.tpstreams.com/api/v1/org123/assets/asset456/?access_token=token789")
    }

    func testStreamsDRMLicenseAPIFormat() {
        let template = StreamsAPI.DRM_LICENSE_API
        let url = String(format: template, "org123", "asset456", "token789", "false")
        XCTAssertEqual(url, "https://app.tpstreams.com/api/v1/org123/assets/asset456/drm_license/?access_token=token789&drm_type=fairplay&download=false")
    }

    func testStreamsDRMLicenseAPIFormatForDownload() {
        let template = StreamsAPI.DRM_LICENSE_API
        let url = String(format: template, "org123", "asset456", "token789", "true")
        XCTAssertTrue(url.contains("download=true"))
    }

    func testStreamsAESEncryptionKeyAPIFormat() {
        let template = StreamsAPI.AES_ENCRYPTION_KEY_API
        let url = String(format: template, "org123", "asset456")
        XCTAssertEqual(url, "https://app.tpstreams.com/api/v1/org123/assets/asset456/aes_key/")
    }

    // MARK: - TestpressAPI URLs

    func testTestpressVideoDetailAPIFormat() {
        let template = TestpressAPI.VIDEO_DETAIL_API
        let url = String(format: template, "myorg", "asset789", "token123")
        XCTAssertEqual(url, "https://myorg.testpress.in/api/v2.5/video_info/asset789/?access_token=token123&v=2")
    }

    func testTestpressDRMLicenseAPIFormat() {
        let template = TestpressAPI.DRM_LICENSE_API
        let url = String(format: template, "myorg", "asset789", "token123", "false")
        XCTAssertEqual(url, "https://myorg.testpress.in/api/v2.5/drm_license_key/asset789/?access_token=token123&drm_type=fairplay&download=false")
    }

    func testTestpressDRMLicenseAPIFormatForDownload() {
        let template = TestpressAPI.DRM_LICENSE_API
        let url = String(format: template, "myorg", "asset789", "token123", "true")
        XCTAssertTrue(url.contains("download=true"))
    }

    func testTestpressAESEncryptionKeyAPIFormat() {
        let template = TestpressAPI.AES_ENCRYPTION_KEY_API
        let url = String(format: template, "myorg", "asset789")
        XCTAssertEqual(url, "https://myorg.testpress.in/api/v2.5/encryption_key/asset789/")
    }

    // MARK: - URL Hosts

    func testStreamsAPIUsesAppTPStreamsHost() {
        XCTAssertTrue(StreamsAPI.VIDEO_DETAIL_API.contains("app.tpstreams.com"))
    }

    func testTestpressAPUsesTestpressInHost() {
        XCTAssertTrue(TestpressAPI.VIDEO_DETAIL_API.contains("testpress.in"))
    }

    // MARK: - URL Paths

    func testStreamsAPIUsesV1Path() {
        XCTAssertTrue(StreamsAPI.VIDEO_DETAIL_API.contains("/api/v1/"))
    }

    func testTestpressAPIUsesV25Path() {
        XCTAssertTrue(TestpressAPI.VIDEO_DETAIL_API.contains("/api/v2.5/"))
    }

    // MARK: - User Agent

    func testTestpressUserAgentPrefix() {
        XCTAssertEqual(TestpressAPI.userAgentPrefix, "ios-app")
    }

    func testStreamsUserAgentPrefixIsNil() {
        XCTAssertNil(StreamsAPI.userAgentPrefix)
    }
}
