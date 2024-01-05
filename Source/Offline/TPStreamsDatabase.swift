//
//  TPStreamsDatabase.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 04/01/24.
//

import Foundation
import SQLite

internal class TPStreamsDatabase {
    
    private var offlineAssetDatabasePath: String?
    private var offlineAssetDatabase: Connection?
    private var offlineAssetTable: Table?
    
    // Columns in Table
    private let id = Expression<String>("id")
    private let created_at = Expression<Date>("created_at")
    private let title = Expression<String>("title")
    private let srcURL = Expression<String>("srcURL")
    private let downloadedPath = Expression<String>("downloadedPath")
    private let downloadedAt = Expression<Date>("downloadedAt")
    private let status = Expression<String>("status")
    private let percentageCompleted = Expression<Double>("percentageCompleted")
    
    func initialize() {
        do {
            offlineAssetDatabasePath = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            ).first!

            // Create Database
            offlineAssetDatabase = try Connection("\(offlineAssetDatabasePath!)/db.sqlite3")
            
            // Initialize Table
            offlineAssetTable = Table("OfflineAsset")

            // Create Table
            try offlineAssetDatabase!.run(offlineAssetTable!.create { offlineAsset in
                offlineAsset.column(id, primaryKey: true)
                offlineAsset.column(created_at)
                offlineAsset.column(title)
                offlineAsset.column(srcURL, unique: true)
                offlineAsset.column(downloadedPath, unique: true)
                offlineAsset.column(downloadedAt)
                offlineAsset.column(status)
                offlineAsset.column(percentageCompleted)
            })
        } catch {
            print (error)
        }
    }
    
    func insert( _ offlineAssets: OfflineAsset) {
        do {
            try offlineAssetDatabase!.run(
                offlineAssetTable!.insert(
                    id <- offlineAssets.id,
                    created_at <- offlineAssets.created_at,
                    title <- offlineAssets.title,
                    srcURL <- offlineAssets.srcURL,
                    downloadedPath <- offlineAssets.downloadedPath,
                    downloadedAt <- offlineAssets.downloadedAt,
                    status <- offlineAssets.status,
                    percentageCompleted <- offlineAssets.percentageCompleted
                )
            )
        } catch {
            print("insertion failed: \(error)")
        }
    }
    
    func update( _ offlineAssets: OfflineAsset) {
        let tempOfflineAsset = offlineAssetTable!.filter(id == offlineAssets.id)
        do {
            try offlineAssetDatabase!.run(
                tempOfflineAsset.update(
                    downloadedPath <- offlineAssets.downloadedPath,
                    downloadedAt <- offlineAssets.downloadedAt,
                    status <- offlineAssets.status,
                    percentageCompleted <- offlineAssets.percentageCompleted
                )
            )
        } catch {
            print("updation failed: \(error)")
        }
    }
    
    func get(id: String) -> OfflineAsset? {
        do {
            let query = offlineAssetTable!.filter(self.id == id)
            if let offlineAsset = try offlineAssetDatabase!.pluck(query) {
                let result = OfflineAsset(
                    id: offlineAsset[self.id],
                    created_at: offlineAsset[self.created_at],
                    title: offlineAsset[self.title],
                    srcURL: offlineAsset[self.srcURL],
                    downloadedPath: offlineAsset[self.downloadedPath],
                    downloadedAt: offlineAsset[self.downloadedAt],
                    status: offlineAsset[self.status],
                    percentageCompleted: offlineAsset[self.percentageCompleted]
                )
                return result
            }
        } catch {
            print("Error fetching offline asset with id \(id): \(error)")
        }
        return nil
    }
    
    func get(srcURL: String) -> OfflineAsset? {
        do {
            let query = offlineAssetTable!.filter(self.srcURL == srcURL)
            if let offlineAsset = try offlineAssetDatabase!.pluck(query) {
                let result = OfflineAsset(
                    id: offlineAsset[self.id],
                    created_at: offlineAsset[self.created_at],
                    title: offlineAsset[self.title],
                    srcURL: offlineAsset[self.srcURL],
                    downloadedPath: offlineAsset[self.downloadedPath],
                    downloadedAt: offlineAsset[self.downloadedAt],
                    status: offlineAsset[self.status],
                    percentageCompleted: offlineAsset[self.percentageCompleted]
                )
                return result
            }
        } catch {
            print("Error fetching offline asset with srcURL \(id): \(error)")
        }
        return nil
    }
    
    func delete(id: String) {
        do {
            let tempOfflineAsset = offlineAssetTable!.filter(self.id == id)
            try offlineAssetDatabase!.run(tempOfflineAsset.delete())
        } catch {
            print("deletion failed: \(error)")
        }
    }
    
    
}
