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
            self.activateAudioSession()
            let playerItem = AVPlayerItem(asset: avURLAsset)
            self.replaceCurrentItem(with: playerItem)
        } else if let error = error {
            debugPrint(error.localizedDescription)
        }
    }
    
    func activateAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
        } catch {
            debugPrint("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }
}
