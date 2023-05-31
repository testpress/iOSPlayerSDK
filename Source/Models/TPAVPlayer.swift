//
//  TPAVPlayer.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 31/05/23.
//

import Foundation
import AVKit


class TPAVPlayer: AVPlayer {
    var accessToken: String?
    
    init(accessToken: String) {
        self.accessToken = accessToken
        super.init()
        API.getPlaybackURL(accessToken: accessToken, completion: self.APIResponse)
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
    
    func APIResponse(asset: API.Asset?, error: Error?) {
        if let asset = asset {
            let url = URL(string: asset.video.playbackURL)
            let playerItem = AVPlayerItem(url: url!)
            self.replaceCurrentItem(with: playerItem)
        } else if let error = error {
            debugPrint(error.localizedDescription)
        }
    }
}
