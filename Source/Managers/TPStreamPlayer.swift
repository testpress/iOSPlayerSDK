import Foundation
import CoreMedia
import AVKit

class TPStreamPlayer: NSObject {
    @objc dynamic var status = "paused"
    @objc dynamic var currentTime: NSNumber = 0
    @objc dynamic var isVideoDurationInitialized = false
    
    private static let rateComparisonTolerance: Float = 0.01
    
    var player: TPAVPlayer!
    var isLive: Bool {
        guard let liveStream = player.asset?.liveStream else {
            return false
        }
        return liveStream.isStreaming
    }
    var playableDuration: Float64 {
        guard let currentItem = player?.currentItem else {
            return CMTimeGetSeconds(CMTime.zero)
        }
        
        if isLive {
            return currentItem.seekableTimeRanges.last?.timeRangeValue.end.seconds ?? CMTimeGetSeconds(CMTime.zero)
        } else {
            return player.durationInSeconds
        }
    }
    var bufferedDuration: Float64 {
        player.bufferedDuration()
    }
    var currentPlaybackSpeed = PlaybackSpeed(rawValue: 1)!
    private var playerCurrentTimeObserver: Any!
    private var currentItemChangeObservation: NSKeyValueObservation!
    private var playerRateObservation: NSKeyValueObservation?
    
    private var isSeeking: Bool = false

    private let assetData: TpstreamsAssetData = TpstreamsAssetData()
    private var hasRestoredLastWatchedPosition = false
    private var didClearLastWatchedPosition = false
    private var lastWatchedPositionSyncTimer: Timer?
    private let userId: String?

    /// `true` when the SDK can synchronize and restore the user's last watched position.
    /// The resume state is synced using the provided `userId` and the asset ID,
    /// allowing playback to continue from the last watched position whenever the
    /// user plays the asset again. Requires a non-empty `userId`, an asset ID, and a non-live stream.
    private var isAutoResumeEnabled: Bool {
        guard let userId = userId, !userId.isEmpty else { return false }
        return player.assetID != nil && TPStreamsSDK.orgCode != nil && !isLive
    }
    
    var availableVideoQualities: [VideoQuality] {
        return self.player.availableVideoQualities
    }
    var currentVideoQuality: VideoQuality? {
        return self.player.availableVideoQualities.first( where: {$0.bitrate == self.player.currentItem?.preferredPeakBitRate })
    }
    
    var asset: Asset? {
        return self.player.asset
    }
    
    init(player: TPAVPlayer, userId: String? = nil) {
        self.player = player
        self.userId = userId
        super.init()
        self.observePlaybackStatusChange()
        self.observePlayerCurrentTimeChange()
        self.observeCurrentItemChanges()
        self.observePlayerStatusChange()
        self.observePlayerRateChange()
    }
    
    deinit {
        updateLastWatchedPosition()
        stopLastWatchedPositionSync()
    }
    
    private func observeCurrentItemChanges() {
        // For offline videos, `currentItem` is immediately available, so we check if `currentItem` is not nil
        // and update the player state accordingly.
        if player.currentItem != nil {
            self.observePlayerBufferingStatusChange()
            self.observeVideoEnd()
            return
        }
        
        // For online videos, the `currentItem` is set asynchronously in `TPAVPlayer` after the asset is fetched over the network.
        // We add observers to `currentItem` once it has been set.
        currentItemChangeObservation = player.observe(\.currentItem, options: [.new]) { [weak self] (_, _) in
            guard let self = self else { return }
            self.observePlayerBufferingStatusChange()
            self.observeVideoEnd()
        }
    }
    
    private func observePlaybackStatusChange(){
        player.addObserver(self, forKeyPath: #keyPath(TPAVPlayer.timeControlStatus), options: .new, context: nil)
    }
    
    private func observePlayerStatusChange(){
        player.addObserver(self, forKeyPath: #keyPath(TPAVPlayer.status), options: .new, context: nil)
    }
    
    private func observePlayerCurrentTimeChange() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        playerCurrentTimeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] progressTime in
            guard let self = self else { return }
            
            // Prevent updating the currentTime during seeking to avoid a minor glitch in the progress bar
            // where the thumb moves back to the previous position from the dragged position for a fraction of a second.
            if !self.isSeeking {
                self.currentTime = NSNumber(value: CMTimeGetSeconds(progressTime))
            }
        }
    }

    private func observePlayerRateChange() {
        playerRateObservation = player.observe(\.rate, options: [.new]) { [weak self] (player, _) in
            guard let self = self else { return }
            let newRate = Float(player.rate)
            if let matchingSpeed = PlaybackSpeed.allCases.first(where: { abs($0.rawValue - newRate) < Self.rateComparisonTolerance }),
               self.currentPlaybackSpeed != matchingSpeed {
                self.currentPlaybackSpeed = matchingSpeed
                self.updateObservedPlaybackSpeed(matchingSpeed)
            }
        }
    }

    func updateObservedPlaybackSpeed(_ speed: PlaybackSpeed) {
        // Empty implementation - will be overridden in TPStreamPlayerObservable
    }
    
    
    private func observePlayerBufferingStatusChange(){
        self.player.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: .new, context: nil)
        self.player.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: .new, context: nil)
        self.player.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration), options: .new, context: nil)
    }
    
    private func observeVideoEnd(){
        NotificationCenter.default.addObserver(self, selector:#selector(self.playerDidFinishPlaying),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        
        switch keyPath {
        case #keyPath(TPAVPlayer.timeControlStatus):
            if let player = object as? TPAVPlayer {
                handlePlaybackStatusChange(for: player)
            }
        case #keyPath(TPAVPlayer.status):
            if let player = object as? TPAVPlayer {
                handlePlayerStatusChange(for: player)
            }
        case #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), #keyPath(AVPlayerItem.isPlaybackBufferEmpty):
            if let playerItem = object as? AVPlayerItem {
                handleBufferStatusChange(of: playerItem, keyPath: keyPath)
            }
        case #keyPath(AVPlayerItem.duration):
            isVideoDurationInitialized = true
        default:
            break
        }
    }
    
    @objc private func playerDidFinishPlaying(){
        status = "ended"
        deleteLastWatchedPosition()
    }
    
    private func handlePlaybackStatusChange(for player: TPAVPlayer) {
        switch player.timeControlStatus {
        case .playing:
            status = "playing"
        case .paused:
            if status == "ended" {return}
            status = "paused"
            updateLastWatchedPosition()
        case .waitingToPlayAtSpecifiedRate:
            break
        @unknown default:
            break
        }
    }
    
    private func handleBufferStatusChange(of playerItem: AVPlayerItem, keyPath: String) {
        switch keyPath {
        case #keyPath(AVPlayerItem.isPlaybackBufferEmpty):
            if playerItem.isPlaybackBufferEmpty {
                status = "buffering"
            }
        case #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp):
            if playerItem.isPlaybackLikelyToKeepUp {
                status = self.player.timeControlStatus == .playing ? "playing" : "paused"
            }
        default:
            break
        }
    }
    
    private func handlePlayerStatusChange(for player: TPAVPlayer) {
        switch player.status {
        case .readyToPlay:
            status = "ready"
            restoreLastWatchedPosition()
        case .failed:
            status = "failed"
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    private func restoreLastWatchedPosition() {
        guard isAutoResumeEnabled,
              !hasRestoredLastWatchedPosition,
              let userId = userId,
              let assetID = player.assetID else { return }
        hasRestoredLastWatchedPosition = true
        startLastWatchedPositionSync()
        assetData.fetchLastWatchedPosition(userId: userId, assetID: assetID) { [weak self] seconds in
            guard let self = self, let seconds = seconds, seconds > 0 else { return }
            DispatchQueue.main.async {
                self.player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600),
                                 toleranceBefore: CMTime.zero,
                                 toleranceAfter: CMTime.zero) { _ in
                    self.currentTime = NSNumber(value: seconds)
                }
            }
        }
    }

    private func updateLastWatchedPosition() {
        guard isAutoResumeEnabled,
              !didClearLastWatchedPosition,
              player.currentItem?.status != .failed else { return }
        let seconds = Int(round(player.currentTimeInSeconds))
        guard seconds > 0,
              let userId = userId,
              let assetID = player.assetID else { return }
        assetData.updateLastWatchedPosition(Double(seconds), userId: userId, assetID: assetID)
    }

    private func deleteLastWatchedPosition() {
        guard isAutoResumeEnabled,
              let userId = userId,
              let assetID = player.assetID else { return }
        didClearLastWatchedPosition = true
        stopLastWatchedPositionSync()
        assetData.deleteLastWatchedPosition(userId: userId, assetID: assetID)
    }

    private func startLastWatchedPositionSync() {
        guard isAutoResumeEnabled else { return }
        lastWatchedPositionSyncTimer?.invalidate()
        let timer = Timer(timeInterval: 120, repeats: true) { [weak self] _ in
            guard let self = self, self.player.timeControlStatus == .playing else { return }
            self.updateLastWatchedPosition()
        }
        RunLoop.main.add(timer, forMode: .common)
        lastWatchedPositionSyncTimer = timer
    }

    private func stopLastWatchedPositionSync() {
        lastWatchedPositionSyncTimer?.invalidate()
        lastWatchedPositionSyncTimer = nil
    }
    
    func play(){
        // When resuming playback, AVPlayer resets the rate to 1.0. We need to capture the current speed 
        // before calling play() and restore it after.
        let previousPlaybackSpeed = currentPlaybackSpeed
        player.play()
        player.rate = previousPlaybackSpeed.rawValue
        didClearLastWatchedPosition = false
        startLastWatchedPositionSync()
    }
    
    func pause(){
        player.pause()
    }
    
    func replay() {
        goTo(seconds: 0.0)
        play()
    }
    func forward(_ seconds: Float64 = 10.0) {
        var seekTo = self.player.currentTimeInSeconds + seconds
        if seekTo > playableDuration {
            seekTo = playableDuration
        }
        goTo(seconds: seekTo)
    }
    
    func rewind(_ seconds: Float64 = 10.0) {
        var seekTo = self.player.currentTimeInSeconds - seconds
        if seekTo < 0 {
            seekTo = 0
        }
        goTo(seconds: seekTo)
    }
    
    func goTo(seconds: Float64) {
        // Here we are validation the second if value is NaN wee will return there is no network second will be NaN
        guard !seconds.isNaN else {
            print("Invalid seconds value: NaN")
            return
        }
        currentTime = NSNumber(value: seconds)
        let seekTime = CMTime(value: Int64(seconds), timescale: 1)
        isSeeking = true
        player?.seek(to: seekTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero){ [weak self] _ in
            guard let self = self else { return }
            self.isSeeking = false
            self.updateLastWatchedPosition()
        }
    }
    
    func changePlaybackSpeed(_ speed: PlaybackSpeed){
        currentPlaybackSpeed = speed
        player.rate = speed.rawValue
        self.updateObservedPlaybackSpeed(speed)
    }
    
    func changeVideoQuality(_ videoQuality: VideoQuality){
        self.player.changeVideoQuality(to: videoQuality)
    }
    
    var isBehindLiveEdge: Bool {
        guard let currentItem = player.currentItem else {
            return false
        }
        
        if isLive {
            let liveTolerance: Float64 = 15.0
            let isPaused = status == "paused"
            let isBehindLiveThreshold = playableDuration - Double(currentTime) > liveTolerance
            
            return isPaused || isBehindLiveThreshold
        } else {
            return false
        }
    }
}


@available(iOS 13.0, *)
class TPStreamPlayerObservable: TPStreamPlayer, ObservableObject {
    @Published var observedStatus: String = "paused"
    @Published var observedCurrentTime: Float64?
    @Published var observedCurrentPlaybackSpeed: PlaybackSpeed = PlaybackSpeed(rawValue: 1)!
    
    override var status: String {
        didSet {
            observedStatus = status
        }
    }
    
    override var currentTime: NSNumber {
        didSet {
            observedCurrentTime = currentTime.doubleValue
        }
    }

    override func updateObservedPlaybackSpeed(_ speed: PlaybackSpeed) {
        observedCurrentPlaybackSpeed = speed
    }
    
    
    override init(player: TPAVPlayer, userId: String? = nil) {
        observedStatus = "paused"
        observedCurrentTime = nil
        observedCurrentPlaybackSpeed = PlaybackSpeed(rawValue: 1)!
        super.init(player: player, userId: userId)
    }
}
