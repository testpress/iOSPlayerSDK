//
//  ResourceLoaderDelegate.swift
//  TPStreamsSDK
//
//  Created by Testpress on 19/10/23.
//

import Foundation
import AVFoundation

class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    let accessToken: String?
    private let assetId: String?
    private let isPlaybackOffline: Bool
    private let offlineAssetId: String?
    internal var asset: Asset? = nil
    
    private let encryptionKeyDelegate = EncryptionKeyDelegate.shared
    
    init(accessToken: String?, assetId: String? = nil, isPlaybackOffline: Bool = false, offlineAssetId: String? = nil, localOfflineAsset: LocalOfflineAsset? = nil) {
        self.accessToken = accessToken
        self.assetId = assetId
        self.isPlaybackOffline = isPlaybackOffline
        self.offlineAssetId = offlineAssetId
        super.init()
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = loadingRequest.request.url else { return false }
        
        guard let asset = asset, asset.video?.isAESEncrypted == true else {
            return false
        }

        if url.scheme == "tpkey" {
            handleLocalKeyRequest(loadingRequest)
            return true
        } else if url.scheme == "https" && isEncryptionKeyUrl(url) {
            if isPlaybackOffline {
                handleLocalKeyRequest(loadingRequest)
            } else {
                handleOnlineKeyRequest(loadingRequest)
            }
            return true
        }
        
        return false
    }
    
    // MARK: - Key Request Handling
    
    private func handleLocalKeyRequest(_ loadingRequest: AVAssetResourceLoadingRequest) {
        guard let url = loadingRequest.request.url else { return }
        
        let id: String = (url.scheme == "tpkey" ? url.host : url.pathComponents.last(where: { component in
            !["aes_key", "encryption_key", "api", "v1", "v2.5", "/"].contains(component)
        })) ?? ""
        
        let fallbacks = ([id, assetId, offlineAssetId].compactMap { $0 }).filter { !$0.isEmpty }
        for key in fallbacks {
            if let data = encryptionKeyDelegate.get(for: key) {
                setEncryptionKeyResponse(for: loadingRequest, data: data)
                return
            }
        }
        
        debugPrint("Key not found for \(id). Tried: \(fallbacks)")
        loadingRequest.finishLoading()
    }
    
    private func handleOnlineKeyRequest(_ loadingRequest: AVAssetResourceLoadingRequest) {
        guard let url = loadingRequest.request.url else { return }
        
        var requestURL = url
        if TPStreamsSDK.provider == .testpress, let org = TPStreamsSDK.orgCode, var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            components.host = "\(org).testpress.in"
            requestURL = components.url ?? url
        }
        
        encryptionKeyDelegate.fetchKey(url: requestURL, accessToken: accessToken) { [weak self] data in
            if let data = data {
                self?.setEncryptionKeyResponse(for: loadingRequest, data: data)
            } else {
                loadingRequest.finishLoading()
            }
        }
    }
    
    private func setEncryptionKeyResponse(for loadingRequest: AVAssetResourceLoadingRequest, data: Data) {
        if let info = loadingRequest.contentInformationRequest {
            info.contentType = "application/octet-stream"
            info.isByteRangeAccessSupported = true
            info.contentLength = Int64(data.count)
        }
        loadingRequest.dataRequest?.respond(with: data)
        loadingRequest.finishLoading()
    }
    
    private func isEncryptionKeyUrl(_ url: URL) -> Bool {
        let path = url.path.lowercased()
        return path.contains("/aes_key") || path.contains("/encryption_key")
    }
}
