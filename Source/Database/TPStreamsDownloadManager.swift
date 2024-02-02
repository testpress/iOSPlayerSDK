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

        if OfflineAssetEntity.manager.exists(id: asset.id) { return }

        let avUrlAsset = AVURLAsset(url: URL(string: asset.video.playbackURL)!)

        guard let task = assetDownloadURLSession.aggregateAssetDownloadTask(
            with: avUrlAsset,
            mediaSelections: [avUrlAsset.preferredMediaSelection],
            assetTitle: asset.title,
            assetArtworkData: nil,
            options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: videoQuality.bitrate]
        ) else { return }

        let offlineAssetEntity = OfflineAssetEntity.create(
            assetId: asset.id,
            srcURL: asset.video.playbackURL,
            title: asset.title,
            resolution:videoQuality.resolution,
            duration: asset.video.duration,
            bitRate: videoQuality.bitrate
        )
        OfflineAssetEntity.manager.add(object: offlineAssetEntity)
        assetDownloadDelegate.activeDownloadsMap[task] = offlineAssetEntity
        task.resume()
        tpStreamsDownloadDelegate?.onStart(offlineAsset: offlineAssetEntity.asOfflineAsset())
        tpStreamsDownloadDelegate?.onStateChange(status: .inProgress, offlineAsset: offlineAssetEntity.asOfflineAsset())
    }
    
    public func pauseDownload(_ offlineAsset: OfflineAsset) {
        guard let offlineAssetEntity = OfflineAssetEntity.manager.get(id: offlineAsset.assetId) else { return }
        if let task = assetDownloadDelegate.activeDownloadsMap.first(where: { $0.value == offlineAssetEntity })?.key {
            task.suspend()
            OfflineAssetEntity.manager.update(object: offlineAssetEntity, with: ["status": Status.paused.rawValue])
            tpStreamsDownloadDelegate?.onPause(offlineAsset: offlineAssetEntity.asOfflineAsset())
            tpStreamsDownloadDelegate?.onStateChange(status: .paused, offlineAsset: offlineAssetEntity.asOfflineAsset())
        }
    }
    
    public func resumeDownload(_ offlineAsset: OfflineAsset) {
        guard let offlineAssetEntity = OfflineAssetEntity.manager.get(id: offlineAsset.assetId) else { return }
        if let task = assetDownloadDelegate.activeDownloadsMap.first(where: { $0.value == offlineAssetEntity })?.key {
            if task.state != .running {
                task.resume()
                OfflineAssetEntity.manager.update(object: offlineAssetEntity, with: ["status": Status.inProgress.rawValue])
                tpStreamsDownloadDelegate?.onResume(offlineAsset: offlineAssetEntity.asOfflineAsset())
                tpStreamsDownloadDelegate?.onStateChange(status: .inProgress, offlineAsset: offlineAssetEntity.asOfflineAsset())
            }
        }
    }
    
    public func getAllOfflineAssets() -> [OfflineAsset]{
        return OfflineAssetEntity.manager.getAll().map { $0.asOfflineAsset() }
    }

}

internal class AssetDownloadDelegate: NSObject, AVAssetDownloadDelegate {

    var activeDownloadsMap = [AVAggregateAssetDownloadTask: OfflineAssetEntity]()
    var tpStreamsDownloadDelegate: TPStreamsDownloadDelegate? = nil

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let assetDownloadTask = task as? AVAggregateAssetDownloadTask else { return }
        guard let offlineAssetEntity = activeDownloadsMap[assetDownloadTask] else { return }
        updateDownloadCompleteStatus(error, offlineAssetEntity)
        activeDownloadsMap.removeValue(forKey: assetDownloadTask)
    }
    
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
        guard let offlineAssetEntity = activeDownloadsMap[aggregateAssetDownloadTask] else { return }
        OfflineAssetEntity.manager.update(object: offlineAssetEntity, with: ["downloadedPath": String(location.relativePath)])
    }

    func urlSession(_ session: URLSession,
                    aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                    didLoad timeRange: CMTimeRange,
                    totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                    timeRangeExpectedToLoad: CMTimeRange,
                    for mediaSelection: AVMediaSelection
    ) {
        guard let offlineAssetEntity = activeDownloadsMap[aggregateAssetDownloadTask] else { return }

        let percentageComplete = calculateDownloadPercentage(loadedTimeRanges, timeRangeExpectedToLoad)
        OfflineAssetEntity.manager.update(object: offlineAssetEntity, with: ["status": Status.inProgress.rawValue, "percentageCompleted": percentageComplete])
        tpStreamsDownloadDelegate?.onProgressChange(assetId: offlineAssetEntity.assetId, percentage: percentageComplete)
        tpStreamsDownloadDelegate?.onStateChange(status: .inProgress, offlineAsset: offlineAssetEntity.asOfflineAsset())
    }

    private func updateDownloadCompleteStatus(_ error: Error?,_ offlineAssetEntity: OfflineAssetEntity) {
        let status: Status = (error == nil) ? .finished : .failed
        let updateValues: [String: Any] = ["status": status.rawValue, "downloadedAt": Date()]
        OfflineAssetEntity.manager.update(object: offlineAssetEntity, with: updateValues)
        tpStreamsDownloadDelegate?.onComplete(offlineAsset: offlineAssetEntity.asOfflineAsset())
        tpStreamsDownloadDelegate?.onStateChange(status: status, offlineAsset: offlineAssetEntity.asOfflineAsset())
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
    func onStateChange(status: Status, offlineAsset: OfflineAsset)
    func onProgressChange(assetId: String, percentage: Double)
}
