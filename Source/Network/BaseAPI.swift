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

    static func getAsset(_ assetID: String, _ accessToken: String, completion: @escaping (Asset?, Error?) -> Void) {
        let url = URL(string: String(format: VIDEO_DETAIL_API, TPStreamsSDK.orgCode!, assetID, accessToken))!

        AF.request(url).responseData { response in

            switch response.result {
            case .success(let data):
                do {
                    let videoDetails = try parseAsset(data: data)
                    completion(videoDetails, nil)
                } catch {
                    completion(nil, error)
                }
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    static func getDRMLicense(_ assetID: String, _ accessToken: String, _ spcData: Data, _ contentID: String, _ completion:@escaping(Data?, Error?) -> Void) -> Void {
        let url = URL(string: String(format: DRM_LICENSE_API, TPStreamsSDK.orgCode!, assetID, accessToken))!
        
        let parameters = [
            "spc": spcData.base64EncodedString(),
            "assetId" : contentID
        ] as [String : String]
        
        let headers: HTTPHeaders = [
            .contentType("application/json")
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.prettyPrinted, headers: headers).responseData { response in
            switch response.result {
            case .success(let data):
                completion(data, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }

    class func parseAsset(data: Data) throws -> Asset {
        fatalError("parseAsset(data:) must be overridden by subclasses.")
    }
}
