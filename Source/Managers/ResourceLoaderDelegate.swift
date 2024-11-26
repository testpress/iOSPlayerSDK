//
//  ResourceLoaderDelegate.swift
//  TPStreamsSDK
//
//  Created by Testpress on 19/10/23.
//

import Foundation
import AVFoundation

class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    let accessToken: String
    
    init(accessToken: String) {
        self.accessToken = accessToken
        super.init()
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url else { return false }
        
        if isEncryptionKeyUrl(url), let modifiedURL = appendAccessToken(url) {
            fetchEncryptionKey(from: modifiedURL) { [weak self] data in
                self?.setEncryptionKeyResponse(for: loadingRequest, data: data)
            }
            return true
        }
        return false
    }
    
    func isEncryptionKeyUrl(_ url: URL) -> Bool {
        return url.path.contains("key")
    }
    
    func appendAccessToken(_ url: URL) -> URL? {
        if var components = URLComponents(url: url, resolvingAgainstBaseURL: true){
            let accessTokenQueryItem = URLQueryItem(name: "access_token", value: self.accessToken)
            components.queryItems = (components.queryItems ?? []) + [accessTokenQueryItem]
            return components.url
        }
        
        return url
    }
    
    func fetchEncryptionKey(from url: URL, completion: @escaping (Data) -> Void) {
        var request = URLRequest(url: url)
        
        // Add Authorization header if authToken is available and non-empty
        if let authToken = TPStreamsSDK.authToken, !authToken.isEmpty {
            request.addValue("JWT \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        let dataTask = URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data {
                completion(data)
            }
        }
        dataTask.resume()
    }
    
    func setEncryptionKeyResponse(for loadingRequest: AVAssetResourceLoadingRequest, data: Data) {
        if let contentInformationRequest = loadingRequest.contentInformationRequest {
            contentInformationRequest.contentType = getContentType(contentInformationRequest: contentInformationRequest)
            contentInformationRequest.isByteRangeAccessSupported = true
            contentInformationRequest.contentLength = Int64(data.count)
        }
        
        loadingRequest.dataRequest?.respond(with: data)
        loadingRequest.finishLoading()
    }
    
    func getContentType(contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) -> String {
        var contentType = AVStreamingKeyDeliveryPersistentContentKeyType
        
        if #available(iOS 11.2, *) {
            if let allowedContentType = contentInformationRequest?.allowedContentTypes?.first {
                if allowedContentType == AVStreamingKeyDeliveryContentKeyType {
                    contentType = AVStreamingKeyDeliveryContentKeyType
                }
            }
        }
        
        return contentType
    }
}
