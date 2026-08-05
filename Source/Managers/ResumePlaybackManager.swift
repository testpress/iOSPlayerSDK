import Foundation
import AVFoundation

final class ResumePlaybackManager {
    private static let resumePlaybackBaseURL = "https://data.tpstreams.com"
    private static let periodicSaveInterval: TimeInterval = 120

    private enum Endpoint {
        static let lastWatchedPosition = "api/player/last-watched-position/"
        static let updateWatchedPosition = "api/player/update-watched-position/"
    }

    private let player: AVPlayer
    private let organizationId: String
    private let assetId: String
    private var hasFetched = false
    private var isEnded = false
    private var saveTimer: Timer?
    private let onSeekCompleted: ((Double) -> Void)?

    init(player: AVPlayer, organizationId: String, assetId: String, onSeekCompleted: ((Double) -> Void)? = nil) {
        self.player = player
        self.organizationId = organizationId
        self.assetId = assetId
        self.onSeekCompleted = onSeekCompleted
        startPeriodicSave()
    }

    deinit {
        saveTimer?.invalidate()
    }

    func resumeFromLastPosition() {
        guard !hasFetched, let body = watchBody else { return }
        hasFetched = true
        request(method: "POST",
                endpoint: Endpoint.lastWatchedPosition,
                body: body) { [weak self] data in
            guard let self = self,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let seconds = json["watched_seconds"] as? Double,
                  seconds > 0 else { return }
            DispatchQueue.main.async {
                self.player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600),
                                 toleranceBefore: CMTime.zero,
                                 toleranceAfter: CMTime.zero) { _ in
                    self.onSeekCompleted?(seconds)
                }
            }
        }
    }

    func saveWatchedPosition() {
        guard !isEnded, let body = watchBody, player.currentItem?.status != .failed else { return }
        let seconds = Int(round(player.currentTime().seconds))
        guard seconds > 0 else { return }
        var requestBody = body
        requestBody["watched_seconds"] = seconds
        request(method: "POST", endpoint: Endpoint.updateWatchedPosition, body: requestBody)
    }

    func deleteWatchedPosition() {
        guard let body = watchBody else { return }
        isEnded = true
        stopPeriodicSave()
        request(method: "DELETE", endpoint: Endpoint.lastWatchedPosition, body: body)
    }

    func reset() {
        isEnded = false
        startPeriodicSave()
    }

    func finalSaveAndStop() {
        saveWatchedPosition()
        stopPeriodicSave()
    }

    private func startPeriodicSave() {
        saveTimer?.invalidate()
        let timer = Timer(timeInterval: Self.periodicSaveInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.player.timeControlStatus == .playing else { return }
            self.saveWatchedPosition()
        }
        RunLoop.main.add(timer, forMode: .common)
        saveTimer = timer
    }

    private func stopPeriodicSave() {
        saveTimer?.invalidate()
        saveTimer = nil
    }

    private var watchBody: [String: Any]? {
        guard let userId = TPStreamsSDK.userId else { return nil }
        return ["user_id": userId,
                "organization_id": organizationId,
                "asset_id": assetId]
    }

    private func request(method: String, endpoint: String, body: [String: Any], completion: ((Data?) -> Void)? = nil) {
        guard let url = URL(string: "\(Self.resumePlaybackBaseURL)/\(endpoint)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                debugPrint("ResumePlaybackManager request failed: \(error)")
            } else if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                debugPrint("ResumePlaybackManager request failed: HTTP \(http.statusCode)")
            }
            completion?(data)
        }.resume()
    }
}
