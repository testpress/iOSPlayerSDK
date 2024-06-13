//
//  VideoDetail.swift
//  TPStreamsSDK
//
//  Created by Testpress on 03/06/23.
//

import Foundation

struct Asset {
    let id: String
    let title: String
    let contentType: String
    let video: Video?
    let liveStream: LiveStream?
    
    var playbackURL: String? {
        if let video = video {
            return video.playbackURL
        } else if let liveStream = liveStream {
            return liveStream.hlsUrl
        } else {
            return nil
        }
    }
}
