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
    private var tpStreamsDownloadDelegate: TPStreamsDownloadDelegate? = nil

    private init() {
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "com.tpstreams.downloadSession")
        assetDownloadDelegate = AssetDownloadDelegate()
        assetDownloadURLSession = AVAssetDownloadURLSession(
            configuration: backgroundConfiguration,
            assetDownloadDelegate: assetDownloadDelegate,
            delegateQueue: OperationQueue.main
        )
    }
    
    public func setTPStreamsDownloadDelegate(tpStreamsDownloadDelegate: TPStreamsDownloadDelegate) {
        self.tpStreamsDownloadDelegate = tpStreamsDownloadDelegate
        assetDownloadDelegate.tpStreamsDownloadDelegate = tpStreamsDownloadDelegate
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
        task.resume()
        tpStreamsDownloadDelegate?.onStart(offlineAsset: offlineAsset)
    }
    
    public func pauseDownload(_ offlineAsset: OfflineAsset) {
        if let task = assetDownloadDelegate.activeDownloadsMap.first(where: { $0.value == offlineAsset })?.key {
            task.suspend()
            OfflineAsset.manager.update(object: offlineAsset, with: ["status": Status.paused.rawValue])
            tpStreamsDownloadDelegate?.onPause(offlineAsset: offlineAsset)
        }
    }
    
    public func resumeDownload(_ offlineAsset: OfflineAsset) {
        if let task = assetDownloadDelegate.activeDownloadsMap.first(where: { $0.value == offlineAsset })?.key {
            if task.state != .running {
                task.resume()
                OfflineAsset.manager.update(object: offlineAsset, with: ["status": Status.inProgress.rawValue])
                tpStreamsDownloadDelegate?.onResume(offlineAsset: offlineAsset)
            }
        }
    }
    
    public func getAllOfflineAssets() -> [OfflineAsset]{
        return Array(OfflineAsset.manager.getAll())
    }

}

internal class AssetDownloadDelegate: NSObject, AVAssetDownloadDelegate {

    var activeDownloadsMap = [AVAggregateAssetDownloadTask: OfflineAsset]()
    var tpStreamsDownloadDelegate: TPStreamsDownloadDelegate? = nil

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let assetDownloadTask = task as? AVAggregateAssetDownloadTask else { return }
        guard let offlineAsset = activeDownloadsMap[assetDownloadTask] else { return }
        updateDownloadCompleteStatus(error, offlineAsset)
        activeDownloadsMap.removeValue(forKey: assetDownloadTask)
        tpStreamsDownloadDelegate?.onComplete(offlineAsset: offlineAsset)
    }
    
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
        guard let offlineAsset = activeDownloadsMap[aggregateAssetDownloadTask] else { return }
        OfflineAsset.manager.update(object: offlineAsset, with: ["downloadedPath": String(location.relativePath)])
        tpStreamsDownloadDelegate?.onStateChange(offlineAsset: offlineAsset)
    }

    func urlSession(_ session: URLSession,
                    aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                    didLoad timeRange: CMTimeRange,
                    totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                    timeRangeExpectedToLoad: CMTimeRange,
                    for mediaSelection: AVMediaSelection
    ) {
        guard let offlineAsset = activeDownloadsMap[aggregateAssetDownloadTask] else { return }

        let percentageComplete = calculateDownloadPercentage(loadedTimeRanges, timeRangeExpectedToLoad)
        OfflineAsset.manager.update(object: offlineAsset, with: ["status": Status.inProgress.rawValue, "percentageCompleted": percentageComplete])
        tpStreamsDownloadDelegate?.onStateChange(offlineAsset: offlineAsset)
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

public protocol TPStreamsDownloadDelegate {
    func onComplete(offlineAsset: OfflineAsset)
    func onStart(offlineAsset: OfflineAsset)
    func onPause(offlineAsset: OfflineAsset)
    func onResume(offlineAsset: OfflineAsset)
    func onStateChange(offlineAsset: OfflineAsset)
}
