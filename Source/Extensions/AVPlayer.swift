import Foundation
import AVKit

extension AVPlayer {
    var currentTimeInSeconds: Float64 {
        return CMTimeGetSeconds(currentTime())
    }
    
    var durationInSeconds: Float64 {
        return CMTimeGetSeconds(currentItem?.duration ?? CMTime.zero)
    }
}
