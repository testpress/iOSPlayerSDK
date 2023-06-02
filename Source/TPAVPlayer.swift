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
        self.initializePlayerWithAsset()
    }
    
    private func initializePlayerWithAsset() {
        API.getAsset(assetID, accessToken) { [weak self] asset, error in
            guard let self = self else { return }
            
            if let asset = asset {
                self.setupPlayer(withAsset: asset)
            } else if let error = error{
                debugPrint(error.localizedDescription)
            }
        }
    }
    
    private func setupPlayer(withAsset asset: API.Asset) {
        guard let url = URL(string: asset.video.playbackURL) else {
            debugPrint("Invalid playback URL received from API: \(asset.video.playbackURL)")
            return
        }
        
        let avURLAsset = AVURLAsset(url: url)
        self.prepareAssetForDRMPlayback(avURLAsset)
        let playerItem = AVPlayerItem(asset: avURLAsset)
        self.replaceCurrentItem(with: playerItem)
    }
    
    private func prepareAssetForDRMPlayback(_ avURLAsset: AVURLAsset) {
        ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(avURLAsset)
        ContentKeyManager.shared.contentKeyDelegate.setAssetDetails(assetID, accessToken)
    }
}
