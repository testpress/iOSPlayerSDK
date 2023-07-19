import Foundation
import CoreMedia
import AVKit

@available(iOS 13.0, *)
class TPStreamPlayer: NSObject, ObservableObject {
    @Published var status: PlayerStatus = .paused
    @Published var currentTime: Float64?

    var player: TPAVPlayer!
    var videoDuration: Float64 {
        player.durationInSeconds
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
        self.addObservers()
    }
    
    private func addObservers(){
        self.observePlayerStatusChange()
        self.observePlayerCurrentTimeChange()
        self.observePlayerBufferingStatusChange()
    }
    
    private func observePlayerStatusChange(){
        player.addObserver(self, forKeyPath: #keyPath(TPAVPlayer.timeControlStatus), options: .new, context: nil)
    }
    
    private func observePlayerCurrentTimeChange() {
        let interval = CMTime(value: 1, timescale: CMTimeScale(NSEC_PER_SEC))
        playerCurrentTimeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] progressTime in
            guard let self = self else { return }

           // Prevent updating the currentTime during seeking to avoid a minor glitch in the progress bar 
           // where the thumb moves back to the previous position from the dragged position for a fraction of a second.
            if !self.isSeeking {
                self.currentTime = CMTimeGetSeconds(progressTime)
            }
        }
    }
    
    private func observePlayerBufferingStatusChange(){
        // We're asynchronously setting the `currentItem` in the TPAVPlayer once the asset is fetched via network.
        // So we adding observers on `currentItem` once it has been set.
        
        currentItemChangeObservation = player.observe(\.currentItem, options: [.new]) { [weak self] (_, _) in
            guard let self = self else { return }
            self.player.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: .new, context: nil)
            self.player.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: .new, context: nil)
        }
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
        default:
            break
        }
    }
    
    private func handlePlayerStatusChange(for player: TPAVPlayer) {
        switch player.timeControlStatus {
        case .playing:
            status = .playing
        case .paused:
            status = .paused
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
                status = .buffering
            }
        case #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp):
            if playerItem.isPlaybackLikelyToKeepUp {
                status = self.player.timeControlStatus == .playing ? .playing : .paused
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
    
    func forward() {
        var seekTo = self.player.currentTimeInSeconds + 10
        if seekTo > videoDuration {
            seekTo = videoDuration
        }
        goTo(seconds: seekTo)
    }

    func rewind() {
        var seekTo = self.player.currentTimeInSeconds - 10
        if seekTo < 0 {
            seekTo = 0
        }
        goTo(seconds: seekTo)
    }

    func goTo(seconds: Float64) {
        currentTime = seconds
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

enum PlayerStatus {
    case playing
    case paused
    case buffering
}

enum PlaybackSpeed: Float, CaseIterable {
    case verySlow = 0.5
    case slow = 0.75
    case normal = 1
    case fast = 1.25
    case veryFast = 1.5
    case double = 2
    
    var label: String {
        switch self {
        case .verySlow: return "0.5x"
        case .slow: return "0.75x"
        case .normal: return "Normal"
        case .fast: return "1.25x"
        case .veryFast: return "1.5x"
        case .double: return "2x"
        }
    }
}
