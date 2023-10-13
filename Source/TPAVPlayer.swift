//
//  TPAVPlayer.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 31/05/23.
//

import Foundation
import AVKit
import Sentry

#if CocoaPods
    import M3U8Kit
#else
    import M3U8Parser
#endif

public class TPAVPlayer: AVPlayer {
    private var accessToken: String
    private var assetID: String
    
    public var availableVideoQualities: [VideoQuality] = [VideoQuality(resolution:"Auto", bitrate: 0)]
    
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
        fetchAsset()
    }
    
    private func fetchAsset() {
        TPStreamsSDK.provider.API.getAsset(assetID, accessToken) { [weak self] asset, error in
            guard let self = self else { return }
            
            if let asset = asset {
                self.setup(withAsset: asset)
            } else if let error = error{
                SentrySDK.capture(error: error)
                debugPrint(error.localizedDescription)
            }
        }
    }
    
    private func setup(withAsset asset: Asset) {
        guard let url = URL(string: asset.video.playbackURL) else {
            debugPrint("Invalid playback URL received from API: \(asset.video.playbackURL)")
            return
        }
        
        let avURLAsset = AVURLAsset(url: url)
        self.setPlaybackURL(avURLAsset)
        self.setupDRM(avURLAsset)
        self.populateAvailableVideoQualities(url)
    }
    
    private func setPlaybackURL(_ asset: AVURLAsset){
        let playerItem = AVPlayerItem(asset: asset)
        self.replaceCurrentItem(with: playerItem)
    }
    
    private func setupDRM(_ avURLAsset: AVURLAsset) {
        ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(avURLAsset)
        ContentKeyManager.shared.contentKeyDelegate.setAssetDetails(assetID, accessToken)
    }
    
    private func populateAvailableVideoQualities(_ url: URL){
        guard let streamList = getStreamListFromMasterPlaylist(url) else {
            return
        }
        
        
        for i in 0 ..< streamList.count {
            if let extXStreamInf = streamList.xStreamInf(at: i){
                let resolution = "\(Int(extXStreamInf.resolution.height))p"
                availableVideoQualities.append(VideoQuality(resolution: resolution, bitrate: Double(extXStreamInf.bandwidth)))
            }
        }
    }
    
    private func getStreamListFromMasterPlaylist(_ url: URL) -> M3U8ExtXStreamInfList?{
        guard let playlistModel = try? M3U8PlaylistModel(url: url),
              let masterPlaylist = playlistModel.masterPlaylist,
              let streamList = masterPlaylist.xStreamList else {
            return nil
        }
        
        streamList.sortByBandwidth(inOrder: .orderedAscending)
        return streamList
    }
    
    public func changeVideoQuality(to videoQuality: VideoQuality) {
        guard availableVideoQualities.contains(where: { $0.resolution == videoQuality.resolution && $0.bitrate == videoQuality.bitrate }) else {
            return
        }
        
        self.currentItem?.preferredPeakBitRate = videoQuality.bitrate
    }
}

public struct VideoQuality {
    public var resolution: String
    public var bitrate: Double
}
