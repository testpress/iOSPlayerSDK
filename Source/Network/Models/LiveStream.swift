//
//  LiveStream.swift
//  TPStreamsSDK
//
//  Created by Testpress on 13/06/24.
//

import Foundation

struct LiveStream{
    let status: String
    let hlsUrl: String
    let transcodeRecordedVideo: Bool
    let chatEmbedUrl: String
    let noticeMessage: String?
    
    var isStreaming: Bool {
        return status == "Streaming" || status == "Running"
    }
}
