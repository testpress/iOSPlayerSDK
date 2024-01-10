//
//  OfflineAsset.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 08/01/24.
//

import Foundation
import RealmSwift

public class OfflineAsset: Object {
    @Persisted(primaryKey: true) var assetId: String = ""
    @Persisted var createdAt = Date()
    @Persisted var srcURL: String = ""
    @Persisted var downloadedPath: String = ""
    @Persisted var downloadedAt = Date()
    @Persisted var status:String = Status.notStarted.rawValue
    @Persisted var percentageCompleted: Float = 0.0
    
    public static var manager = ObjectManager<OfflineAsset>()
}

extension OfflineAsset {
    internal func update(_ attributes: [String: Any]) {
        let realm = try! Realm()
        try! realm.write {
            for (key, value) in attributes {
                self[key] = value
            }
        }
    }
}

enum Status: String {
    case notStarted = "notStarted"
    case inProgress = "inProgress"
    case paused = "paused"
    case finished = "finished"
    case failed = "failed"
}
