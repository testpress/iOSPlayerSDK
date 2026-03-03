//
//  VideoDetail.swift
//  TPStreamsSDK
//
//  Created by Testpress on 03/06/23.
//

import Foundation

public struct Asset {
    public let id: String
    public let title: String
    public let contentType: String
    public let video: Video?
    public let liveStream: LiveStream?
    public let folderTree: String?
    public let drmContentId: String?
    
    public var playbackURL: String? {
        if let video = video {
            return video.playbackURL
        } else if let liveStream = liveStream {
            return liveStream.hlsUrl
        } else {
            return nil
        }
    }
}

public struct VideoQuality: Equatable {
    public let resolution: String
    public let bitrate: Double
    
    public init(resolution: String, bitrate: Double) {
        self.resolution = resolution
        self.bitrate = bitrate
    }
}
