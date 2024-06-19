import Foundation
import CoreMedia
import AVKit

class TPStreamPlayer: NSObject {
    @objc dynamic var status = "paused"
    @objc dynamic var currentTime: NSNumber = 0
    @objc dynamic var isVideoDurationInitialized = false
    
    var player: TPAVPlayer!
    var playableDuration: Float64 {
        guard let currentItem = player?.currentItem else {
            return CMTimeGetSeconds(CMTime.zero)
        }
        
        if let liveStream = player.asset?.liveStream, liveStream.isStreaming {
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
    
    private var isSeeking: Bool = false
    
    var availableVideoQualities: [VideoQuality] {
        return self.player.availableVideoQualities
    }
    var currentVideoQuality: VideoQuality? {
        return self.player.availableVideoQualities.first( where: {$0.bitrate == self.player.currentItem?.preferredPeakBitRate })
    }
    
    init(player: TPAVPlayer){
        self.player = player
        super.init()
        self.observePlayerStatusChange()
        self.observePlayerCurrentTimeChange()
        self.observeCurrentItemChanges()
    }
    
    private func observeCurrentItemChanges(){
        // We're asynchronously setting the `currentItem` in the TPAVPlayer once the asset is fetched via network.
        // So we adding observers on `currentItem` once it has been set.
        
        currentItemChangeObservation = player.observe(\.currentItem, options: [.new]) { [weak self] (_, _) in
            guard let self = self else { return }
            self.observePlayerBufferingStatusChange()
            self.observeVideoEnd()
        }
    }
    
    private func observePlayerStatusChange(){
        player.addObserver(self, forKeyPath: #keyPath(TPAVPlayer.timeControlStatus), options: .new, context: nil)
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
    }
    
    private func handlePlayerStatusChange(for player: TPAVPlayer) {
        switch player.timeControlStatus {
        case .playing:
            status = "playing"
        case .paused:
            if status == "ended" {return}
            status = "paused"
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
    
    func play(){
        player.play()
        
        // When resuming playback, AVPlayer resets the rate to 1.0. We need to set it back to the current playback speed.
        player.rate = currentPlaybackSpeed.rawValue
    }
    
    func pause(){
        player.pause()
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
        }
    }
    
    func changePlaybackSpeed(_ speed: PlaybackSpeed){
        currentPlaybackSpeed = speed
        player.rate = speed.rawValue
    }
    
    func changeVideoQuality(_ videoQuality: VideoQuality){
        self.player.changeVideoQuality(to: videoQuality)
    }
}


@available(iOS 13.0, *)
class TPStreamPlayerObservable: TPStreamPlayer, ObservableObject {
    @Published var observedStatus: String = "paused"
    @Published var observedCurrentTime: Float64?
    
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
    
    override init(player: TPAVPlayer) {
        observedStatus = "paused"
        observedCurrentTime = nil
        super.init(player: player)
    }
}
