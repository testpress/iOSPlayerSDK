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

        if DomainOfflineAsset.manager.exists(id: asset.id) { return }

        let avUrlAsset = AVURLAsset(url: URL(string: asset.video.playbackURL)!)

        guard let task = assetDownloadURLSession.aggregateAssetDownloadTask(
            with: avUrlAsset,
            mediaSelections: [avUrlAsset.preferredMediaSelection],
            assetTitle: asset.title,
            assetArtworkData: nil,
            options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: videoQuality.bitrate]
        ) else { return }

        let domainOfflineAsset = DomainOfflineAsset.create(
            assetId: asset.id,
            srcURL: asset.video.playbackURL,
            title: asset.title,
            resolution:videoQuality.resolution,
            duration: asset.video.duration,
            bitRate: videoQuality.bitrate
        )
        DomainOfflineAsset.manager.add(object: domainOfflineAsset)
        assetDownloadDelegate.activeDownloadsMap[task] = domainOfflineAsset
        task.resume()
        tpStreamsDownloadDelegate?.onStart(offlineAsset: domainOfflineAsset.asOfflineAsset())
    }
    
    public func pauseDownload(_ offlineAsset: OfflineAsset) {
        guard let domainOfflineAsset = DomainOfflineAsset.manager.get(id: offlineAsset.assetId) else { return }
        if let task = assetDownloadDelegate.activeDownloadsMap.first(where: { $0.value == domainOfflineAsset })?.key {
            task.suspend()
            DomainOfflineAsset.manager.update(object: domainOfflineAsset, with: ["status": Status.paused.rawValue])
            tpStreamsDownloadDelegate?.onPause(offlineAsset: domainOfflineAsset.asOfflineAsset())
        }
    }
    
    public func resumeDownload(_ offlineAsset: OfflineAsset) {
        guard let domainOfflineAsset = DomainOfflineAsset.manager.get(id: offlineAsset.assetId) else { return }
        if let task = assetDownloadDelegate.activeDownloadsMap.first(where: { $0.value == domainOfflineAsset })?.key {
            if task.state != .running {
                task.resume()
                DomainOfflineAsset.manager.update(object: domainOfflineAsset, with: ["status": Status.inProgress.rawValue])
                tpStreamsDownloadDelegate?.onResume(offlineAsset: domainOfflineAsset.asOfflineAsset())
            }
        }
    }
    
    public func getOfflineAssets() -> [OfflineAsset]{
        return DomainOfflineAsset.manager.getAll().map { $0.asOfflineAsset() }
    }

}

internal class AssetDownloadDelegate: NSObject, AVAssetDownloadDelegate {

    var activeDownloadsMap = [AVAggregateAssetDownloadTask: DomainOfflineAsset]()
    var tpStreamsDownloadDelegate: TPStreamsDownloadDelegate? = nil

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let assetDownloadTask = task as? AVAggregateAssetDownloadTask else { return }
        guard let domainOfflineAsset = activeDownloadsMap[assetDownloadTask] else { return }
        updateDownloadCompleteStatus(error, domainOfflineAsset)
        activeDownloadsMap.removeValue(forKey: assetDownloadTask)
        tpStreamsDownloadDelegate?.onComplete(offlineAsset: domainOfflineAsset.asOfflineAsset())
    }
    
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
        guard let domainOfflineAsset = activeDownloadsMap[aggregateAssetDownloadTask] else { return }
        DomainOfflineAsset.manager.update(object: domainOfflineAsset, with: ["downloadedPath": String(location.relativePath)])
        tpStreamsDownloadDelegate?.onStateChange(offlineAsset: domainOfflineAsset.asOfflineAsset())
    }

    func urlSession(_ session: URLSession,
                    aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                    didLoad timeRange: CMTimeRange,
                    totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                    timeRangeExpectedToLoad: CMTimeRange,
                    for mediaSelection: AVMediaSelection
    ) {
        guard let domainOfflineAsset = activeDownloadsMap[aggregateAssetDownloadTask] else { return }

        let percentageComplete = calculateDownloadPercentage(loadedTimeRanges, timeRangeExpectedToLoad)
        DomainOfflineAsset.manager.update(object: domainOfflineAsset, with: ["status": Status.inProgress.rawValue, "percentageCompleted": percentageComplete])
        tpStreamsDownloadDelegate?.onStateChange(offlineAsset: domainOfflineAsset.asOfflineAsset())
    }

    private func updateDownloadCompleteStatus(_ error: Error?,_ domainOfflineAsset: DomainOfflineAsset) {
        let status: Status = (error == nil) ? .finished : .failed
        let updateValues: [String: Any] = ["status": status.rawValue, "downloadedAt": Date()]
        DomainOfflineAsset.manager.update(object: domainOfflineAsset, with: updateValues)
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
