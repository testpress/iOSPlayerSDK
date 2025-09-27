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
    private var contentKeySession: AVContentKeySession!
    private var contentKeyDelegate: ContentKeyDelegate!
    private let contentKeyDelegateQueue = DispatchQueue(label: "com.tpstreams.iOSPlayerSDK.ContentKeyDelegateQueueOffline")

    private init() {
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "com.tpstreams.downloadSession")
        assetDownloadDelegate = AssetDownloadDelegate()
        assetDownloadURLSession = AVAssetDownloadURLSession(
            configuration: backgroundConfiguration,
            assetDownloadDelegate: assetDownloadDelegate,
            delegateQueue: OperationQueue.main
        )
        
        #if !targetEnvironment(simulator)
        contentKeySession = AVContentKeySession(keySystem: .fairPlayStreaming)
        contentKeyDelegate = ContentKeyDelegate()
        contentKeySession.setDelegate(contentKeyDelegate, queue: contentKeyDelegateQueue)
        contentKeyDelegate.onError = { error in
            if error as? TPStreamPlayerError == .unauthorizedAccess {
                self.requestPersistentKeyWithNewAccessToken()
            }
        }
        #endif
    }
    
    public func setTPStreamsDownloadDelegate(tpStreamsDownloadDelegate: TPStreamsDownloadDelegate) {
        self.tpStreamsDownloadDelegate = tpStreamsDownloadDelegate
        assetDownloadDelegate.tpStreamsDownloadDelegate = tpStreamsDownloadDelegate
    }
    
    public func isAssetDownloaded(assetID: String) -> Bool {
        if let localOfflineAsset = LocalOfflineAsset.manager.get(id: assetID),
           localOfflineAsset.status == Status.finished.rawValue {
            return true
        }
        return false
    }

    internal func startDownload(asset: Asset, accessToken: String?, videoQuality: VideoQuality, metadata: [String: Any]? = nil) throws {
        #if targetEnvironment(simulator)
            if (asset.video?.drmEncrypted == true){
                print("Downloading DRM content is not supported in simulator")
                throw NSError(domain: "TPStreamsSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "DRM content downloading is not supported in simulator"])
            }
        #else
            contentKeyDelegate.setAssetDetails(asset.id, accessToken, true)
        #endif

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
            thumbnailURL: asset.video!.thumbnailURL ?? "",
            folderTree: asset.folderTree ?? "",
            drmContentId: asset.drmContentId,
            metadata: metadata
        )
        LocalOfflineAsset.manager.add(object: localOfflineAsset)
        assetDownloadDelegate.activeDownloadsMap[task] = localOfflineAsset
        task.resume()
        tpStreamsDownloadDelegate?.onStart(offlineAsset: localOfflineAsset.asOfflineAsset())
        tpStreamsDownloadDelegate?.onStateChange(status: .inProgress, offlineAsset: localOfflineAsset.asOfflineAsset())
        
        if (asset.video?.drmEncrypted == true){
            M3U8Parser.extractContentID(url: URL(string: asset.video!.playbackURL)!) { result in
                switch result {
                case .success(let drmContentId):
                    print("Extracted DRM content ID: \(drmContentId)")
                    DispatchQueue.main.async {
                        LocalOfflineAsset.manager.update(id: asset.id, with: ["drmContentId": drmContentId])
                        self.requestPersistentKey(localOfflineAsset.assetId)
                    }
                case .failure(let error):
                    print("Error extracting content ID: \(error.localizedDescription)")
                }
            }
        }
        ToastHelper.show(message: DownloadMessages.started)
    }
    
    private func requestPersistentKey(_ assetID: String) {
        guard let localOfflineAsset = LocalOfflineAsset.manager.get(id: assetID) else {
            print("Asset with ID \(assetID) does not exist.")
            return
        }
        contentKeySession.processContentKeyRequest(
            withIdentifier: localOfflineAsset.drmContentId,
            initializationData: nil,
            options: nil
        )
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
            ToastHelper.show(message: DownloadMessages.paused)
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
                ToastHelper.show(message: DownloadMessages.resumed)
            }
        }
    }
    
    public func cancelDownload(_ assetId: String) {
        guard let localOfflineAsset = LocalOfflineAsset.manager.get(id: assetId) else {
            print("Asset with ID \(assetId) does not exist.")
            return
        }
        
        if let task = assetDownloadDelegate.activeDownloadsMap.first(where: { $0.value == localOfflineAsset })?.key {
            task.cancel()
            self.deleteDownloadedFile(localOfflineAsset.downloadedFileURL!, localOfflineAsset: localOfflineAsset) { success, error in
                if success {
                    LocalOfflineAsset.manager.delete(id: localOfflineAsset.assetId)
                } else {
                    print("An error occurred trying to delete the contents on disk for \(localOfflineAsset.assetId): \(String(describing: error))")
                }
            }
        }
    }
    
    internal func removePartiallyDeletedVideos() {
        LocalOfflineAsset.manager.getAll().filter { localOfflineAsset in
            localOfflineAsset.status != Status.finished.rawValue
        }.forEach { localOfflineAsset in
            guard let downloadedFileURL = localOfflineAsset.downloadedFileURL else {
                print("No downloaded file URL for asset \(localOfflineAsset.assetId). Skipping deletion.")
                return
            }
            
            self.deleteDownloadedFile(downloadedFileURL, localOfflineAsset: localOfflineAsset) { success, error in
                if success {
                    LocalOfflineAsset.manager.delete(id: localOfflineAsset.assetId)
                } else {
                    print("An error occurred trying to delete the contents on disk for \(localOfflineAsset.assetId): \(String(describing: error))")
                }
            }
        }
    }
    
    public func deleteDownload(_ offlineAssetId: String) {
        guard let localOfflineAsset = LocalOfflineAsset.manager.get(id: offlineAssetId),
              localOfflineAsset.status == Status.finished.rawValue,
              localOfflineAsset.downloadedFileURL != nil else { return }
        
        LocalOfflineAsset.manager.update(object: localOfflineAsset, with: ["status": Status.deleted.rawValue])
        tpStreamsDownloadDelegate?.onDelete(assetId: localOfflineAsset.assetId)
        
        self.deleteDownloadedFile(localOfflineAsset.downloadedFileURL!, localOfflineAsset: localOfflineAsset) { success, error in
            if success {
                LocalOfflineAsset.manager.delete(id: localOfflineAsset.assetId)
            } else {
                print("An error occurred trying to delete the contents on disk for \(localOfflineAsset.assetId): \(String(describing: error))")
            }
        }
    }
    
    private func deleteDownloadedFile(_ downloadedFileURL: URL, localOfflineAsset: LocalOfflineAsset, completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                try FileManager.default.removeItem(at: downloadedFileURL)
                
                DispatchQueue.main.async {
                    if let drmContentId = localOfflineAsset.drmContentId {
                        self.contentKeyDelegate.cleanupPersistentContentKey(for: drmContentId)
                    }
                }
                
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error)
                }
            }
        }
    }
    
    public func getAllOfflineAssets() -> [OfflineAsset] {
        // This method retrieves all offline assets from the local storage.
        // It filters out any assets that have a status of 'deleted',
        // ensuring that only available (non-deleted) video assets are returned.
        return LocalOfflineAsset.manager.getAll()
            .filter { $0.status != Status.deleted.rawValue }
            .map { $0.asOfflineAsset() }
    }

    private func requestPersistentKeyWithNewAccessToken() {
        guard let assetId = contentKeyDelegate.assetID else { return }
        guard let delegate = tpStreamsDownloadDelegate else { return }
        
        delegate.onRequestNewAccessToken(assetId: assetId) { [weak self] newToken in
            guard let self = self else { return }
            
            if let newToken = newToken {
                self.contentKeyDelegate.setAssetDetails(assetId, newToken, true)
                DispatchQueue.main.async {
                    self.requestPersistentKey(assetId)
                }
            }
        }
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
        let status: Status = {
            switch error {
            case nil:
                return .finished
            case let nsError as NSError where nsError.code == NSURLErrorCancelled:
                return .deleted
            default:
                return .failed
            }
        }()
        let updateValues: [String: Any] = ["status": status.rawValue, "downloadedAt": Date()]
        LocalOfflineAsset.manager.update(object: localOfflineAsset, with: updateValues)
        if status == Status.deleted {
            tpStreamsDownloadDelegate?.onCanceled(assetId: localOfflineAsset.assetId)
        } else {
            tpStreamsDownloadDelegate?.onComplete(offlineAsset: localOfflineAsset.asOfflineAsset())
            tpStreamsDownloadDelegate?.onStateChange(status: status, offlineAsset: localOfflineAsset.asOfflineAsset())
            ToastHelper.show(message: DownloadMessages.completed)
        }
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
    func onCanceled(assetId: String)
    func onDelete(assetId: String)
    func onProgressChange(assetId: String, percentage: Double)
    func onStateChange(status: Status, offlineAsset: OfflineAsset)
    func onRequestNewAccessToken(assetId: String, completion: @escaping (String?) -> Void)
}

public extension TPStreamsDownloadDelegate {
    func onRequestNewAccessToken(assetId: String, completion: @escaping (String?) -> Void) {
        debugPrint("Default onRequestNewAccessToken called - no token returned for assetId: \(assetId)")
        completion(nil) 
    }
}