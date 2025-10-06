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
    @Persisted var thumbnailURL: String? = nil
    @Persisted var percentageCompleted: Double = 0.0
    @Persisted var resolution: String = ""
    @Persisted var duration: Double = 0.0
    @Persisted var bitRate: Double = 0.0
    @Persisted var size: Double = 0.0
    @Persisted var folderTree: String = ""
    @Persisted var drmContentId: String? = nil
    @Persisted var metadataMap = Map<String, AnyRealmValue>()
    @Persisted var licenseExpiryDate: Date? = nil
    
    static var manager = ObjectManager<LocalOfflineAsset>()
    
    var metadata: [String: Any]? {
        get {
            if metadataMap.count == 0 { return nil }
            return Dictionary(uniqueKeysWithValues: metadataMap.map { ($0.key, $0.value.toAny) })
        }
        set {
            metadataMap.removeAll()
            newValue?.forEach { key, value in
                metadataMap[key] = AnyRealmValue(fromAny: value)
            }
        }
    }
}

extension LocalOfflineAsset {
    
    static func create(
        assetId: String,
        srcURL: String,
        title: String,
        resolution: String,
        duration:Double,
        bitRate: Double,
        thumbnailURL: String? = nil,
        folderTree: String,
        drmContentId: String? = nil,
        metadata: [String: Any]? = nil
    ) -> LocalOfflineAsset {
        let localOfflineAsset = LocalOfflineAsset()
        localOfflineAsset.assetId = assetId
        localOfflineAsset.srcURL = srcURL
        localOfflineAsset.title = title
        localOfflineAsset.resolution = resolution
        localOfflineAsset.duration = duration
        localOfflineAsset.bitRate = bitRate
        localOfflineAsset.size = (bitRate * duration)
        localOfflineAsset.thumbnailURL = thumbnailURL
        localOfflineAsset.folderTree = folderTree
        localOfflineAsset.drmContentId = drmContentId
        localOfflineAsset.metadata = metadata
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
            thumbnailURL: self.thumbnailURL,
            folderTree: self.folderTree,
            metadata: self.metadata
        )
    }
    
    func asAsset() -> Asset {
        guard let downloadedFileURL = downloadedFileURL else {
            fatalError("downloadedFileURL is nil")
        }

        let isDrmEncrypted = drmContentId != nil && !drmContentId!.isEmpty
        let playbackURLString = downloadedFileURL.absoluteString

        let video = Video(
            playbackURL: playbackURLString,
            status: self.status,
            drmEncrypted: isDrmEncrypted,
            duration: self.duration,
            thumbnailURL: self.thumbnailURL
        )

        let asset: Asset = Asset(
            id: self.assetId,
            title: self.title,
            contentType: "video",
            video: video,
            liveStream: nil,
            folderTree: self.folderTree,
            drmContentId: self.drmContentId
        )

        return asset
    }

    var downloadedFileURL: URL? {
        if !self.downloadedPath.isEmpty{
            let baseURL = URL(fileURLWithPath: NSHomeDirectory())
            return baseURL.appendingPathComponent(self.downloadedPath)
        }
        return nil
    }
}
