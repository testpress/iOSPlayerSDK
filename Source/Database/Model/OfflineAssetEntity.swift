//
//  OfflineAsset.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 08/01/24.
//

import Foundation
import RealmSwift

class OfflineAssetEntity: Object {
    @Persisted(primaryKey: true) var assetId: String = ""
    @Persisted var createdAt = Date()
    @Persisted var srcURL: String = ""
    @Persisted var title: String = ""
    @Persisted var downloadedPath: String = ""
    @Persisted var downloadedAt = Date()
    @Persisted var status:String = Status.notStarted.rawValue
    @Persisted var percentageCompleted: Double = 0.0
    @Persisted var resolution: String = ""
    @Persisted var duration: Double = 0.0
    @Persisted var bitRate: Double = 0.0
    @Persisted var size: Double = 0.0
    
    static var manager = ObjectManager<OfflineAssetEntity>()
}

extension OfflineAssetEntity {
    static func create(
        assetId: String,
        srcURL: String,
        title: String,
        resolution: String,
        duration:Double,
        bitRate: Double
    ) -> OfflineAssetEntity {
        let offlineAssetEntity = OfflineAssetEntity()
        offlineAssetEntity.assetId = assetId
        offlineAssetEntity.srcURL = srcURL
        offlineAssetEntity.title = title
        offlineAssetEntity.resolution = resolution
        offlineAssetEntity.duration = duration
        offlineAssetEntity.bitRate = bitRate
        offlineAssetEntity.size = (bitRate * duration)
        return offlineAssetEntity
    }
    
    var downloadedFileURL: URL? {
        if !self.downloadedPath.isEmpty{
            let baseURL = URL(fileURLWithPath: NSHomeDirectory())
            return baseURL.appendingPathComponent(self.downloadedPath)
        }
        return nil
    }
    
    func asOfflineAsset() -> OfflineAsset {
        return OfflineAsset(
            assetId: self.assetId,
            createdAt: self.createdAt,
            title: self.title,
            downloadedAt: self.downloadedAt,
            status: self.status,
            percentageCompleted: self.percentageCompleted,
            resolution: self.resolution,
            duration: self.duration,
            bitRate: self.bitRate,
            size: self.size
        )
    }
}

public enum Status: String {
    case notStarted = "notStarted"
    case inProgress = "inProgress"
    case paused = "paused"
    case finished = "finished"
    case failed = "failed"
}
