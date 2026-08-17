import Foundation

// Standard XCTest network-mocking pattern: intercepts every request made
// through a URLSession configured with this as its only protocol class, so
// PresenceHeartbeatManagerTests never touches the real network.
final class MockURLProtocol: URLProtocol {
    struct StubbedResponse {
        let statusCode: Int
        let headers: [String: String]
        let body: Data?

        init(statusCode: Int, headers: [String: String] = [:], body: Data? = nil) {
            self.statusCode = statusCode
            self.headers = headers
            self.body = body
        }
    }

    private static let lock = NSLock()
    private static var responseQueue: [StubbedResponse] = []
    private static var _capturedRequests: [URLRequest] = []
    private static var failNextRequestWithError: Error?
    // Fired synchronously from startLoading() after a request is captured and
    // its response fully delivered, so tests can wait on an exact signal
    // instead of a fixed delay.
    static var onRequestHandled: ((URLRequest) -> Void)?

    static var capturedRequests: [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return _capturedRequests
    }

    static func reset() {
        lock.lock()
        responseQueue = []
        _capturedRequests = []
        failNextRequestWithError = nil
        onRequestHandled = nil
        lock.unlock()
    }

    static func enqueue(_ response: StubbedResponse) {
        lock.lock()
        responseQueue.append(response)
        lock.unlock()
    }

    static func failNextRequest(with error: Error) {
        lock.lock()
        failNextRequestWithError = error
        lock.unlock()
    }

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        MockURLProtocol.lock.lock()
        MockURLProtocol._capturedRequests.append(request)
        let error = MockURLProtocol.failNextRequestWithError
        MockURLProtocol.failNextRequestWithError = nil
        let stubbed = MockURLProtocol.responseQueue.isEmpty ? nil : MockURLProtocol.responseQueue.removeFirst()
        MockURLProtocol.lock.unlock()

        defer { MockURLProtocol.onRequestHandled?(request) }

        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        guard let stubbed = stubbed, let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: stubbed.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: stubbed.headers
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let body = stubbed.body {
            client?.urlProtocol(self, didLoad: body)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
