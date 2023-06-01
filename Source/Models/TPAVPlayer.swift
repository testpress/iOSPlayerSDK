//
//  TPAVPlayer.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 31/05/23.
//

import Foundation
import AVKit


public class TPAVPlayer: AVPlayer {
    var accessToken: String?
    
    init(accessToken: String) {
        guard TPStreamsSDK.orgCode != nil else {
            fatalError("You must call TPStreamsSDK.initialize")
        }
        
        if (accessToken.isEmpty) {
            fatalError("AccessToken cannot be empty")
        }
        self.accessToken = accessToken
        super.init()
        API.getPlaybackURL(accessToken: accessToken) {[weak self] asset, error in
            guard let self = self else { return }
            self.APIResponse(asset, error)
        }
    }
    
    override init() {
        super.init()
    }
    
    override init(url URL: URL) {
        super.init(url: URL)
    }

    override init(playerItem item: AVPlayerItem?) {
        super.init(playerItem: item)
    }
    
    func APIResponse(_ asset: API.Asset?, _ error: Error?) {
        if let asset = asset {
            let url = URL(string: asset.video.playbackURL)
            let avURLAsset = AVURLAsset(url: url!)
            ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(avURLAsset)
            let playerItem = AVPlayerItem(asset: avURLAsset)
            self.replaceCurrentItem(with: playerItem)
        } else if let error = error {
            debugPrint(error.localizedDescription)
        }
    }
}
