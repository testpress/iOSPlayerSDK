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
}

struct Video{
    let playbackURL: String
    let status: String
    let drmEncrypted: Bool
}

struct LiveStream{
    let status: String
    let hlsUrl: String
    let transcodeRecordedVideo: Bool
    let chatEmbedUrl: String
    let noticeMessage: String?
}
