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
            
            private enum CodingKeys: String, CodingKey {
                case playbackURL = "playback_url"
                case status
            }
        }
    }
    
    static func getPlaybackURL(accessToken: String, completion:@escaping(Asset?, Error?) -> Void) {
        let orgCode = "6eafqn"
        let assetId = "AeDsCzqB5Td"
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
}
