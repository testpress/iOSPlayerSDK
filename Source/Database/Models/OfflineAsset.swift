//
//  OfflineAsset.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 04/10/24.
//

import Foundation

public struct OfflineAsset: Hashable {
    public var assetId: String = ""
    public var createdAt = Date()
    public var title: String = ""
    public var srcURL: String = ""
    public var downloadedAt = Date()
    public var status:String = Status.notStarted.rawValue
    public var thumbnailURL: String? = nil
    public var percentageCompleted: Double = 0.0
    public var resolution: String = ""
    public var duration: Double = 0.0
    public var bitRate: Double = 0.0
    public var size: Double = 0.0
    public var folderTree: String = ""
}


public enum Status: String {
    case notStarted = "notStarted"
    case inProgress = "inProgress"
    case paused = "paused"
    case finished = "finished"
    case failed = "failed"
    case deleted = "deleted"
}
