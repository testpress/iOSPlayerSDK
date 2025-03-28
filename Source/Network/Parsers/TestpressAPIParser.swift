//
//  TestpressAPIParser.swift
//  TPStreamsSDK
//
//  Created by Testpress on 13/06/24.
//

import Foundation

class TestpressAPIParser: APIParser {
    func parseAsset(data: Data) throws -> Asset {
        guard let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = responseDict["id"] as? String,
              let title = responseDict["title"] as? String,
              let contentType = responseDict["content_type"] as? String else {
            throw NSError(domain: "InvalidResponseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing required fields in response"])
        }
        
        let video = parseVideo(from: responseDict["video"] as? [String: Any])
        let liveStream = parseLiveStream(from: responseDict["live_stream"] as? [String: Any])
        let folderTree = responseDict["folder_tree"] as? String
        let drmContentId = responseDict["drm_content_id"] as? String
        
        return Asset(id: id, title: title, contentType: contentType, video: video, liveStream: liveStream, folderTree: folderTree, drmContentId: drmContentId)
    }

    func parseVideo(from dictionary: [String: Any]?) -> Video? {
        guard let videoDict = dictionary,
              let playbackURL = videoDict["hls_url"] as? String ?? videoDict["url"] as? String,
              let status = videoDict["transcoding_status"] as? String,
              let drmEncrypted = videoDict["drm_enabled"] as? Bool else {
            return nil
        }
        let duration: Double = videoDict["duration"] as? Double ?? 0.0
        
        return Video(playbackURL: playbackURL, status: status, drmEncrypted: drmEncrypted, duration: duration)
    }

    func parseLiveStream(from dictionary: [String: Any]?) -> LiveStream? {
        guard let liveStreamDict = dictionary,
              let status = liveStreamDict["status"] as? String,
              let hlsUrl = liveStreamDict["stream_url"] as? String,
              let chatEmbedUrl = liveStreamDict["chat_embed_url"] as? String else {
            return nil
        }
        
        let noticeMessage = liveStreamDict["notice_message"] as? String
        let transcodeRecordedVideo = liveStreamDict["show_recorded_video"] as? Bool ?? false
        
        return LiveStream(status: status, hlsUrl: hlsUrl, transcodeRecordedVideo: transcodeRecordedVideo, chatEmbedUrl: chatEmbedUrl, noticeMessage: noticeMessage)
    }
}
