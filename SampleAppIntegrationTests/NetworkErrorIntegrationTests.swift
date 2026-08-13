//
//  NetworkErrorIntegrationTests.swift
//  SampleAppIntegrationTests
//
//  Tests network error handling through the public SDK API.
//  Verifies the SDK handles network failures gracefully.
//
//  Note: These tests simulate network errors via the mock layer.
//  The mock URLProtocol determines the response (or lack thereof).
//  The SDK's public API (completion callback, onError) conveys the result.
//

import XCTest
import TPStreamsSDK

final class NetworkErrorIntegrationTests: XCTestCase {

    private let orgCode = "integration-test-org"

    override func setUp() {
        super.setUp()
        TPStreamsSDK.initialize(for: .tpstreams, withOrgCode: orgCode)
    }

    override func tearDown() {
        teardownMockNetwork()
        super.tearDown()
    }

    // MARK: - Network Unavailable

    func testPlayerInitFailsWhenNetworkUnavailable() {
        // Set up mock that fails all requests (simulating no network)
        MockURLProtocol.requestHandler = { _ in return nil }
        URLProtocol.registerClass(MockURLProtocol.self)

        let ready = XCTestExpectation(description: "Player init")
        var capturedError: Error?

        let player = TPAVPlayer(assetID: "integration-test-asset",
                                 accessToken: "test-access-token") { error in
            capturedError = error
            ready.fulfill()
        }

        let result = XCTWaiter.wait(for: [ready], timeout: 15.0)
        XCTAssertEqual(result, .completed, "Completion should fire even with network failure")
        XCTAssertNotNil(capturedError, "Error should be reported when network is unavailable")
        XCTAssertNotNil(player, "Player object should still be created even if init fails")
    }

    // MARK: - Malformed Response

    func testPlayerInitFailsWithMalformedResponse() {
        // Set up mock that returns malformed JSON (missing all required fields)
        setupMockNetwork(assetResponse: MockResponses.malformedResponse)

        let ready = XCTestExpectation(description: "Player init")
        var capturedError: Error?

        TPAVPlayer(assetID: "integration-test-asset",
                    accessToken: "test-access-token") { error in
            capturedError = error
            ready.fulfill()
        }

        let result = XCTWaiter.wait(for: [ready], timeout: 15.0)
        XCTAssertEqual(result, .completed)
        XCTAssertNotNil(capturedError, "Should report error for malformed response")
    }

    // MARK: - HTTP Error Status

    func testPlayerInitFailsWhenServerReturns500() {
        // Configure mock to return 500 for API requests
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url else { return nil }
            if url.absoluteString.contains("tpstreams.com/api/v1/") {
                let data = "{\"error\":\"Internal Server Error\"}".data(using: .utf8)!
                let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
                return (data, response)
            }
            return nil
        }
        URLProtocol.registerClass(MockURLProtocol.self)

        let ready = XCTestExpectation(description: "Player init")
        var capturedError: Error?

        TPAVPlayer(assetID: "integration-test-asset",
                    accessToken: "test-access-token") { error in
            capturedError = error
            ready.fulfill()
        }

        let result = XCTWaiter.wait(for: [ready], timeout: 15.0)
        XCTAssertEqual(result, .completed)
        XCTAssertNotNil(capturedError, "Should report error for HTTP 500")
    }

    func testPlayerInitFailsWith403Forbidden() {
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url else { return nil }
            if url.absoluteString.contains("tpstreams.com/api/v1/") {
                let data = "{\"error\":\"Forbidden\"}".data(using: .utf8)!
                let response = HTTPURLResponse(url: url, statusCode: 403, httpVersion: nil, headerFields: nil)!
                return (data, response)
            }
            return nil
        }
        URLProtocol.registerClass(MockURLProtocol.self)

        let ready = XCTestExpectation(description: "Player init")
        var capturedError: Error?

        TPAVPlayer(assetID: "integration-test-asset",
                    accessToken: "test-access-token") { error in
            capturedError = error
            ready.fulfill()
        }

        let result = XCTWaiter.wait(for: [ready], timeout: 15.0)
        XCTAssertEqual(result, .completed)
        XCTAssertNotNil(capturedError, "Should report error for 403")
    }

    // MARK: - Timeout Simulation

    func testPlayerInitHandlesTimeoutGracefully() {
        // Simulate a slow response by delaying the mock
        MockURLProtocol.requestHandler = { request in
            Thread.sleep(forTimeInterval: 0.5) // Simulate network latency
            guard let url = request.url else { return nil }
            if url.absoluteString.contains("tpstreams.com/api/v1/") {
                return MockResponses.response(for: url, config: MockConfig())
            }
            return nil
        }
        URLProtocol.registerClass(MockURLProtocol.self)

        let ready = XCTestExpectation(description: "Player init")
        var capturedError: Error?

        TPAVPlayer(assetID: "integration-test-asset",
                    accessToken: "test-access-token") { error in
            capturedError = error
            ready.fulfill()
        }

        let result = XCTWaiter.wait(for: [ready], timeout: 30.0)
        XCTAssertEqual(result, .completed, "Init should complete despite latency")
        // May succeed or fail depending on timing — just shouldn't crash
    }
}
