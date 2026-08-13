//
//  TPStreamPlayerErrorTests.swift
//  iOSPlayerSDKTests
//
//  Tests for TPStreamPlayerError codes, messages, and Sentry logging behavior.
//

import XCTest
@testable import TPStreamsSDK

final class TPStreamPlayerErrorTests: XCTestCase {

    // MARK: - Error Codes

    func testResourceNotFoundHasCorrectCode() {
        XCTAssertEqual(TPStreamPlayerError.resourceNotFound.code, 5001)
    }

    func testUnauthorizedAccessHasCorrectCode() {
        XCTAssertEqual(TPStreamPlayerError.unauthorizedAccess.code, 5002)
    }

    func testFailedToFetchLicenseKeyHasCorrectCode() {
        XCTAssertEqual(TPStreamPlayerError.failedToFetchLicenseKey.code, 5003)
    }

    func testNoInternetConnectionHasCorrectCode() {
        XCTAssertEqual(TPStreamPlayerError.noInternetConnection.code, 5004)
    }

    func testServerErrorHasCorrectCode() {
        XCTAssertEqual(TPStreamPlayerError.serverError.code, 5005)
    }

    func testNetworkTimeoutHasCorrectCode() {
        XCTAssertEqual(TPStreamPlayerError.networkTimeout.code, 5006)
    }

    func testIncompleteOfflineVideoHasCorrectCode() {
        XCTAssertEqual(TPStreamPlayerError.incompleteOfflineVideo.code, 5007)
    }

    func testDrmSimulatorErrorHasCorrectCode() {
        XCTAssertEqual(TPStreamPlayerError.drmSimulatorError.code, 5008)
    }

    func testUnknownErrorHasCorrectCode() {
        XCTAssertEqual(TPStreamPlayerError.unknownError.code, 5100)
    }

    // MARK: - Error Codes via CustomNSError

    func testErrorCodeMatchesCodeProperty() {
        let allErrors: [TPStreamPlayerError] = [
            .resourceNotFound,
            .unauthorizedAccess,
            .failedToFetchLicenseKey,
            .noInternetConnection,
            .serverError,
            .networkTimeout,
            .incompleteOfflineVideo,
            .drmSimulatorError,
            .unknownError
        ]
        for error in allErrors {
            XCTAssertEqual(error.errorCode, error.code, "errorCode should match code for \(error)")
        }
    }

    // MARK: - Error Messages

    func testResourceNotFoundHasNonEmptyMessage() {
        XCTAssertFalse(TPStreamPlayerError.resourceNotFound.message.isEmpty)
    }

    func testUnauthorizedAccessHasNonEmptyMessage() {
        XCTAssertFalse(TPStreamPlayerError.unauthorizedAccess.message.isEmpty)
    }

    func testFailedToFetchLicenseKeyHasNonEmptyMessage() {
        XCTAssertFalse(TPStreamPlayerError.failedToFetchLicenseKey.message.isEmpty)
    }

    func testNoInternetConnectionHasNonEmptyMessage() {
        XCTAssertFalse(TPStreamPlayerError.noInternetConnection.message.isEmpty)
    }

    func testServerErrorHasNonEmptyMessage() {
        XCTAssertFalse(TPStreamPlayerError.serverError.message.isEmpty)
    }

    func testNetworkTimeoutHasNonEmptyMessage() {
        XCTAssertFalse(TPStreamPlayerError.networkTimeout.message.isEmpty)
    }

    func testIncompleteOfflineVideoHasNonEmptyMessage() {
        XCTAssertFalse(TPStreamPlayerError.incompleteOfflineVideo.message.isEmpty)
    }

    func testDrmSimulatorErrorHasNonEmptyMessage() {
        XCTAssertFalse(TPStreamPlayerError.drmSimulatorError.message.isEmpty)
    }

    func testUnknownErrorHasNonEmptyMessage() {
        XCTAssertFalse(TPStreamPlayerError.unknownError.message.isEmpty)
    }

    func testAllErrorsHaveUniqueMessages() {
        let allErrors: [TPStreamPlayerError] = [
            .resourceNotFound,
            .unauthorizedAccess,
            .failedToFetchLicenseKey,
            .noInternetConnection,
            .serverError,
            .networkTimeout,
            .incompleteOfflineVideo,
            .drmSimulatorError,
            .unknownError
        ]
        let messages = allErrors.map { $0.message }
        XCTAssertEqual(messages.count, Set(messages).count, "All error messages should be unique")
    }

    // MARK: - Sentry Logging Behavior

    func testNoInternetConnectionShouldNotLogToSentry() {
        XCTAssertFalse(TPStreamPlayerError.noInternetConnection.shouldLogToSentry)
    }

    func testIncompleteOfflineVideoShouldNotLogToSentry() {
        XCTAssertFalse(TPStreamPlayerError.incompleteOfflineVideo.shouldLogToSentry)
    }

    func testDrmSimulatorErrorShouldNotLogToSentry() {
        XCTAssertFalse(TPStreamPlayerError.drmSimulatorError.shouldLogToSentry)
    }

    func testResourceNotFoundShouldLogToSentry() {
        XCTAssertTrue(TPStreamPlayerError.resourceNotFound.shouldLogToSentry)
    }

    func testUnauthorizedAccessShouldLogToSentry() {
        XCTAssertTrue(TPStreamPlayerError.unauthorizedAccess.shouldLogToSentry)
    }

    func testFailedToFetchLicenseKeyShouldLogToSentry() {
        XCTAssertTrue(TPStreamPlayerError.failedToFetchLicenseKey.shouldLogToSentry)
    }

    func testServerErrorShouldLogToSentry() {
        XCTAssertTrue(TPStreamPlayerError.serverError.shouldLogToSentry)
    }

    func testNetworkTimeoutShouldLogToSentry() {
        XCTAssertTrue(TPStreamPlayerError.networkTimeout.shouldLogToSentry)
    }

    func testUnknownErrorShouldLogToSentry() {
        XCTAssertTrue(TPStreamPlayerError.unknownError.shouldLogToSentry)
    }

    // MARK: - CustomNSError userInfo

    func testErrorUserInfoContainsDebugDescription() {
        let error = TPStreamPlayerError.resourceNotFound
        let userInfo = error.errorUserInfo
        XCTAssertNotNil(userInfo[NSDebugDescriptionErrorKey])
        XCTAssertEqual(userInfo[NSDebugDescriptionErrorKey] as? String, error.message)
    }

    // MARK: - Error Identity

    func testAllErrorsAreDistinct() {
        let allErrors: [TPStreamPlayerError] = [
            .resourceNotFound,
            .unauthorizedAccess,
            .failedToFetchLicenseKey,
            .noInternetConnection,
            .serverError,
            .networkTimeout,
            .incompleteOfflineVideo,
            .drmSimulatorError,
            .unknownError
        ]
        let codes = allErrors.map { $0.code }
        XCTAssertEqual(codes.count, Set(codes).count, "All error codes should be unique")
    }
}
