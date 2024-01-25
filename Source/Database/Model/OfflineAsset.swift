//
//  OfflineAsset.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 08/01/24.
//

import Foundation
import RealmSwift

public class OfflineAsset: Object {
    @Persisted(primaryKey: true) public var assetId: String = ""
    @Persisted public var createdAt = Date()
    @Persisted var srcURL: String = ""
    @Persisted public var title: String = ""
    @Persisted public var downloadedPath: String = ""
    @Persisted public var downloadedAt = Date()
    @Persisted public var status:String = Status.notStarted.rawValue
    @Persisted public var percentageCompleted: Double = 0.0
    @Persisted public var resolution: String = ""
    @Persisted public var duration: Double = 0.0
    @Persisted public var bitRate: Double = 0.0
    @Persisted public var size: Double = 0.0
    
    public static var manager = ObjectManager<OfflineAsset>()
}

extension OfflineAsset {
    static func create(
        assetId: String,
        srcURL: String,
        title: String,
        resolution: String,
        duration:Double,
        bitRate: Double
    ) -> OfflineAsset {
        let offlineAsset = OfflineAsset()
        offlineAsset.assetId = assetId
        offlineAsset.srcURL = srcURL
        offlineAsset.title = title
        offlineAsset.resolution = resolution
        offlineAsset.duration = duration
        offlineAsset.bitRate = bitRate
        offlineAsset.size = (bitRate * duration)
        return offlineAsset
    }
    
    public var downloadedFileURL: URL? {
        if !self.downloadedPath.isEmpty{
            let baseURL = URL(fileURLWithPath: NSHomeDirectory())
            return baseURL.appendingPathComponent(self.downloadedPath)
        }
        return nil
    }
}

public enum Status: String {
    case notStarted = "notStarted"
    case inProgress = "inProgress"
    case paused = "paused"
    case finished = "finished"
    case failed = "failed"
}
