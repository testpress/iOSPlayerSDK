import XCTest
@testable import TPStreamsSDK

private let viewerId = "device-abc-123"
private let baseUrl = "https://presence.tpstreams.test"

// Records every scheduled beat instead of running it, so the test controls
// exactly when each one fires — the real request still goes through
// MockURLProtocol on URLSession's own background machinery, which is what
// makes a semaphore the right synchronization primitive here rather than a
// plain array.
private final class RecordingPresenceScheduler: PresenceScheduler {
    struct ScheduledCall {
        let seconds: TimeInterval
        let action: () -> Void
    }

    private let lock = NSLock()
    private var pending: [ScheduledCall] = []
    private let semaphore = DispatchSemaphore(value: 0)
    private(set) var cancelledCount = 0

    func schedule(after seconds: TimeInterval, action: @escaping () -> Void) -> PresenceCancellable {
        lock.lock()
        pending.append(ScheduledCall(seconds: seconds, action: action))
        lock.unlock()
        semaphore.signal()
        return RecordingCancellable(scheduler: self)
    }

    func awaitNextSchedule(timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) -> ScheduledCall {
        switch semaphore.wait(timeout: .now() + timeout) {
        case .timedOut:
            XCTFail("No beat was scheduled within the timeout", file: file, line: line)
            return ScheduledCall(seconds: 0, action: {})
        case .success:
            lock.lock()
            defer { lock.unlock() }
            return pending.removeFirst()
        }
    }

    func assertNothingScheduled(within seconds: TimeInterval, file: StaticString = #filePath, line: UInt = #line) {
        switch semaphore.wait(timeout: .now() + seconds) {
        case .success:
            XCTFail("expected no further beat to be scheduled, but one was", file: file, line: line)
        case .timedOut:
            break
        }
    }

    fileprivate func recordCancellation() {
        lock.lock()
        cancelledCount += 1
        lock.unlock()
    }
}

private final class RecordingCancellable: PresenceCancellable {
    private weak var scheduler: RecordingPresenceScheduler?

    init(scheduler: RecordingPresenceScheduler) {
        self.scheduler = scheduler
    }

    func cancel() {
        scheduler?.recordCancellation()
    }
}

final class PresenceHeartbeatManagerTests: XCTestCase {
    private var scheduler: RecordingPresenceScheduler!

    override func setUp() {
        super.setUp()
        scheduler = RecordingPresenceScheduler()
        MockURLProtocol.reset()
    }

    private func buildManager(
        onTokenExpired: @escaping (@escaping (String) -> Void) -> Void = { callback in callback("") },
        onError: ((Error) -> Void)? = nil
    ) -> PresenceHeartbeatManager {
        return PresenceHeartbeatManager(
            urlSession: MockURLProtocol.session(),
            viewerId: viewerId,
            scheduler: scheduler,
            onTokenExpired: onTokenExpired,
            onError: onError
        )
    }

    private func okResponse(nextHeartbeatIn: Int = 15) -> MockURLProtocol.StubbedResponse {
        let body = try! JSONSerialization.data(withJSONObject: ["ok": true, "next_heartbeat_in": nextHeartbeatIn])
        return MockURLProtocol.StubbedResponse(statusCode: 200, body: body)
    }

    // Arms an expectation for the Nth request MockURLProtocol fully handles
    // (captured and responded to) — call before triggering the action that
    // causes it, then wait(for:) after. Precise regardless of how long
    // URLSession takes to dispatch onto the protocol, unlike a fixed delay.
    private func expectRequestsHandled(_ count: Int) -> XCTestExpectation {
        let expectation = expectation(description: "\(count) request(s) handled")
        var handled = 0
        MockURLProtocol.onRequestHandled = { _ in
            handled += 1
            if handled >= count {
                expectation.fulfill()
            }
        }
        return expectation
    }

    private func bodyJSON(_ request: URLRequest) -> [String: Any] {
        guard let data = request.httpBody ?? request.httpBodyStream.map({ stream -> Data in
            stream.open()
            defer { stream.close() }
            var data = Data()
            let bufferSize = 1024
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: bufferSize)
                if read > 0 { data.append(buffer, count: read) }
            }
            return data
        }) else { return [:] }
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    func testSendsTheFirstHeartbeatWithTheBearerTokenAndThePersistedViewerId() {
        MockURLProtocol.enqueue(okResponse())
        let manager = buildManager()
        let handled = expectRequestsHandled(1)

        manager.start(baseUrl: baseUrl, token: "token-1")
        scheduler.awaitNextSchedule().action()
        wait(for: [handled], timeout: 5)

        let request = MockURLProtocol.capturedRequests.first
        XCTAssertEqual(request?.url?.absoluteString, "\(baseUrl)/presence/v1/heartbeat")
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Bearer token-1")
        XCTAssertEqual(bodyJSON(request!)["viewer_id"] as? String, viewerId)
    }

    func testSchedulesTheNextHeartbeatUsingNextHeartbeatInFromTheResponse() {
        MockURLProtocol.enqueue(okResponse(nextHeartbeatIn: 42))
        let manager = buildManager()

        manager.start(baseUrl: baseUrl, token: "token-1")
        scheduler.awaitNextSchedule().action()

        XCTAssertEqual(scheduler.awaitNextSchedule().seconds, 42)
    }

    func testOn401RefreshesViaOnTokenExpiredAndResumesWithTheNewToken() {
        MockURLProtocol.enqueue(MockURLProtocol.StubbedResponse(statusCode: 401))
        MockURLProtocol.enqueue(okResponse())
        var refreshCallCount = 0
        let manager = buildManager(onTokenExpired: { callback in
            refreshCallCount += 1
            callback("refreshed-token")
        })

        manager.start(baseUrl: baseUrl, token: "token-1")
        scheduler.awaitNextSchedule().action()
        // Only appears once the 401 response has been fully processed and the
        // refresh (synchronous in this test) has rescheduled — the queue
        // itself is the synchronization point, no fixed delay needed here.
        let secondCall = scheduler.awaitNextSchedule()
        let handled = expectRequestsHandled(1)
        secondCall.action()
        wait(for: [handled], timeout: 5)

        XCTAssertEqual(refreshCallCount, 1)
        XCTAssertEqual(MockURLProtocol.capturedRequests.last?.value(forHTTPHeaderField: "Authorization"), "Bearer refreshed-token")
    }

    func testKeepsBackingOffInsteadOfGivingUpWhenRefreshKeepsFailing() {
        MockURLProtocol.enqueue(MockURLProtocol.StubbedResponse(statusCode: 401))
        MockURLProtocol.enqueue(MockURLProtocol.StubbedResponse(statusCode: 401))
        let manager = buildManager(onTokenExpired: { callback in callback("") })

        manager.start(baseUrl: baseUrl, token: "token-1")
        scheduler.awaitNextSchedule().action()
        let afterFirstFailure = scheduler.awaitNextSchedule()
        XCTAssertEqual(afterFirstFailure.seconds, 15)
        afterFirstFailure.action()

        let afterSecondFailure = scheduler.awaitNextSchedule()
        XCTAssertGreaterThan(afterSecondFailure.seconds, afterFirstFailure.seconds)
    }

    func testRespectsRetryAfterOnA429InsteadOfTheDefaultInterval() {
        MockURLProtocol.enqueue(MockURLProtocol.StubbedResponse(statusCode: 429, headers: ["Retry-After": "5"]))
        let manager = buildManager()

        manager.start(baseUrl: baseUrl, token: "token-1")
        scheduler.awaitNextSchedule().action()

        XCTAssertEqual(scheduler.awaitNextSchedule().seconds, 5)
    }

    func testSwallowsANetworkErrorAndKeepsTheLoopAliveOnTheFallbackCadence() {
        MockURLProtocol.failNextRequest(with: URLError(.notConnectedToInternet))
        var observedError: Error?
        let manager = buildManager(onError: { observedError = $0 })

        manager.start(baseUrl: baseUrl, token: "token-1")
        scheduler.awaitNextSchedule().action()

        XCTAssertEqual(scheduler.awaitNextSchedule().seconds, 15)
        XCTAssertNotNil(observedError)
    }

    func testStartIsIdempotentCallingItTwiceDoesNotScheduleASecondLoop() {
        MockURLProtocol.enqueue(okResponse())
        let manager = buildManager()
        let handled = expectRequestsHandled(1)

        manager.start(baseUrl: baseUrl, token: "token-1")
        manager.start(baseUrl: baseUrl, token: "token-2")
        scheduler.awaitNextSchedule().action()
        wait(for: [handled], timeout: 5)

        XCTAssertEqual(MockURLProtocol.capturedRequests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer token-1")
        scheduler.assertNothingScheduled(within: 0.2)
    }

    func testStopSendsALeaveBeaconWithThePresenceTokenAndTheSameViewerId() {
        MockURLProtocol.enqueue(MockURLProtocol.StubbedResponse(statusCode: 204))
        let manager = buildManager()
        let handled = expectRequestsHandled(1)

        manager.start(baseUrl: baseUrl, token: "token-1")
        manager.stop()
        wait(for: [handled], timeout: 5)

        let request = MockURLProtocol.capturedRequests.first
        XCTAssertEqual(request?.url?.absoluteString, "\(baseUrl)/presence/v1/leave")
        let body = bodyJSON(request!)
        XCTAssertEqual(body["presence_token"] as? String, "token-1")
        XCTAssertEqual(body["viewer_id"] as? String, viewerId)
    }

    func testStopCancelsTheScheduledBeat() {
        MockURLProtocol.enqueue(MockURLProtocol.StubbedResponse(statusCode: 204))
        let manager = buildManager()

        manager.start(baseUrl: baseUrl, token: "token-1")
        manager.stop()

        XCTAssertEqual(scheduler.cancelledCount, 1)
    }

    func testStopIsIdempotentASecondCallDoesNotSendAnotherBeacon() {
        MockURLProtocol.enqueue(MockURLProtocol.StubbedResponse(statusCode: 204))
        let manager = buildManager()

        let handled = expectRequestsHandled(1)
        manager.start(baseUrl: baseUrl, token: "token-1")
        manager.stop()
        wait(for: [handled], timeout: 5)
        manager.stop()

        // Only a positive signal exists for "the first beacon was sent"; a
        // second call sending nothing has no event to wait on, so this grace
        // period is a deliberate exception to preferring the expectation
        // above over a fixed delay.
        let settle = expectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { settle.fulfill() }
        wait(for: [settle], timeout: 2)

        XCTAssertEqual(MockURLProtocol.capturedRequests.count, 1)
    }
}
