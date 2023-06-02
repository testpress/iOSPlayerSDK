//
//  TPAVPlayer.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 31/05/23.
//

import Foundation
import AVKit


public class TPAVPlayer: AVPlayer {
    private var accessToken: String
    private var assetID: String
    
    public init(assetID: String, accessToken: String) {
        guard TPStreamsSDK.orgCode != nil else {
            fatalError("You must call TPStreamsSDK.initialize")
        }
        
        if accessToken.isEmpty || assetID.isEmpty {
            fatalError("AccessToken/AssetID cannot be empty")
        }
        self.accessToken = accessToken
        self.assetID = assetID

        super.init()
        
        loadAsset()
    }
    
    private func loadAsset() {
        API.getAsset(assetID, accessToken) { [weak self] asset, error in
            guard let self = self else { return }
            self.handleAPIResponse(asset: asset, error: error)
        }
    }
    
    private func handleAPIResponse(asset: API.Asset?, error: Error?) {
        if let asset = asset {
            guard let url = URL(string: asset.video.playbackURL) else {
                debugPrint("Got invalid playback URL from API")
                return
            }
            
            let avURLAsset = AVURLAsset(url: url)
            self.prepareAssetForDRMPlayback(avURLAsset)
            let playerItem = AVPlayerItem(asset: avURLAsset)
            self.replaceCurrentItem(with: playerItem)
        } else if let error = error {
            debugPrint(error.localizedDescription)
        }
    }
    
    private func prepareAssetForDRMPlayback(_ avURLAsset: AVURLAsset) {
        ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(avURLAsset)
        ContentKeyManager.shared.contentKeyDelegate.setAssetDetails(assetID, accessToken)
    }
}
