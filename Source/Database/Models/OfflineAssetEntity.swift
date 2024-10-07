//
//  OfflineAssetEntity.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 04/10/24.
//

import Foundation
import RealmSwift

class LocalOfflineAsset: Object {
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
    @Persisted var folderTree: String = ""
    
    static var manager = ObjectManager<LocalOfflineAsset>()
}

extension LocalOfflineAsset {
    
    static func create(
        assetId: String,
        srcURL: String,
        title: String,
        resolution: String,
        duration:Double,
        bitRate: Double,
        folderTree: String
    ) -> LocalOfflineAsset {
        let localOfflineAsset = LocalOfflineAsset()
        localOfflineAsset.assetId = assetId
        localOfflineAsset.srcURL = srcURL
        localOfflineAsset.title = title
        localOfflineAsset.resolution = resolution
        localOfflineAsset.duration = duration
        localOfflineAsset.bitRate = bitRate
        localOfflineAsset.size = (bitRate * duration)
        localOfflineAsset.folderTree = folderTree
        return localOfflineAsset
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
            size: self.size,
            folderTree: self.folderTree
        )
    }
}