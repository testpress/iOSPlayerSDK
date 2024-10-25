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
    class var parser: APIParser {
        fatalError("parser must be implemented by subclasses.")
    }
    
    static func getAsset(_ assetID: String, _ accessToken: String, completion: @escaping (Asset?, Error?) -> Void) {
        let url = URL(string: String(format: VIDEO_DETAIL_API, TPStreamsSDK.orgCode!, assetID, accessToken))!
        
        print(url)
        
        let headers: HTTPHeaders = (TPStreamsSDK.authToken?.isEmpty == false) ? ["Authorization": "JWT \(TPStreamsSDK.authToken!)"] : [:]
        
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
    
    static func getDRMLicense(_ assetID: String, _ accessToken: String, _ spcData: Data, _ contentID: String, _ completion:@escaping(Data?, Error?) -> Void) -> Void {
        let url = URL(string: String(format: DRM_LICENSE_API, TPStreamsSDK.orgCode!, assetID, accessToken))!
        
        print(url)
        
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
        
        AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.prettyPrinted, headers: headers).responseData { response in
            switch response.result {
            case .success(let data):
                if response.response?.statusCode == 200 {
                    completion(data, nil)
                } else {
                    completion(nil, TPStreamPlayerError.failedToFetchLicenseKey)
                }
            case .failure(_):
                completion(nil, TPStreamPlayerError.failedToFetchLicenseKey)
            }
            
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
