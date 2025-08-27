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
    internal var metadata: String? = nil
    
    public var availableVideoQualities: [VideoQuality] = [VideoQuality(resolution:"Auto", bitrate: 0)]
    
    public init(assetID: String, accessToken: String? = nil, metadata: String? = nil, completion: SetupCompletion? = nil) {
        guard TPStreamsSDK.orgCode != nil else {
            fatalError("You must call TPStreamsSDK.initialize")
        }
        
        if assetID.isEmpty {
            fatalError("AssetID cannot be empty")
        }
        
        if (TPStreamsSDK.authToken?.isEmpty ?? true) && (accessToken?.isEmpty ?? true) {
            fatalError("AccessToken cannot be nil or empty")
        }
        self.accessToken = accessToken
        self.assetID = assetID
        self.setupCompletion = completion
        self.resourceLoaderDelegate = ResourceLoaderDelegate(accessToken: accessToken)
        self.metadata = metadata
        
        super.init()
        fetchAsset()
        isPlaybackOffline = false
    }
    
    public init(offlineAssetId: String, metadata: String? = nil, completion: SetupCompletion? = nil) {
        self.setupCompletion = completion
        super.init()
        isPlaybackOffline = true
        guard let localOfflineAsset = LocalOfflineAsset.manager.get(id: offlineAssetId) else { return }
        if (localOfflineAsset.status == "finished") {
            self.asset = localOfflineAsset.asAsset()
            self.metadata = metadata ?? localOfflineAsset.metadataJSON
            self.initializePlayer()
            self.setupCompletion?(nil)
            self.initializationStatus = "ready"
        } else {
            self.processInitializationFailure(TPStreamPlayerError.incompleteOfflineVideo)
        }
    }
    
    private func fetchAsset() {
        TPStreamsSDK.provider.API.getAsset(assetID!, accessToken) { [weak self] asset, error in
            guard let self = self else { return }
            
            if let error = error {
                self.processInitializationFailure(error)
                return
            }

            #if targetEnvironment(simulator)
            if asset?.video?.drmEncrypted == true {
                self.processInitializationFailure(TPStreamPlayerError.drmSimulatorError)
                return
            }
            #endif
            
            guard let asset = asset else { return }
            self.initializePlayerWithFetchedAsset(asset)
        }
    }
    
    private func processInitializationFailure(_ error: Error) {
        setupCompletion?(error)
        var sentryIssueId: String? = nil
        if (error as? TPStreamPlayerError)?.shouldLogToSentry ?? true {
            sentryIssueId = captureErrorInSentry(error, assetID, accessToken)
        }
        initializationErrorContext = InitializationErrorContext(error: error, sentryIssueId: sentryIssueId)
        onError?(error, sentryIssueId)
        initializationStatus = "error"
        
        if isNetworkUnavailableError(error) {
            retryFetchAssetWhenNetworkIsReady()
        }
    }
    
    private func initializePlayerWithFetchedAsset(_ asset: Asset) {
        self.asset = asset
        initializePlayer()
        setupCompletion?(nil)
        initializationStatus = "ready"
    }
    
    private func initializePlayer() {
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
    
    private func populateAvailableVideoQualities(_ url: URL) {
        fetchStreamList(from: url) { [weak self] streamList in
            guard let self = self, let streamList = streamList else {
                print("Failed to load stream list from: \(url)")
                return
            }
            
            for i in 0 ..< streamList.count {
                if let extXStreamInf = streamList.xStreamInf(at: i){
                    let resolution = "\(Int(extXStreamInf.resolution.height))p"
                    availableVideoQualities.append(VideoQuality(resolution: resolution, bitrate: Double(extXStreamInf.bandwidth)))
                }
            }
        }
    }

    private func fetchStreamList(from url: URL, completion: @escaping (M3U8ExtXStreamInfList?) -> Void) {
        DispatchQueue.global(qos: .utility).async {
        do {
            let playlistModel = try M3U8PlaylistModel(url: url)
            let streamList = playlistModel.masterPlaylist?.xStreamList
            streamList?.sortByBandwidth(inOrder: .orderedAscending)

            DispatchQueue.main.async {
                completion(streamList)
            }
         } catch {
            print("Error loading playlist: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(nil)
                }
            }
        }
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
