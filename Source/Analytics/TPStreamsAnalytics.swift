import UIKit

internal enum TPStreamsAnalyticsIdentity {
    private static let service = "com.tpstreams.analytics"
    private static let visitorAccount = "visitor_id"
    private static let generatedVisitorID = UUID().uuidString.replacingOccurrences(of: "-", with: "")

    static var visitorID: String {
        if let data = KeychainUtil.get(service: service, account: visitorAccount),
           let value = String(data: data, encoding: .utf8), !value.isEmpty {
            return value
        }
        KeychainUtil.save(data: Data(generatedVisitorID.utf8), service: service, account: visitorAccount)
        return generatedVisitorID
    }

    static func sessionID() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
}

internal enum TPStreamsAnalyticsUserAgent {
    static var value: String {
        let systemVersion = UIDevice.current.systemVersion
        if UIDevice.current.userInterfaceIdiom == .pad {
            return "Mozilla/5.0 (iPad; CPU OS \(systemVersion) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15 TPStreamsIOSPlayer/1.0"
        }
        return "Mozilla/5.0 (iPhone; CPU iPhone OS \(systemVersion) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1 TPStreamsIOSPlayer/1.0"
    }
}

internal final class TPStreamsAnalyticsUploader {
    private let orgID: String
    private let assetID: String
    private let visitorID: String
    private let sessionID: String
    private let accessToken: String?
    private let userAgent: String

    private var presignedUploadURL: URL?
    private var ipAddress: String?
    private var location: String?
    private let stateQueue = DispatchQueue(label: "com.tpstreams.analytics.uploader")
    private var presignedRequestInFlight = false
    private var presignedRequestCompletions: [(Bool) -> Void] = []
    private var pendingUploads: [(Int, (Bool) -> Void)] = []
    private var queuedUploads: [(Int, (Bool) -> Void)] = []
    private var uploadInFlight = false

    init(orgID: String, assetID: String, visitorID: String, sessionID: String,
         accessToken: String?, userAgent: String) {
        self.orgID = orgID
        self.assetID = assetID
        self.visitorID = visitorID
        self.sessionID = sessionID
        self.accessToken = accessToken
        self.userAgent = userAgent
    }

    func start(completion: @escaping () -> Void) {
        fetchPresignedURL { _ in completion() }
    }

    func upload(durationSeconds: Int, completion: @escaping (Bool) -> Void) {
        stateQueue.async { [self] in
            guard self.presignedUploadURL != nil else {
                self.pendingUploads.append((durationSeconds, completion))
                self.fetchPresignedURLOnQueue(completion: nil)
                return
            }
            self.enqueueUploadOnQueue(durationSeconds: durationSeconds, completion: completion)
        }
    }

    private func fetchPresignedURL(completion: @escaping (Bool) -> Void) {
        stateQueue.async { [self] in
            self.fetchPresignedURLOnQueue(completion: completion)
        }
    }

    private func fetchPresignedURLOnQueue(completion: ((Bool) -> Void)?) {
        if let completion = completion {
            presignedRequestCompletions.append(completion)
        }
        guard !presignedRequestInFlight else { return }
        presignedRequestInFlight = true

        TPStreamsSDK.provider.API.fetchAnalyticsPresignedURL(
            orgID,
            assetID,
            visitorID,
            sessionID,
            accessToken,
            userAgent
        ) { [self] value in
            self.stateQueue.async {
                let success: Bool
                if let value = value {
                    self.presignedUploadURL = value.presignedUploadURL
                    self.ipAddress = value.ipAddress
                    self.location = value.location
                    success = true
                } else {
                    success = false
                }

                self.presignedRequestInFlight = false
                let requestCompletions = self.presignedRequestCompletions
                self.presignedRequestCompletions.removeAll()
                requestCompletions.forEach { $0(success) }

                let queuedUploads = self.pendingUploads
                self.pendingUploads.removeAll()
                if success {
                    queuedUploads.forEach {
                        self.enqueueUploadOnQueue(durationSeconds: $0.0, completion: $0.1)
                    }
                } else {
                    queuedUploads.forEach { $0.1(false) }
                }
            }
        }
    }

    private func enqueueUploadOnQueue(durationSeconds: Int, completion: @escaping (Bool) -> Void) {
        guard presignedUploadURL != nil else {
            pendingUploads.append((durationSeconds, completion))
            fetchPresignedURLOnQueue(completion: nil)
            return
        }
        guard !uploadInFlight else {
            queuedUploads.append((durationSeconds, completion))
            return
        }
        sendUploadOnQueue(durationSeconds: durationSeconds, completion: completion)
    }

    private func sendUploadOnQueue(
        durationSeconds: Int,
        retryAfterForbidden: Bool = true,
        completion: @escaping (Bool) -> Void
    ) {
        guard let uploadURL = presignedUploadURL else { completion(false); return }
        uploadInFlight = true
        TPStreamsSDK.provider.API.uploadAnalytics(
            uploadURL,
            assetID,
            orgID,
            visitorID,
            sessionID,
            durationSeconds,
            userAgent,
            ipAddress,
            location
        ) { [self] success, statusCode in
            self.stateQueue.async {
                if statusCode == 403 {
                    self.presignedUploadURL = nil
                    guard retryAfterForbidden else {
                        self.completeUploadOnQueue(success: false, completion: completion)
                        return
                    }

                    // A presigned URL can expire while a session is still active. Refresh it
                    // once and retry this same duration so the final release upload is not lost.
                    self.fetchPresignedURLOnQueue { refreshed in
                        guard refreshed else {
                            self.completeUploadOnQueue(success: false, completion: completion)
                            return
                        }
                        self.sendUploadOnQueue(
                            durationSeconds: durationSeconds,
                            retryAfterForbidden: false,
                            completion: completion
                        )
                    }
                    return
                }
                self.completeUploadOnQueue(success: success, completion: completion)
            }
        }
    }

    private func completeUploadOnQueue(success: Bool, completion: @escaping (Bool) -> Void) {
        uploadInFlight = false
        if !queuedUploads.isEmpty {
            let nextUpload = queuedUploads.removeFirst()
            enqueueUploadOnQueue(durationSeconds: nextUpload.0, completion: nextUpload.1)
        }
        completion(success)
    }
}

internal final class TPStreamsAnalyticsTracker {
    private let stateLock = NSRecursiveLock()
    private let uploader: TPStreamsAnalyticsUploader
    private let heartbeatInterval: TimeInterval = 5 * 60
    private var heartbeatTimer: Timer?
    private var started = false
    private var released = false
    private var isPlaying = false
    private var cumulativeDuration: TimeInterval = 0
    private var playingStartedAt: TimeInterval?
    private var highestUploadedDuration = -1
    private var uploadInFlight = false
    private var uploadPending = false

    init?(player: TPAVPlayer, accessToken: String?) {
        guard TPStreamsSDK.provider == .tpstreams,
              !player.isPlaybackOffline,
              let orgID = TPStreamsSDK.orgCode,
              let assetID = player.assetID else { return nil }
        uploader = TPStreamsAnalyticsUploader(
            orgID: orgID, assetID: assetID,
            visitorID: TPStreamsAnalyticsIdentity.visitorID,
            sessionID: TPStreamsAnalyticsIdentity.sessionID(),
            accessToken: accessToken,
            userAgent: TPStreamsAnalyticsUserAgent.value
        )
    }

    func start() {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard !started, !released else { return }
        started = true
        uploader.start { }
    }

    func playbackDidChange(to status: String) {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard started, !released else { return }
        switch status {
        case "playing": beginPlaying()
        case "paused", "buffering", "ended":
            stopPlaying()
            uploadIfNeeded()
        default: break
        }
    }

    func seeked() {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard started, !released else { return }
        if isPlaying {
            accumulatePlayingTime()
            playingStartedAt = ProcessInfo.processInfo.systemUptime
        }
        uploadIfNeeded()
    }

    /// Stops tracking this playback session and queues one final duration upload.
    /// The upload is intentionally asynchronous so player teardown never blocks playback.
    func finishSession() {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard !released else { return }
        if started {
            // Accumulate the time since the last heartbeat before sending the final value.
            stopPlaying()
            let seconds = Int(cumulativeDuration)
            if seconds > 0, seconds > highestUploadedDuration {
                // Queue the final value independently of the tracker lifecycle. The uploader
                // serializes it behind any heartbeat or pause upload already in flight.
                uploader.upload(durationSeconds: seconds) { _ in }
            }
        }
        invalidateHeartbeatTimer()
        released = true
    }

    private func beginPlaying() {
        guard !isPlaying else { return }
        isPlaying = true
        playingStartedAt = ProcessInfo.processInfo.systemUptime
        invalidateHeartbeatTimer()
        let timer = Timer(timeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.uploadIfNeeded()
        }
        RunLoop.main.add(timer, forMode: .common)
        heartbeatTimer = timer
    }

    private func stopPlaying() {
        guard isPlaying else { return }
        accumulatePlayingTime()
        isPlaying = false
        playingStartedAt = nil
        invalidateHeartbeatTimer()
    }

    private func invalidateHeartbeatTimer() {
        guard let timer = heartbeatTimer else { return }
        heartbeatTimer = nil
        if Thread.isMainThread {
            timer.invalidate()
        } else {
            DispatchQueue.main.async {
                timer.invalidate()
            }
        }
    }

    private func accumulatePlayingTime() {
        guard let startedAt = playingStartedAt else { return }
        cumulativeDuration += max(0, ProcessInfo.processInfo.systemUptime - startedAt)
    }

    private func uploadIfNeeded() {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard started, !released else { return }
        var duration = cumulativeDuration
        if isPlaying, let startedAt = playingStartedAt {
            // Heartbeats and state changes can occur between timer callbacks, so include the
            // currently active segment without resetting its start time.
            duration += max(0, ProcessInfo.processInfo.systemUptime - startedAt)
        }
        let seconds = Int(duration)
        guard seconds > 0, seconds > highestUploadedDuration else { return }
        guard !uploadInFlight else {
            uploadPending = true
            return
        }
        uploadInFlight = true
        uploader.upload(durationSeconds: seconds) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.stateLock.lock()
                defer { self.stateLock.unlock() }
                self.uploadInFlight = false
                if success {
                    self.highestUploadedDuration = max(self.highestUploadedDuration, seconds)
                }
                if self.uploadPending {
                    self.uploadPending = false
                    self.uploadIfNeeded()
                }
            }
        }
    }
}
