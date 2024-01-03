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
    
    private override init() {
        super.init()
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
        
        let offlineAsset = try! OfflineAsset.manager.create(["id": asset.id, "srcURL": asset.video.playbackURL,"title": asset.title])
        activeDownloadsMap[task] = offlineAsset
        task.resume()
    }
    
    public func getDownloadedAsset(srcURL: String) -> OfflineAsset? {
        let predicate = NSPredicate(format: "srcURL == %@ AND status == %@", srcURL, "Finished")
        return OfflineAsset.manager.filter(predicate: predicate).first
    }
    
}

extension TPStreamsDownloadManager: AVAssetDownloadDelegate {
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        guard let offlineAsset = activeDownloadsMap[assetDownloadTask] else { return }
        
        try! offlineAsset.update(["downloadedPath": location.relativePath])
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard error != nil else {
            guard let assetDownloadTask = task as? AVAssetDownloadTask,
                  let offlineAsset = activeDownloadsMap[assetDownloadTask] else { return }
            
            try! offlineAsset.update(["status": Status.finished.rawValue])
            activeDownloadsMap.removeValue(forKey: assetDownloadTask)
            print(offlineAsset)
            return
        }
    }
    
    public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        guard let offlineAsset = activeDownloadsMap[assetDownloadTask] else { return }
        
        var percentageComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange = value.timeRangeValue
            percentageComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        
        print("hihihi",(percentageComplete * 100))
        
        try! offlineAsset.update(["status": Status.inProgress.rawValue, "percentageCompleted": percentageComplete * 100])
    }
}
