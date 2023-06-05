import Foundation

class TPStreamPlayer: NSObject, ObservableObject {
    @Published var status: PlayerStatus = .paused
    
    var player: TPAVPlayer!
    
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
    
    public func togglePlay(){
        if status == .paused {
            player.play()
        } else {
            player.pause()
        }
    }
}

enum PlayerStatus {
    case playing
    case paused
}
