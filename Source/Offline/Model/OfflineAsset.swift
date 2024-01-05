//
//  OfflineAsset.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 03/01/24.
//

import Foundation

public struct OfflineAsset {
    var id: String
    var created_at = Date()
    var title: String = ""
    var srcURL: String = ""
    var downloadedPath: String = ""
    var downloadedAt = Date()
    var status:String = Status.notStarted.rawValue
    var percentageCompleted: Double = 0.0
}

enum Status: String {
    case notStarted = "notStarted"
    case inProgress = "inProgress"
    case paused = "paused"
    case finished = "finished"
    case failed = "failed"
}

extension OfflineAsset {
    
    mutating func updateDownloadPath(downloadedPath: String) {
        self.downloadedPath = downloadedPath
    }
    
    mutating func updateStatus(status: String) {
        self.status = status
    }
    
    mutating func updatePercentageCompleted(percentageCompleted: Double) {
        self.percentageCompleted = percentageCompleted
    }
    
    mutating func updateDownloadAt(downloadedAt: Date) {
        self.downloadedAt = downloadedAt
    }
    
}
