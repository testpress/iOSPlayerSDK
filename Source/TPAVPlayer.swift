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
    private var assetID: String
    public typealias SetupCompletion = (Error?) -> Void
    private var setupCompletion: SetupCompletion?
    private var resourceLoaderDelegate: ResourceLoaderDelegate
    public var onError: ((Error) -> Void)?
    internal var initializationError: Error?
    
    public var availableVideoQualities: [VideoQuality] = [VideoQuality(resolution:"Auto", bitrate: 0)]
    
    public init(assetID: String, completion: SetupCompletion? = nil) {
        guard TPStreamsSDK.orgCode != nil else {
            fatalError("You must call TPStreamsSDK.initialize")
        }
        
        if assetID.isEmpty {
            fatalError("AssetID cannot be empty")
        }
        self.assetID = assetID
        self.setupCompletion = completion
        self.resourceLoaderDelegate = ResourceLoaderDelegate()

        super.init()
        fetchAsset()
    }
    
    private func fetchAsset() {
        TPStreamsSDK.provider.API.getAsset(assetID) { [weak self] asset, error in
            guard let self = self else { return }
            
            if let asset = asset {
                self.setup(withAsset: asset)
                self.setupCompletion?(nil)
            } else if let error = error{
                SentrySDK.capture(error: error)
                self.setupCompletion?(error)
                self.onError?(error)
                self.initializationError = error
            }
        }
    }
    
    private func setup(withAsset asset: Asset) {
        guard let url = URL(string: asset.video.playbackURL) else {
            debugPrint("Invalid playback URL received from API: \(asset.video.playbackURL)")
            return
        }
        
        let avURLAsset = AVURLAsset(url: url)
        avURLAsset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
        self.setPlayerItem(avURLAsset)
        self.setupDRM(avURLAsset)
        self.populateAvailableVideoQualities(url)
    }
    
    private func setPlayerItem(_ asset: AVURLAsset){
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 3
        self.replaceCurrentItem(with: playerItem)
    }
    
    private func setupDRM(_ avURLAsset: AVURLAsset) {
        ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(avURLAsset)
        ContentKeyManager.shared.contentKeyDelegate.setAssetDetails(assetID)
        ContentKeyManager.shared.contentKeyDelegate.onError = { error in
            self.initializationError = error
            self.onError?(error)
        }
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
    
    public func limitAvailableVideoQualities(byMaxHeight maxHeight: Int) {
        // Exclude "Auto" resolution because it is handled by AVPlayer and does not adhere to the height limitation.
        self.availableVideoQualities = availableVideoQualities.filter { quality in
            quality.resolution != "Auto" && Int(String(quality.resolution.dropLast()))! <= maxHeight
        }
    }
}

public struct VideoQuality {
    public var resolution: String
    public var bitrate: Double
}
