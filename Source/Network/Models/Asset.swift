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
        if let video = video {
            if let liveStream = liveStream, video.status.lowercased() == "completed" && liveStream.transcodeRecordedVideo == false, liveStream.isStreaming {
                return liveStream.hlsUrl
            }
            if video.status.lowercased() != "completed",
               let liveStream = liveStream {
                return liveStream.hlsUrl
            }
            return video.playbackURL
        } else if let liveStream = liveStream {
            return liveStream.hlsUrl
        } else {
            return nil
        }
    }

    /// Returns the canonical identifier for encryption keys.
    var keyIdentifier: String {
        return id
    }

    var isDrmEncrypted: Bool {
        return video?.drmEncrypted == true || liveStream?.enableDRM == true
    }
}
