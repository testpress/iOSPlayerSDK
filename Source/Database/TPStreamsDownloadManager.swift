//
//  TPStreamsDownloadManager.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 07/10/24.
//

import Foundation
import AVFoundation
import M3U8Parser

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
        contentKeySession = AVContentKeySession(keySystem: .fairPlayStreaming)
        contentKeyDelegate = ContentKeyDelegate()
        contentKeySession.setDelegate(contentKeyDelegate, queue: contentKeyDelegateQueue)
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

    internal func startDownload(asset: Asset, videoQuality: VideoQuality, accessToken: String) {
        if LocalOfflineAsset.manager.exists(id: asset.id) {
            return
        }
        
        extractContentIDFromMasterURL(masterURL: URL(string: asset.video!.playbackURL)!) { result in
            switch result {
            case .success(let contentID):
                
                
                
                let avUrlAsset = AVURLAsset(url: URL(string: asset.video!.playbackURL)!)
                
                guard let task = self.assetDownloadURLSession.aggregateAssetDownloadTask(
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
                    resolution: videoQuality.resolution,
                    duration: asset.video!.duration,
                    bitRate: videoQuality.bitrate,
                    folderTree: asset.folderTree ?? ""
                )
                // Optionally store the content ID
                localOfflineAsset.contentID = contentID
                
                LocalOfflineAsset.manager.add(object: localOfflineAsset)
                self.assetDownloadDelegate.activeDownloadsMap[task] = localOfflineAsset
                task.resume()
                self.tpStreamsDownloadDelegate?.onStart(offlineAsset: localOfflineAsset.asOfflineAsset())
                self.tpStreamsDownloadDelegate?.onStateChange(status: .inProgress, offlineAsset: localOfflineAsset.asOfflineAsset())
                
                if (asset.video?.drmEncrypted == true){
                    self.requestPersistentKey(localOfflineAsset.assetId, accessToken)
                }
            case .failure(let error):
                print("Error extracting content ID: \(error.localizedDescription)")
            }
        }
        
        
        
    }

    func extractContentIDFromMasterURL(masterURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            // Create a playlist model from the master URL
            let masterPlaylist = try M3U8PlaylistModel(url: masterURL)
            
            // Check if the master playlist contains a valid stream list
            if let streamList = masterPlaylist.masterPlaylist?.xStreamList, streamList.count != 0 {
                // Take the first variant's URL from the stream list
                if let variant = streamList.xStreamInf(at: 0),
                   let variantURL = variant.m3u8URL() {
                    parseVariantURL(variantURL) { result in
                        switch result {
                        case .success(let contentID):
                            completion(.success(contentID)) // Pass the contentID back
                        case .failure(let error):
                            completion(.failure(error)) // Pass the error back
                        }
                    }
                } else {
                    completion(.failure(NSError(domain: "M3U8Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No variant URL found."])))
                }
            } else {
                completion(.failure(NSError(domain: "M3U8Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No variants found in master playlist."])))
            }
        } catch {
            completion(.failure(error)) // Pass the error back if something went wrong
        }
    }

    func parseVariantURL(_ variantURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            // Parse the variant playlist to retrieve the media playlist model
            let variantPlaylist = try M3U8PlaylistModel(url: variantURL)
            
            // Access the first segment from the variant playlist (segmentList is a list of M3U8SegmentInfo)
            if let segmentList = variantPlaylist.mainMediaPl?.segmentList, segmentList.count != 0 {
                if let key = segmentList.segmentInfo(at: 0)?.xKey,
                   let uri = key.url(),
                   let contentID = extractIDFromURI(uri: uri) {
                    completion(.success(contentID)) // Pass the extracted contentID back
                } else {
                    completion(.failure(NSError(domain: "M3U8Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No contentID found in the variant."])))
                }
            } else {
                completion(.failure(NSError(domain: "M3U8Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "No segments found in variant playlist."])))
            }
        } catch {
            completion(.failure(error)) // Pass the error back if something went wrong
        }
    }

    // Helper function to extract contentID from URI
    func extractIDFromURI(uri: String) -> String? {
        if uri.contains("skd://") {
            return uri.replacingOccurrences(of: "skd://", with: "")
        }
        return nil
    }
    
    private func requestPersistentKey(_ assetID: String,_ accessToken: String) {
        guard let localOfflineAsset = LocalOfflineAsset.manager.get(id: assetID) else {
            print("Asset with ID \(assetID) does not exist.")
            return
        }
        contentKeySession.processContentKeyRequest(
            withIdentifier: "skd://\(localOfflineAsset.contentID)",
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
    
    public func cancelDownload(_ assetId: String) {
        guard let localOfflineAsset = LocalOfflineAsset.manager.get(id: assetId) else {
            print("Asset with ID \(assetId) does not exist.")
            return
        }
        
        if let task = assetDownloadDelegate.activeDownloadsMap.first(where: { $0.value == localOfflineAsset })?.key {
            task.cancel()
            self.deleteDownloadedFile(localOfflineAsset.downloadedFileURL!) { success, error in
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
            localOfflineAsset.status == Status.deleted.rawValue
        }.forEach { localOfflineAsset in
            guard let downloadedFileURL = localOfflineAsset.downloadedFileURL else {
                print("No downloaded file URL for asset \(localOfflineAsset.assetId). Skipping deletion.")
                return
            }
            
            self.deleteDownloadedFile(downloadedFileURL) { success, error in
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
        
        self.deleteDownloadedFile(localOfflineAsset.downloadedFileURL!) { success, error in
            if success {
                LocalOfflineAsset.manager.delete(id: localOfflineAsset.assetId)
            } else {
                print("An error occurred trying to delete the contents on disk for \(localOfflineAsset.assetId): \(String(describing: error))")
            }
        }
    }
    
    private func deleteDownloadedFile(_ downloadedFileURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                try FileManager.default.removeItem(at: downloadedFileURL)
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
}
