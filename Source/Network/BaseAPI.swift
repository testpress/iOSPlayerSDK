//
//  BaseAPI.swift
//  TPStreamsSDK
//
//  Created by Testpress on 03/06/23.
//

import Foundation
import Alamofire

class BaseAPI {
    class var VIDEO_DETAIL_API: String {
        fatalError("VIDEO_DETAIL_API must be implemented by subclasses.")
    }
    class var DRM_LICENSE_API: String {
        fatalError("DRM_LICENSE_API must be implemented by subclasses.")
    }
    class var AES_ENCRYPTION_KEY_API: String {
        fatalError("AES_ENCRYPTION_KEY_API must be implemented by subclasses.")
    }
    class var ANALYTICS_PRESIGNED_URL_API: String {
        fatalError("ANALYTICS_PRESIGNED_URL_API must be implemented by subclasses.")
    }
    class var parser: APIParser {
        fatalError("parser must be implemented by subclasses.")
    }
    
    class var userAgentPrefix: String? {
        return nil
    }
    
    private static let systemUserAgent = HTTPHeaders.default.value(for: "User-Agent") ?? ""

    private static var customUserAgent: String {
        if let prefix = userAgentPrefix {
            return "\(prefix) \(systemUserAgent)"
        }
        return systemUserAgent
    }
    
    static func getAsset(_ assetID: String, _ accessToken: String?, completion: @escaping (Asset?, Error?) -> Void) {
        let url = URL(string: String(format: VIDEO_DETAIL_API, TPStreamsSDK.orgCode!, assetID, accessToken ?? ""))!
        
        var headers: HTTPHeaders = (TPStreamsSDK.authToken?.isEmpty == false) ? ["Authorization": "JWT \(TPStreamsSDK.authToken!)"] : [:]
        headers.update(name: "User-Agent", value: Self.customUserAgent)
        
        AF.request(url, headers: headers)
            .responseData { response in
                switch response.result {
                case .success(let data):
                    handleResponse(response, data, completion)
                case .failure(let error):
                    handleNetworkFailure(error, completion)
                }
            }
    }
    
    static func getDRMLicense(_ assetID: String, _ accessToken: String?, _ spcData: Data, _ contentID: String, _ forOfflinePlayback: Bool, _ licenseDurationSeconds: Double? = nil, _ completion:@escaping(Data?, Error?) -> Void) -> Void {
        var components = URLComponents(string: String(format: DRM_LICENSE_API, TPStreamsSDK.orgCode!, assetID, accessToken ?? "", (forOfflinePlayback == true ? "true" : "false")))!

        if forOfflinePlayback {
            if let licenseDuration = licenseDurationSeconds, licenseDuration > 0 {
                var queryItems = components.queryItems ?? []
                queryItems.append(URLQueryItem(name: "license_duration_seconds", value: String(Int(licenseDuration))))
                queryItems.append(URLQueryItem(name: "rental_duration_seconds", value: String(Int(licenseDuration))))
                components.queryItems = queryItems
            }
        }
        let url = components.url!
        let parameters = [
            "spc": spcData.base64EncodedString(),
            "assetId" : contentID
        ] as [String : String]
        
        var headers: HTTPHeaders = [
            .contentType("application/json")
        ]
        
        // Add Authorization header if authToken is available and non-empty
        if let authToken = TPStreamsSDK.authToken, !authToken.isEmpty {
            headers["Authorization"] = "JWT \(authToken)"
        }
        
        headers.update(name: "User-Agent", value: Self.customUserAgent)       
        AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.prettyPrinted, headers: headers).responseData { response in
            switch response.result {
            case .success(let data):
                if response.response?.statusCode == 200 {
                    completion(data, nil)
                } else if response.response?.statusCode == 401 {
                    completion(nil, TPStreamPlayerError.unauthorizedAccess)
                } else {
                    completion(nil, TPStreamPlayerError.failedToFetchLicenseKey)
                }
            case .failure(_):
                completion(nil, TPStreamPlayerError.failedToFetchLicenseKey)
            }
            
        }
    }

    static func fetchAnalyticsPresignedURL(
        _ orgID: String,
        _ assetID: String,
        _ visitorID: String,
        _ sessionID: String,
        _ accessToken: String?,
        _ userAgent: String,
        completion: @escaping (TPStreamsAnalyticsPresignedResponse?) -> Void
    ) {
        guard TPStreamsSDK.provider == .tpstreams,
              var components = URLComponents(string: String(format: ANALYTICS_PRESIGNED_URL_API, orgID, assetID)) else {
            completion(nil)
            return
        }

        var queryItems = [
            URLQueryItem(name: "visitorId", value: visitorID),
            URLQueryItem(name: "sessionId", value: sessionID)
        ]
        if let accessToken = accessToken, !accessToken.isEmpty {
            queryItems.append(URLQueryItem(name: "access_token", value: accessToken))
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data()
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        if let authToken = TPStreamsSDK.authToken, !authToken.isEmpty {
            request.setValue("JWT \(authToken)", forHTTPHeaderField: "Authorization")
        }

        AF.request(request).responseData { response in
            guard let statusCode = response.response?.statusCode,
                  (200..<300).contains(statusCode),
                  let data = response.data else {
                completion(nil)
                return
            }
            completion(StreamsAPIParser.parseAnalyticsPresignedResponse(data: data))
        }
    }

    static func uploadAnalytics(
        _ putURL: URL,
        _ assetID: String,
        _ orgID: String,
        _ visitorID: String,
        _ sessionID: String,
        _ durationSeconds: Int,
        _ userAgent: String,
        _ ipAddress: String?,
        _ location: String?,
        completion: @escaping (Bool, Int?) -> Void
    ) {
        guard TPStreamsSDK.provider == .tpstreams else {
            completion(false, nil)
            return
        }

        let payload: [String: Any] = [
            "assetId": assetID,
            "organization": orgID,
            "visitor_id": visitorID,
            "session_id": sessionID,
            "duration": durationSeconds,
            "user_agent": userAgent,
            "time_stamp": ISO8601DateFormatter().string(from: Date()),
            "ip_address": ipAddress ?? "",
            "location": location ?? ""
        ]

        AF.request(
            putURL,
            method: .put,
            parameters: payload,
            encoding: JSONEncoding.default,
            headers: [.contentType("application/json")]
        ).response { response in
            let statusCode = response.response?.statusCode
            completion(statusCode.map { (200..<300).contains($0) } ?? false, statusCode)
        }
    }
    
    static func handleResponse(_ response: AFDataResponse<Data>, _ data: Data, _ completion: @escaping (Asset?, Error?) -> Void) {
        guard let statusCode = response.response?.statusCode else {
            completion(nil, TPStreamPlayerError.unknownError)
            return
        }
        
        switch statusCode {
        case 200:
            do {
                let videoDetails = try parser.parseAsset(data: data)
                completion(videoDetails, nil)
            } catch {
                completion(nil, TPStreamPlayerError.unknownError)
            }
        case 404:
            completion(nil, TPStreamPlayerError.resourceNotFound)
        case 401:
            completion(nil, TPStreamPlayerError.unauthorizedAccess)
        case 500:
            completion(nil, TPStreamPlayerError.serverError)
        default:
            completion(nil, TPStreamPlayerError.unknownError)
        }
    }
    
    static func handleNetworkFailure(_ error: AFError, _ completion: @escaping (Asset?, Error?) -> Void) {
        if let underlyingError = error.underlyingError as? URLError {
            switch underlyingError.code {
            case .timedOut:
                completion(nil, TPStreamPlayerError.networkTimeout)
            case .notConnectedToInternet:
                completion(nil, TPStreamPlayerError.noInternetConnection)
            default:
                completion(nil, TPStreamPlayerError.unknownError)
            }
        } else {
            completion(nil, error)
        }
    }
}
