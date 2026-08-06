import Foundation

final class TpstreamsVideoData {
    private static let baseURL = "https://data.tpstreams.com"

    private enum Endpoint {
        static let lastWatchedPosition = "api/player/last-watched-position/"
        static let updateWatchedPosition = "api/player/update-watched-position/"
    }

    func fetchLastWatchedPosition(userId: String, assetID: String, completion: @escaping (Double?) -> Void) {
        request(method: "POST", endpoint: Endpoint.lastWatchedPosition, body: body(userId: userId, assetID: assetID)) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let seconds = json["watched_seconds"] as? Double,
                  seconds > 0 else {
                completion(nil)
                return
            }
            completion(seconds)
        }
    }

    func updateLastWatchedPosition(_ position: Double, userId: String, assetID: String) {
        var body = body(userId: userId, assetID: assetID)
        body["watched_seconds"] = Int(round(position))
        request(method: "POST", endpoint: Endpoint.updateWatchedPosition, body: body)
    }

    func deleteLastWatchedPosition(userId: String, assetID: String) {
        request(method: "DELETE", endpoint: Endpoint.lastWatchedPosition, body: body(userId: userId, assetID: assetID))
    }

    private func body(userId: String, assetID: String) -> [String: Any] {
        ["user_id": userId,
         "organization_id": TPStreamsSDK.orgCode ?? "",
         "asset_id": assetID]
    }

    private func request(method: String, endpoint: String, body: [String: Any], completion: ((Data?) -> Void)? = nil) {
        guard let url = URL(string: "\(Self.baseURL)/\(endpoint)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                debugPrint("TpstreamsVideoData request failed: \(error)")
            } else if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                debugPrint("TpstreamsVideoData request failed: HTTP \(http.statusCode)")
            }
            completion?(data)
        }.resume()
    }
}
