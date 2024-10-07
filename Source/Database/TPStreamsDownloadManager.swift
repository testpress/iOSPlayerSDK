//
//  TPStreamsDownloadManager.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 07/10/24.
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
    
    public func startDownload(assetID: String, accessToken: String, resolution: String) {
        TPStreamsSDK.provider.API.getAsset(assetID, accessToken) { [weak self] asset, error in
            guard let self = self else { return }
            if let asset = asset {
                //TODO Create video quality object (dummy for now, can be implemented later)
                let videoQuality = VideoQuality.init(resolution: resolution, bitrate: 519200)
                startDownload(asset: asset, videoQuality: videoQuality)
            } else if let error = error{
                print (error)
            }
        }
    }

    internal func startDownload(asset: Asset, videoQuality: VideoQuality) {

        if LocalOfflineAsset.manager.exists(id: asset.id) {
            return
        }

        let avUrlAsset = AVURLAsset(url: URL(string: asset.video!.playbackURL)!)

        guard let task = assetDownloadURLSession.aggregateAssetDownloadTask(
            with: avUrlAsset,
            mediaSelections: [avUrlAsset.preferredMediaSelection],
            assetTitle: asset.title,
            assetArtworkData: nil,
            options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: videoQuality.bitrate]
        ) else { return }

        let localOfflineAsset = LocalOfflineAsset.create(
            assetId: asset.id,
            srcURL: asset.video!.playbackURL,
            title: asset.title,
            resolution:videoQuality.resolution,
            duration: asset.video!.duration,
            bitRate: videoQuality.bitrate,
            folderTree: asset.folderTree ?? ""
        )
        LocalOfflineAsset.manager.add(object: localOfflineAsset)
        assetDownloadDelegate.activeDownloadsMap[task] = localOfflineAsset
        task.resume()
        tpStreamsDownloadDelegate?.onStart(offlineAsset: localOfflineAsset.asOfflineAsset())
        tpStreamsDownloadDelegate?.onStateChange(status: .inProgress, offlineAsset: localOfflineAsset.asOfflineAsset())
    }
    
    public func pauseDownload(_ assetId: String) {
        guard let localOfflineAsset = LocalOfflineAsset.manager.get(id: assetId) else {
            print("Asset with ID \(assetId) does not exist.")
            return
        }

        if let task = assetDownloadDelegate.activeDownloadsMap.first(where: { $0.value == localOfflineAsset })?.key {
            task.suspend()
            LocalOfflineAsset.manager.update(object: localOfflineAsset, with: ["status": Status.paused.rawValue])
            tpStreamsDownloadDelegate?.onPause(offlineAsset: localOfflineAsset.asOfflineAsset())
            tpStreamsDownloadDelegate?.onStateChange(status: .paused, offlineAsset: localOfflineAsset.asOfflineAsset())
        }
    }
    
    public func resumeDownload(_ assetId: String) {
        guard let localOfflineAsset = LocalOfflineAsset.manager.get(id: assetId) else {
            print("Asset with ID \(assetId) does not exist.")
            return
        }
        
        if let task = assetDownloadDelegate.activeDownloadsMap.first(where: { $0.value == localOfflineAsset })?.key {
            if task.state != .running {
                task.resume()
                LocalOfflineAsset.manager.update(object: localOfflineAsset, with: ["status": Status.inProgress.rawValue])
                tpStreamsDownloadDelegate?.onResume(offlineAsset: localOfflineAsset.asOfflineAsset())
                tpStreamsDownloadDelegate?.onStateChange(status: .inProgress, offlineAsset: localOfflineAsset.asOfflineAsset())
            }
        }
    }
    
    public func getAllOfflineAssets() -> [OfflineAsset]{
        return Array(LocalOfflineAsset.manager.getAll().map({ localOfflineAsset in
            localOfflineAsset.asOfflineAsset()
        }))
    }

}

internal class AssetDownloadDelegate: NSObject, AVAssetDownloadDelegate {

    var activeDownloadsMap = [AVAggregateAssetDownloadTask: LocalOfflineAsset]()
    var tpStreamsDownloadDelegate: TPStreamsDownloadDelegate? = nil

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let assetDownloadTask = task as? AVAggregateAssetDownloadTask else { return }
        guard let localOfflineAsset = activeDownloadsMap[assetDownloadTask] else { return }
        updateDownloadCompleteStatus(error, localOfflineAsset)
        activeDownloadsMap.removeValue(forKey: assetDownloadTask)
        tpStreamsDownloadDelegate?.onComplete(offlineAsset: localOfflineAsset.asOfflineAsset())
    }

    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {
        guard let localOfflineAsset = activeDownloadsMap[aggregateAssetDownloadTask] else { return }
        LocalOfflineAsset.manager.update(object: localOfflineAsset, with: ["downloadedPath": String(location.relativePath)])
    }

    func urlSession(_ session: URLSession,
                    aggregateAssetDownloadTask: AVAggregateAssetDownloadTask,
                    didLoad timeRange: CMTimeRange,
                    totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                    timeRangeExpectedToLoad: CMTimeRange,
                    for mediaSelection: AVMediaSelection
    ) {
        guard let localOfflineAsset = activeDownloadsMap[aggregateAssetDownloadTask] else { return }

        let percentageComplete = calculateDownloadPercentage(loadedTimeRanges, timeRangeExpectedToLoad)
        LocalOfflineAsset.manager.update(object: localOfflineAsset, with: ["status": Status.inProgress.rawValue, "percentageCompleted": percentageComplete])
        tpStreamsDownloadDelegate?.onProgressChange(assetId: localOfflineAsset.assetId, percentage: percentageComplete)
        tpStreamsDownloadDelegate?.onStateChange(status: .inProgress, offlineAsset: localOfflineAsset.asOfflineAsset())
    }

    private func updateDownloadCompleteStatus(_ error: Error?,_ localOfflineAsset: LocalOfflineAsset) {
        let status: Status = (error == nil) ? .finished : .failed
        let updateValues: [String: Any] = ["status": status.rawValue, "downloadedAt": Date()]
        LocalOfflineAsset.manager.update(object: localOfflineAsset, with: updateValues)
        tpStreamsDownloadDelegate?.onComplete(offlineAsset: localOfflineAsset.asOfflineAsset())
        tpStreamsDownloadDelegate?.onStateChange(status: status, offlineAsset: localOfflineAsset.asOfflineAsset())
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
    func onProgressChange(assetId: String, percentage: Double)
    func onStateChange(status: Status, offlineAsset: OfflineAsset)
}
