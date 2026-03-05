//
//  VideoQualityUtils.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 05/03/26.
//

import Foundation

extension VideoQuality {
    var resolutionHeight: Int? {
        var height: Int = 0
        return Scanner(string: resolution).scanInt(&height) ? height : nil
    }
}

public class VideoQualityUtils {
    public static func findQualityForResolution(
        _ qualities: [VideoQuality],
        resolution: String,
        allowFallback: Bool
    ) -> VideoQuality? {
        if let exactMatch = qualities.first(where: { $0.resolution == resolution }) {
            return exactMatch
        }

        var requestedHeight: Int = 0
        guard allowFallback, Scanner(string: resolution).scanInt(&requestedHeight) else {
            return nil
        }

        return qualities.compactMap { quality -> (quality: VideoQuality, height: Int)? in
            guard let height = quality.resolutionHeight else { return nil }
            return (quality, height)
        }.min { first, second in
            let diff1 = abs(first.height - requestedHeight)
            let diff2 = abs(second.height - requestedHeight)
            
            if diff1 == diff2 {
                return first.height < second.height
            }
            return diff1 < diff2
        }?.quality
    }
}
