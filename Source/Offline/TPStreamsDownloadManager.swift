//
//  TPStreamsDownloadManager.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 03/01/24.
//

import Foundation
import AVFoundation


public final class TPStreamsDownloadManager: NSObject {
    
    static public let shared = TPStreamsDownloadManager()
    private var assetDownloadURLSession: AVAssetDownloadURLSession!
    private var activeDownloadsMap = [AVAssetDownloadTask: OfflineAsset]()
    internal var tpStreamsDatabase: TPStreamsDatabase?
    
    private override init() {
        super.init()
        tpStreamsDatabase = TPStreamsDatabase()
        tpStreamsDatabase?.initialize()
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "com.tpstreams.downloadSession")
        assetDownloadURLSession = AVAssetDownloadURLSession(
            configuration: backgroundConfiguration,
            assetDownloadDelegate: self,
            delegateQueue: OperationQueue.main
        )
    }
    
    internal func startDownload(asset: Asset, bitRate: Int) {
        let avUrlAsset = AVURLAsset(url: URL(string: asset.video.playbackURL)!)
        
        guard let task = assetDownloadURLSession.makeAssetDownloadTask(
            asset: avUrlAsset,
            assetTitle: asset.title,
            assetArtworkData: nil,
            options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: bitRate]
        ) else {
            return
        }
        
        let offlineAsset = OfflineAsset(id: asset.id, title: asset.title, srcURL: asset.video.playbackURL)
        tpStreamsDatabase?.insert(offlineAsset)
        activeDownloadsMap[task] = offlineAsset
        task.resume()
    }
    
}

extension TPStreamsDownloadManager: AVAssetDownloadDelegate {
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        guard var offlineAsset = activeDownloadsMap[assetDownloadTask] else { return }
        offlineAsset.updateDownloadPath(downloadedPath: location.relativePath)
        activeDownloadsMap[assetDownloadTask] = offlineAsset
        tpStreamsDatabase?.update(offlineAsset)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard error != nil else {
            guard let assetDownloadTask = task as? AVAssetDownloadTask,
                  var offlineAsset = activeDownloadsMap[assetDownloadTask] else { return }
            offlineAsset.updateStatus(status: Status.finished.rawValue)
            tpStreamsDatabase?.update(offlineAsset)
            activeDownloadsMap.removeValue(forKey: assetDownloadTask)
            return
        }
    }
    
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        guard var offlineAsset = activeDownloadsMap[assetDownloadTask] else { return }
        var percentageComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange = value.timeRangeValue
            percentageComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        offlineAsset.updatePercentageCompleted(percentageCompleted: percentageComplete * 100)
        activeDownloadsMap[assetDownloadTask] = offlineAsset
        tpStreamsDatabase?.update(offlineAsset)
    }
}
