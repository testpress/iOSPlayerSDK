//
//  Client.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 31/05/23.
//

import Foundation
import Alamofire

class API {
    struct Asset: Codable {
        let id: String
        let title: String
        let video: Video
        
        struct Video: Codable {
            let playbackURL: String
            let status: String
            let isProtected: Bool
            
            private enum CodingKeys: String, CodingKey {
                case playbackURL = "playback_url"
                case status
                case isProtected = "enable_drm"
            }
        }
    }
    
    static func getAsset(_ assetID: String, _ accessToken: String, completion:@escaping(Asset?, Error?) -> Void) {
        let url = URL(string: String(format: "https://app.tpstreams.com/api/v1/%@/assets/%@/?access_token=%@", TPStreamsSDK.orgCode!, assetID, accessToken))!

        AF.request(url).responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    let videoDetails = try JSONDecoder().decode(Asset.self, from: data)
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
        
        let parameters = [
            "spc": spcData.base64EncodedString(),
            "assetId" : contentID
        ] as [String : String]
        
        let url = URL(string: String(format:"https://app.tpstreams.com/api/v1/\(TPStreamsSDK.orgCode!)/assets/\(assetID)/drm_license/?access_token=\(accessToken)&drm_type=fairplay"))!
        let headers: HTTPHeaders = [
            .contentType("application/json")
        ]
        AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.prettyPrinted, headers: headers).responseData { response in
            alamoFireOnComplete(response, completion)
        }
    }
    
    static func alamoFireOnComplete(_ response: AFDataResponse<Data>, _ completion:@escaping(Data?, Error?) -> Void) -> Void {
        switch response.result {
        case .success(let data):
            completion(data, nil)
        case .failure(let error):
            completion(nil, error)
        }
    }
}
