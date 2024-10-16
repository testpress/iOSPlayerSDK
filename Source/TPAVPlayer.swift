//
//  TPAVPlayer.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 31/05/23.
//

import Foundation
import AVKit
import Sentry
import Reachability

#if CocoaPods
import M3U8Kit
#else
import M3U8Parser
#endif

public class TPAVPlayer: AVPlayer {
    private var accessToken: String?
    private var assetID: String?
    public typealias SetupCompletion = (Error?) -> Void
    private var setupCompletion: SetupCompletion?
    private var resourceLoaderDelegate: ResourceLoaderDelegate?
    public var onError: ((Error) -> Void)?
    @objc internal dynamic var initializationStatus = "pending"
    internal var initializationError: Error?
    internal var asset: Asset? = nil
    private var reachability: Reachability?
    
    public var availableVideoQualities: [VideoQuality] = [VideoQuality(resolution:"Auto", bitrate: 0)]
    
    public init(assetID: String, accessToken: String, completion: SetupCompletion? = nil) {
        guard TPStreamsSDK.orgCode != nil else {
            fatalError("You must call TPStreamsSDK.initialize")
        }
        
        if assetID.isEmpty {
            fatalError("AssetID cannot be empty")
        }
        self.accessToken = accessToken
        self.assetID = assetID
        self.setupCompletion = completion
        self.resourceLoaderDelegate = ResourceLoaderDelegate(accessToken: accessToken)
        
        super.init()
        fetchAsset()
    }
    
    public init(offlineAssetId: String, completion: SetupCompletion? = nil) {
        self.setupCompletion = completion
        super.init()
        guard let localOfflineAsset = LocalOfflineAsset.manager.get(id: offlineAssetId) else { return }
        if (localOfflineAsset.status == "finished") {
            let avURLAsset = AVURLAsset(url: localOfflineAsset.downloadedFileURL!)
            self.setPlayerItem(avURLAsset)
            self.setupCompletion?(nil)
            self.initializationStatus = "ready"
        } else {
            self.setupCompletion?(TPStreamPlayerError.incompleteOfflineVideo)
            self.onError?(TPStreamPlayerError.incompleteOfflineVideo)
            self.initializationError = TPStreamPlayerError.incompleteOfflineVideo
            self.initializationStatus = "error"
        }
    }
    
    private func fetchAsset() {
        TPStreamsSDK.provider.API.getAsset(assetID!, accessToken!) { [weak self] asset, error in
            guard let self = self else { return }
            
            if let asset = asset {
                self.asset = asset
                self.setup()
                self.setupCompletion?(nil)
                self.initializationStatus = "ready"
            } else if let error = error{
                self.setupCompletion?(error)
                self.onError?(error)
                self.initializationError = error
                self.initializationStatus = "error"
                captureErrorInSentry(error, self.assetID, self.accessToken)
                if self.isNetworkUnavailableError(error){
                    self.retryFetchAssetWhenNetworkIsReady()
                }
            }
        }
    }
    
    private func setup() {
        guard let asset = asset, let urlString = asset.playbackURL, let url = URL(string: urlString) else {
            debugPrint("Invalid playback URL received from API: \(asset?.playbackURL ?? "nil")")
            return
        }
        
        let avURLAsset = AVURLAsset(url: url)
        avURLAsset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
        self.setPlayerItem(avURLAsset)
        
        if asset.video?.drmEncrypted == true {
            self.setupDRM(avURLAsset)
        }
        self.populateAvailableVideoQualities(url)
    }
    
    private func isNetworkUnavailableError(_ error: Error) -> Bool {
        return (error as? TPStreamPlayerError) == .noInternetConnection
    }
    
    private func retryFetchAssetWhenNetworkIsReady() {
        do {
            reachability = try Reachability()
            reachability?.whenReachable = { [weak self] _ in
                if self?.asset == nil {
                    self?.fetchAsset()
                }
            }
            try reachability?.startNotifier()
        } catch {
            print("Unable to start reachability notifier")
        }
    }
    
    private func setPlayerItem(_ asset: AVURLAsset){
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 3
        self.replaceCurrentItem(with: playerItem)
    }
    
    private func setupDRM(_ avURLAsset: AVURLAsset) {
        ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(avURLAsset)
        ContentKeyManager.shared.contentKeyDelegate.setAssetDetails(assetID!, accessToken!)
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
    
    deinit {
        reachability?.stopNotifier()
    }
}

public struct VideoQuality {
    public var resolution: String
    public var bitrate: Double
}
