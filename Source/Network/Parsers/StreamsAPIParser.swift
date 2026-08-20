//
//  StreamsAPIParser.swift
//  TPStreamsSDK
//
//  Created by Testpress on 13/06/24.
//

import Foundation

class StreamsAPIParser: APIParser {
    func parseAsset(data: Data) throws -> Asset {
        guard let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = responseDict["id"] as? String,
              let title = responseDict["title"] as? String,
              let contentType = responseDict["type"] as? String else {
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
              let playbackURL = videoDict["playback_url"] as? String,
              let status = videoDict["status"] as? String else {
            return nil
        }
        
        let id: String? = videoDict["id"] as? String
        let duration: Double = videoDict["duration"] as? Double ?? 0.0
        let thumbnailURL: String? = videoDict["cover_thumbnail_url"] as? String
        let contentProtectionType: ContentProtectionType? = {
            let type = ContentProtectionType.fromString(videoDict["content_protection_type"] as? String)
            // If the backend specifically sends DRM, or if we want to force priority
            return type
        }()
        
        let isDrm = contentProtectionType == .drm
        let tracks = parseTracks(from: videoDict["tracks"] as? [[String: Any]])
        
        return Video(id: id, playbackURL: playbackURL, status: status, drmEncrypted: isDrm, duration: duration, thumbnailURL: thumbnailURL, contentProtectionType: contentProtectionType, tracks: tracks)
    }

    func parseLiveStream(from dictionary: [String: Any]?) -> LiveStream? {
        guard let liveStreamDict = dictionary,
              let status = liveStreamDict["status"] as? String,
              let hlsUrl = liveStreamDict["hls_url"] as? String,
              let transcodeRecordedVideo = liveStreamDict["transcode_recorded_video"] as? Bool,
              let chatEmbedUrl = liveStreamDict["chat_embed_url"] as? String else {
            return nil
        }
        let noticeMessage = liveStreamDict["notice_message"] as? String
        let enableDRM = liveStreamDict["enable_drm"] as? Bool ?? false
        let presence = parsePresence(from: liveStreamDict["presence"] as? [String: Any])

        return LiveStream(status: status, hlsUrl: hlsUrl, transcodeRecordedVideo: transcodeRecordedVideo, chatEmbedUrl: chatEmbedUrl, noticeMessage: noticeMessage, enableDRM: enableDRM, presence: presence)
    }

    // A malformed or absent presence payload is treated as no presence at
    // all, rather than propagating a half-populated config further — presence
    // is a bolt-on feature that must never be able to break asset parsing.
    func parsePresence(from dictionary: [String: Any]?) -> Presence? {
        guard let presenceDict = dictionary,
              let token = presenceDict["token"] as? String,
              let baseUrl = presenceDict["base_url"] as? String,
              !token.isEmpty, !baseUrl.isEmpty else {
            return nil
        }
        return Presence(token: token, baseUrl: baseUrl)
    }
}
