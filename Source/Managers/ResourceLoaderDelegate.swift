//
//  ResourceLoaderDelegate.swift
//  TPStreamsSDK
//
//  Created by Testpress on 19/10/23.
//

import Foundation
import AVFoundation

class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url else { return false }

        if isEncryptionKeyUrl(url) {
            fetchEncryptionKey(from: url) { [weak self] data in
                self?.setEncryptionKeyResponse(for: loadingRequest, data: data)
            }
            return true
        }
        return false
    }

    func isEncryptionKeyUrl(_ url: URL) -> Bool {
        return url.path.contains("key")
    }

    func fetchEncryptionKey(from url: URL, completion: @escaping (Data) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("\(TPStreamsSDK.provider.API.AUTH_TOKEN_PREFIX) \(TPStreamsSDK.authToken!)", forHTTPHeaderField: "Authorization")
        
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
