//
//  LiveStream.swift
//  TPStreamsSDK
//
//  Created by Testpress on 13/06/24.
//

import Foundation

public struct LiveStream {
    public let status: String
    public let hlsUrl: String
    public let transcodeRecordedVideo: Bool
    public let chatEmbedUrl: String
    public let noticeMessage: String?
    
    public var isStreaming: Bool {
        return status == "Streaming" || status == "Running"
    }
}
