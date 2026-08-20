import Foundation

// Mirrors the web presence-client's heartbeat loop (see player.js's
// PresenceClient) and the Android SDK's PresenceHeartbeatManager, so all
// three behave identically from the server's point of view. Kept entirely
// internal to the player: an app never starts or stops this directly, only
// TPStreamPlayerDelegate.presenceTokenExpired reaches outside this class,
// when a fresh token is needed.
final class PresenceHeartbeatManager {
    enum PresenceError: Error {
        case invalidResponse
        case unexpectedStatusCode(Int)
    }

    private static let maxBackoffMultiplier = 8

    private let urlSession: URLSession
    private let viewerId: String
    private let scheduler: PresenceScheduler
    // Called on a 401 with a callback that must be invoked with a fresh token,
    // or an empty string if none could be obtained. An app that hasn't
    // implemented presenceTokenExpired simply never calls this back, and the
    // loop quietly stops rather than erroring.
    private let onTokenExpired: (@escaping (String) -> Void) -> Void
    private let onError: ((Error) -> Void)?
    private let fallbackInterval: TimeInterval

    private let lock = NSLock()
    private var token: String = ""
    private var baseUrl: String = ""
    private var active = false
    private var unauthorizedStreak = 0
    private var scheduled: PresenceCancellable?

    init(
        urlSession: URLSession = .shared,
        viewerId: String,
        scheduler: PresenceScheduler,
        onTokenExpired: @escaping (@escaping (String) -> Void) -> Void,
        onError: ((Error) -> Void)? = nil,
        fallbackInterval: TimeInterval = 15
    ) {
        self.urlSession = urlSession
        self.viewerId = viewerId
        self.scheduler = scheduler
        self.onTokenExpired = onTokenExpired
        self.onError = onError
        self.fallbackInterval = fallbackInterval
    }

    // Call this only while playback is actually active. Safe to call more
    // than once; a call while already active is a no-op.
    func start(baseUrl: String, token: String) {
        lock.lock()
        defer { lock.unlock() }
        guard !active, !baseUrl.isEmpty, !token.isEmpty else { return }
        self.baseUrl = baseUrl
        self.token = token
        self.unauthorizedStreak = 0
        active = true
        // Spreads the first beat across the interval instead of firing it the
        // moment playback starts. A scheduled class means many viewers
        // pressing play within the same few seconds, and without this they
        // would then beat in lockstep for the whole session — a request spike
        // every interval rather than steady load.
        scheduleNextBeatLocked(after: TimeInterval.random(in: 0..<fallbackInterval))
    }

    // Sends a final leave beacon and stops the loop. Safe to call more than
    // once or without a matching start().
    func stop() {
        lock.lock()
        guard active else {
            lock.unlock()
            return
        }
        active = false
        scheduled?.cancel()
        scheduled = nil
        let currentToken = token
        let currentBaseUrl = baseUrl
        lock.unlock()
        sendLeaveBeacon(baseUrl: currentBaseUrl, token: currentToken)
    }

    // Assumes the lock is already held by the caller.
    private func scheduleNextBeatLocked(after seconds: TimeInterval) {
        guard active else { return }
        scheduled = scheduler.schedule(after: seconds) { [weak self] in self?.beat() }
    }

    private func scheduleNextBeat(after seconds: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        scheduleNextBeatLocked(after: seconds)
    }

    private func beat() {
        lock.lock()
        guard active else {
            lock.unlock()
            return
        }
        let currentToken = token
        let currentBaseUrl = baseUrl
        lock.unlock()

        guard let url = URL(string: "\(currentBaseUrl)/presence/v1/heartbeat") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(currentToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Resent on every call, not just once when requesting playback: the
        // server hashes it and checks it still matches the vid baked into the
        // token, so a token copied to another device gets rejected.
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["viewer_id": viewerId])

        urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            // Network hiccup: keep the loop alive on the fallback cadence
            // rather than letting this bring playback down with it.
            if let error = error {
                self.onError?(error)
                self.scheduleNextBeat(after: self.fallbackInterval)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                self.onError?(PresenceError.invalidResponse)
                self.scheduleNextBeat(after: self.fallbackInterval)
                return
            }
            self.handleHeartbeatResponse(httpResponse, data: data)
        }.resume()
    }

    private func handleHeartbeatResponse(_ response: HTTPURLResponse, data: Data?) {
        switch response.statusCode {
        case 401:
            recoverFromUnauthorized()
        case 429:
            lock.lock()
            unauthorizedStreak = 0
            lock.unlock()
            let retryAfter = response.value(forHTTPHeaderField: "Retry-After").flatMap(Double.init)
            scheduleNextBeat(after: retryAfter ?? fallbackInterval)
        case 200..<300:
            lock.lock()
            unauthorizedStreak = 0
            lock.unlock()
            scheduleNextBeat(after: parseNextHeartbeatIn(data) ?? fallbackInterval)
        default:
            onError?(PresenceError.unexpectedStatusCode(response.statusCode))
            scheduleNextBeat(after: fallbackInterval)
        }
    }

    private func parseNextHeartbeatIn(_ data: Data?) -> TimeInterval? {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let value = json["next_heartbeat_in"] as? NSNumber else {
            return nil
        }
        return value.doubleValue
    }

    // A 401 here could mean either an expired token or a device-binding
    // mismatch — there's no need to tell them apart, both are resolved by
    // asking the integrator for a fresh playback config and resuming with its
    // token, exactly like the web SDK's recoverFromUnauthorized.
    private func recoverFromUnauthorized() {
        lock.lock()
        unauthorizedStreak += 1
        lock.unlock()
        onTokenExpired { [weak self] newToken in
            guard let self = self else { return }
            if !newToken.isEmpty {
                self.applyRefreshedToken(newToken)
            } else {
                self.backOffAfterFailedRefresh()
            }
        }
    }

    private func applyRefreshedToken(_ newToken: String) {
        lock.lock()
        guard active else {
            lock.unlock()
            return
        }
        token = newToken
        unauthorizedStreak = 0
        lock.unlock()
        scheduleNextBeat(after: fallbackInterval)
    }

    private func backOffAfterFailedRefresh() {
        lock.lock()
        guard active else {
            lock.unlock()
            return
        }
        // Backs off further each consecutive failure — capped, not abandoned:
        // an integrator's own backend can be down for a while and recover,
        // and this loop has no playback-affecting reason to ever give up on it.
        let multiplier = min(unauthorizedStreak, Self.maxBackoffMultiplier)
        lock.unlock()
        scheduleNextBeat(after: fallbackInterval * TimeInterval(multiplier))
    }

    private func sendLeaveBeacon(baseUrl: String, token: String) {
        // Best-effort, fire-and-forget: never blocks player teardown on a
        // response.
        guard let url = URL(string: "\(baseUrl)/presence/v1/leave") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "presence_token": token,
            "viewer_id": viewerId,
        ])
        urlSession.dataTask(with: request) { [weak self] _, _, error in
            if let error = error {
                self?.onError?(error)
            }
        }.resume()
    }
}
