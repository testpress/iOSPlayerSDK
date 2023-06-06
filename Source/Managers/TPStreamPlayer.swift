import Foundation
import CoreMedia

class TPStreamPlayer: NSObject, ObservableObject {
    @Published var status: PlayerStatus = .paused
    @Published var currentTime: Float64?

    var player: TPAVPlayer!
    var videoDuration: Float64 {
        player.durationInSeconds
    }
    
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
}

enum PlayerStatus {
    case playing
    case paused
}
