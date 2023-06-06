import Foundation
import CoreMedia

class TPStreamPlayer: NSObject, ObservableObject {
    @Published var status: PlayerStatus = .paused
    @Published var currentTime: Float64?

    var player: TPAVPlayer!
    var videoDuration: Float64 {
        player.durationInSeconds
    }
    var currentPlaybackSpeed = PlaybackSpeed(rawValue: 1)!
    
    init(player: TPAVPlayer){
        self.player = player
        super.init()
        self.observePlayerStatusChange()
    }
    
    private func observePlayerStatusChange(){
        player.addObserver(self, forKeyPath: #keyPath(TPAVPlayer.timeControlStatus), options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        
        switch keyPath {
        case #keyPath(TPAVPlayer.timeControlStatus):
            if let player = object as? TPAVPlayer {
                handlePlayerStatusChange(for: player)
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
        player?.seek(to: seekTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
    
    func changePlaybackSpeed(_ speed: PlaybackSpeed){
        currentPlaybackSpeed = speed
        player.rate = speed.rawValue
    }
}

enum PlayerStatus {
    case playing
    case paused
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
