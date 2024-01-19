//
//  TPStreamsDownloadManager.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 08/01/24.
//

import Foundation
import AVFoundation


public final class TPStreamsDownloadManager {

    static public let shared = TPStreamsDownloadManager()
    private var assetDownloadURLSession: AVAssetDownloadURLSession!
    private var assetDownloadDelegate: AssetDownloadDelegate!

    private init() {
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "com.tpstreams.downloadSession")
        assetDownloadDelegate = AssetDownloadDelegate()
        assetDownloadURLSession = AVAssetDownloadURLSession(
            configuration: backgroundConfiguration,
            assetDownloadDelegate: assetDownloadDelegate,
            delegateQueue: OperationQueue.main
        )
        
//        assetDownloadURLSession.getAllTasks { tasksArray in
//            print("hihihi0",tasksArray.count)
//            for task in tasksArray {
//                guard let assetDownloadTask = task as? AVAggregateAssetDownloadTask, let assetName = task.taskDescription else { break }
//                print(assetDownloadTask.state.rawValue)
//                print(assetDownloadTask.urlAsset.self)
//                assetDownloadTask.resume()
////                let urlAsset = assetDownloadTask.urlAsset
////                print(urlAsset)
//            }
//        }
        
        //resumeDownload(id: "8eaHZjXt6km")
        
    }

    internal func startDownload(asset: Asset, videoQuality: VideoQuality) {

        if OfflineAsset.manager.exists(id: asset.id) { return }

        let avUrlAsset = AVURLAsset(url: URL(string: asset.video.playbackURL)!)

        guard let task = assetDownloadURLSession.aggregateAssetDownloadTask(
            with: avUrlAsset,
            mediaSelections: [avUrlAsset.preferredMediaSelection],
            assetTitle: asset.title,
            assetArtworkData: nil,
            options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: videoQuality.bitrate]
        ) else { return }

        let offlineAsset = OfflineAsset.create(
            assetId: asset.id,
            srcURL: asset.video.playbackURL,
            title: asset.title,
            resolution:videoQuality.resolution,
            duration: asset.video.duration,
            bitRate: videoQuality.bitrate
        )
        OfflineAsset.manager.add(object: offlineAsset)
        assetDownloadDelegate.activeDownloadsMap[task] = offlineAsset
        task.taskDescription = asset.video.playbackURL
        task.resume()
    }
    
    func resumeDownload(id: String) {
        guard let offlineAsset = OfflineAsset.manager.get(id: id) else { return }

        print(offlineAsset)
        
        if let task = assetDownloadDelegate.activeDownloadsMap.first(where: { $0.value == offlineAsset })?.key {
            if task.state != .running {
                task.resume()
                OfflineAsset.manager.update(object: offlineAsset, with: ["status": Status.inProgress.rawValue])
            }
        }
    }

    func pauseDownload(id: String) {
        guard let offlineAsset = OfflineAsset.manager.get(id: id) else { return }
        if let task = assetDownloadDelegate.activeDownloadsMap.first(where: { $0.value == offlineAsset })?.key {
            task.suspend()
            OfflineAsset.manager.update(object: offlineAsset, with: ["status": Status.paused.rawValue])
        }
    }


}

internal class AssetDownloadDelegate: NSObject, AVAssetDownloadDelegate {

    var activeDownloadsMap = [AVAggregateAssetDownloadTask: OfflineAsset]()

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            print("hihihi1",error)
        if (error != nil) {
            guard let assetDownloadTask = task as? AVAggregateAssetDownloadTask else { return }
            guard let offlineAsset = activeDownloadsMap[assetDownloadTask] else { return }
            updateDownloadCompleteStatus(error, offlineAsset)
            activeDownloadsMap.removeValue(forKey: assetDownloadTask)
        }
        }

        func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, didCompleteFor mediaSelection: AVMediaSelection) {
            print("hihihi2")
        }

        func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
            print("hihihi3")
            guard let offlineAsset = activeDownloadsMap[aggregateAssetDownloadTask] else { return }
            OfflineAsset.manager.update(object: offlineAsset, with: ["downloadedPath": String(location.absoluteString)])
        }

        func urlSession(_ session: URLSession,
                        aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                        didLoad timeRange: CMTimeRange,
                        totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                        timeRangeExpectedToLoad: CMTimeRange,
                        for mediaSelection: AVMediaSelection
        ) {
            print("hihihi4")
            guard let offlineAsset = activeDownloadsMap[aggregateAssetDownloadTask] else { return }

            let percentageComplete = calculateDownloadPercentage(loadedTimeRanges, timeRangeExpectedToLoad)
            print(percentageComplete)
            OfflineAsset.manager.update(object: offlineAsset, with: ["status": Status.inProgress.rawValue, "percentageCompleted": percentageComplete])
        }
    
    
    
    
    private func updateDownloadCompleteStatus(_ error: Error?,_ offlineAsset: OfflineAsset) {
        let status: Status = (error == nil) ? .finished : .failed
        let updateValues: [String: Any] = ["status": status.rawValue, "downloadedAt": Date()]
        OfflineAsset.manager.update(object: offlineAsset, with: updateValues)
    }

    private func calculateDownloadPercentage(_ loadedTimeRanges: [NSValue], _ timeRangeExpectedToLoad: CMTimeRange) -> Double {
        var percentageComplete = 0.0
                for value in loadedTimeRanges {
                    let loadedTimeRange = value.timeRangeValue
                    percentageComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
                }
        return percentageComplete * 100
    }
}
