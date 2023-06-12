import Foundation
import AVKit

extension AVPlayer {
    var currentTimeInSeconds: Float64 {
        return CMTimeGetSeconds(currentTime())
    }
    
    var durationInSeconds: Float64 {
        return CMTimeGetSeconds(currentItem?.duration ?? CMTime.zero)
    }
    
    func bufferedDuration() -> Double {
        if let range = currentItem?.loadedTimeRanges.first {
            let endTime = CMTimeRangeGetEnd(range.timeRangeValue)
            let durationInSeconds = CMTimeGetSeconds(endTime)
            return durationInSeconds
        }
        
        return 0.0
    }
}
