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
    
    static func getPlaybackURL(accessToken: String, completion:@escaping(Asset?, Error?) -> Void) {
        let orgCode = "6eafqn"
        let assetId = "68PAFnYTjSU"
        let url = URL(string: String(format: "https://app.tpstreams.com/api/v1/%@/assets/%@/?access_token=%@", orgCode, assetId, accessToken))!

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
    
    static func getDRMLicense(_ spcData: Data, _ contentID: String, _ completion:@escaping(Data?, Error?) -> Void) -> Void {
        let orgCode = "6eafqn"
        let assetId = "68PAFnYTjSU"
        let accessToken = "5f3ded52-ace8-487e-809c-10de895872d6"
        
        let parameters = [
            "spc": spcData.base64EncodedString(),
            "assetId" : contentID
        ] as [String : Any]
        
        let url = URL(string: String(format:"https://app.tpstreams.com/api/v1/\(orgCode)/assets/\(assetId)/drm_license/?access_token=\(accessToken)&drm_type=fairplay"))!
        AF.request(url, method: .post, parameters: parameters).responseData { response in
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
