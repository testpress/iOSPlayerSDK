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

public typealias SetupCompletion = (Error?) -> Void
public struct InitializationErrorContext {
    var error: Error
    var sentryIssueId: String?
}

public class TPAVPlayer: AVPlayer {
    internal var accessToken: String?
    internal var assetID: String?
    private var setupCompletion: SetupCompletion?
    private var resourceLoaderDelegate: ResourceLoaderDelegate?
    public var onError: ((Error, String?) -> Void)?
    @objc internal dynamic var initializationStatus = "pending"
    internal var initializationErrorContext: InitializationErrorContext?
    internal var asset: Asset? = nil
    private var reachability: Reachability?
    internal var isPlaybackOffline: Bool = false
    
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
        isPlaybackOffline = false
    }
    
    public init(offlineAssetId: String, completion: SetupCompletion? = nil) {
        self.setupCompletion = completion
        super.init()
        isPlaybackOffline = true
        guard let localOfflineAsset = LocalOfflineAsset.manager.get(id: offlineAssetId) else { return }
        if (localOfflineAsset.status == "finished") {
            self.asset = localOfflineAsset.asAsset()
            self.setup()
            self.setupCompletion?(nil)
            self.initializationStatus = "ready"
        } else {
            self.setupCompletion?(TPStreamPlayerError.incompleteOfflineVideo)
            self.onError?(TPStreamPlayerError.incompleteOfflineVideo, nil)
            self.initializationErrorContext = InitializationErrorContext(error: TPStreamPlayerError.incompleteOfflineVideo, sentryIssueId: nil)
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
                let sentryIssueId = captureErrorInSentry(error, self.assetID, self.accessToken)
                self.initializationErrorContext = InitializationErrorContext(error: error, sentryIssueId: sentryIssueId)
                self.onError?(error, sentryIssueId)
                self.initializationStatus = "error"
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
        ContentKeyManager.shared.contentKeyDelegate.setAssetDetails(assetID, accessToken, isPlaybackOffline)
        ContentKeyManager.shared.contentKeyDelegate.onError = { error in
            let sentryIssueId = captureErrorInSentry(error, self.assetID, self.accessToken)
            self.initializationErrorContext = InitializationErrorContext(error: error, sentryIssueId: sentryIssueId)
            self.onError?(error, sentryIssueId)
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
