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
    let enableDRM: Bool
    let presence: Presence?

    init(status: String, hlsUrl: String, transcodeRecordedVideo: Bool, chatEmbedUrl: String, noticeMessage: String?, enableDRM: Bool, presence: Presence? = nil) {
        self.status = status
        self.hlsUrl = hlsUrl
        self.transcodeRecordedVideo = transcodeRecordedVideo
        self.chatEmbedUrl = chatEmbedUrl
        self.noticeMessage = noticeMessage
        self.enableDRM = enableDRM
        self.presence = presence
    }

    var isStreaming: Bool {
        return status == "Streaming" || status == "Running"
    }
}

// Nothing downstream needs the hashed vid the server also mints alongside
// this — only the raw device id (PresenceViewerIdStore) that produced it,
// which the app already has, matters for resending on heartbeat/leave.
struct Presence {
    let token: String
    let baseUrl: String
}
