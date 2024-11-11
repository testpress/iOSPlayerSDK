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
    let folderTree: String?
    let drmContentId: String?
    
    var playbackURL: String? {
        get {
            if let video = video {
                return video.playbackURL
            } else if let liveStream = liveStream {
                return liveStream.hlsUrl
            } else {
                return nil
            }
        }
        set {
            if let newValue = newValue {
                if var video = video {
                    video.playbackURL = newValue
                }
            }
        }
    }
}
