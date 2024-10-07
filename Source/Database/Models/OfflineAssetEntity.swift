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
