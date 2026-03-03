//
//  TPStreamsDownloadManager.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 07/10/24.
//

import Foundation
import AVFoundation
import UIKit

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
        contentKeyDelegate.onError = { [weak self] error in
            guard let self = self else { return }
            if error as? TPStreamPlayerError == .unauthorizedAccess {
                self.requestPersistentKeyWithNewAccessToken()
            } else {
                self.handleDownloadFailure(assetId: self.contentKeyDelegate.assetID, error: error)
            }
        }
        #endif
    }
    
    private func handleDownloadFailure(assetId: String?, error: Error?) {
        guard let assetId = assetId,
              let localOfflineAsset = LocalOfflineAsset.manager.get(id: assetId) else { return }

        if let error = error {
            print("Download failed for asset \(assetId): \(error.localizedDescription)")
        }

        LocalOfflineAsset.manager.update(object: localOfflineAsset, with: ["status": Status.failed.rawValue])
        tpStreamsDownloadDelegate?.onFailed(offlineAsset: localOfflineAsset.asOfflineAsset())
        tpStreamsDownloadDelegate?.onStateChange(status: .failed, offlineAsset: localOfflineAsset.asOfflineAsset())
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

    
    internal func fetchQualities(
        for asset: Asset,
        completion: @escaping (Result<[VideoQuality], TPDownloadError>) -> Void
    ) {
        guard let urlString = asset.video?.playbackURL,
              let url = URL(string: urlString) else {
            completion(.failure(.assetNotFound))
            return
        }

        M3U8Parser.parseQualities(from: url) { qualities in
            completion(.success(qualities))
        }
    }

    public func startDownload(
        assetID: String,
        accessToken: String? = nil,
        resolution: String? = nil,
        presentingViewController: UIViewController? = nil,
        completion: ((Result<OfflineAsset, TPDownloadError>) -> Void)? = nil
    ) {
        let token = accessToken ?? TPStreamsSDK.authToken

        TPStreamsSDK.provider.API.getAsset(assetID, token) { [weak self] asset, error in
            guard let self = self else { return }

            if let error = error {
                completion?(.failure(.networkError(error)))
                return
            }

            guard let asset = asset else {
                completion?(.failure(.assetNotFound))
                return
            }

            self.fetchQualities(for: asset) { result in
                switch result {
                case .failure(let error):
                    completion?(.failure(error))
                case .success(let qualities):
                    if let requestedResolution = resolution {
                        self.enqueueDownload(forResolution: requestedResolution, asset: asset, from: qualities, token: token, completion: completion)
                    } else if let presentingViewController = presentingViewController {
                        self.showQualityPicker(qualities: qualities, asset: asset, token: token, on: presentingViewController, completion: completion)
                    } else {
                        completion?(.failure(.resolutionRequired))
                    }
                }
            }
        }
    }

    private func showQualityPicker(
        qualities: [VideoQuality],
        asset: Asset,
        token: String?,
        on viewController: UIViewController,
        completion: ((Result<OfflineAsset, TPDownloadError>) -> Void)?
    ) {
        let alert = UIAlertController(title: "Select Download Quality", message: nil, preferredStyle: .actionSheet)
        
        for quality in qualities {
            alert.addAction(UIAlertAction(title: quality.resolution, style: .default) { _ in
                self.enqueueDownload(forResolution: quality.resolution, asset: asset, from: qualities, token: token, completion: completion)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        DispatchQueue.main.async {
            viewController.present(alert, animated: true)
        }
    }

    private func enqueueDownload(
        forResolution resolution: String,
        asset: Asset,
        from availableQualities: [VideoQuality],
        token: String?,
        completion: ((Result<OfflineAsset, TPDownloadError>) -> Void)?
    ) {
        guard let quality = selectQuality(resolution: resolution, from: availableQualities) else {
            completion?(.failure(.resolutionNotAvailable(resolution)))
            return
        }

        let videoQuality = quality

        do {
            try self.submitDownload(asset: asset, accessToken: token, videoQuality: videoQuality)

            if let offlineAsset = LocalOfflineAsset.manager.get(id: asset.id) {
                completion?(.success(offlineAsset.asOfflineAsset()))
            } else {
                completion?(.failure(.downloadStartFailed))
            }
        } catch {
            completion?(.failure(.downloadExecutionFailed(error)))
        }
    }

    private func selectQuality(resolution: String, from availableQualities: [VideoQuality]) -> VideoQuality? {
        return availableQualities.first(where: { $0.resolution == resolution })
    }

    internal func submitDownload(asset: Asset, accessToken: String?, videoQuality: VideoQuality, metadata: [String: Any]? = nil, offlineLicenseDurationSeconds: Double? = nil) throws {
        #if targetEnvironment(simulator)
            if (asset.video?.drmEncrypted == true){
                print("Downloading DRM content is not supported in simulator")
                throw NSError(domain: "TPStreamsSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "DRM content downloading is not supported in simulator"])
            }
        #else
            contentKeyDelegate.setAssetDetails(asset.id, accessToken, true, offlineLicenseDurationSeconds)
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
        ) else {
            let offlineAsset = OfflineAsset(assetId: asset.id, title: asset.title)
            tpStreamsDownloadDelegate?.onFailed(offlineAsset: offlineAsset)
            tpStreamsDownloadDelegate?.onStateChange(status: .failed, offlineAsset: offlineAsset)
            return
        }

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
                    DispatchQueue.main.async {
                        self.handleDownloadFailure(assetId: asset.id, error: error)
                    }
                }
            }
        }
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
        
        let hasActiveTask = assetDownloadDelegate.activeDownloadsMap.first(where: { $0.value == localOfflineAsset })?.key
        if let task = hasActiveTask {
            task.cancel()
        }
        
        guard let fileURL = localOfflineAsset.downloadedFileURL else {
            LocalOfflineAsset.manager.delete(id: assetId)
            if hasActiveTask == nil {
                tpStreamsDownloadDelegate?.onCanceled(assetId: assetId)
            }
            return
        }
        
        deleteDownloadedFile(fileURL, localOfflineAsset: localOfflineAsset) { [weak self] success, error in
            if success {
                LocalOfflineAsset.manager.delete(id: assetId)
                if hasActiveTask == nil {
                    self?.tpStreamsDownloadDelegate?.onCanceled(assetId: assetId)
                }
            } else {
                print("An error occurred trying to delete the contents on disk for \(assetId): \(String(describing: error))")
            }
        }
    }
    
    internal func removeIncompleteDownloads() {
        LocalOfflineAsset.manager.getAll().filter { localOfflineAsset in
            localOfflineAsset.status != Status.finished.rawValue
        }.forEach { localOfflineAsset in
            cancelDownload(localOfflineAsset.assetId)
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
                    if localOfflineAsset.drmContentId != nil {
                        self.contentKeyDelegate.cleanupPersistentContentKey()
                    }
                    
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

    public func updateOfflineLicenseExpiry(_ assetID: String, expiryDate: Date?) {
        DispatchQueue.main.async {
            let updateData: [String: Any] = ["licenseExpiryDate": expiryDate ?? NSNull()]
            LocalOfflineAsset.manager.update(id: assetID, with: updateData)
        }
    }

    public func isOfflineAssetLicenseExpired(_ assetID: String) -> Bool {
        var isExpired = true
        DispatchQueue.main.sync {
            if let offlineAsset = LocalOfflineAsset.manager.get(id: assetID) {
                isExpired = offlineAsset.isOfflineLicenseExpired()
            }
        }
        return isExpired
    }

    private func requestPersistentKeyWithNewAccessToken() {
        guard let assetId = contentKeyDelegate.assetID else { return }
        guard let delegate = tpStreamsDownloadDelegate else { return }
        let currentLicenseDuration = contentKeyDelegate.licenseDurationSeconds
        
        delegate.onRequestNewAccessToken(assetId: assetId) { [weak self] newToken in
            guard let self = self else { return }
            
            if let newToken = newToken {
                self.contentKeyDelegateQueue.async {
                    self.contentKeyDelegate.setAssetDetails(assetId, newToken, true, currentLicenseDuration)
                    DispatchQueue.main.async {
                        self.requestPersistentKey(assetId)
                    }
                }
            } else {
                self.handleDownloadFailure(assetId: assetId, error: nil)
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
        } else if status == Status.failed {
            tpStreamsDownloadDelegate?.onFailed(offlineAsset: localOfflineAsset.asOfflineAsset())
            tpStreamsDownloadDelegate?.onStateChange(status: status, offlineAsset: localOfflineAsset.asOfflineAsset())
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
    func onFailed(offlineAsset: OfflineAsset)
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
    func onFailed(offlineAsset: OfflineAsset) {}

    func onRequestNewAccessToken(assetId: String, completion: @escaping (String?) -> Void) {
        debugPrint("Default onRequestNewAccessToken called - no token returned for assetId: \(assetId)")
        completion(nil) 
    }
}

public enum TPDownloadError: Error {
    case assetNotFound
    case resolutionNotAvailable(String)
    case resolutionRequired
    case downloadStartFailed
    case networkError(Error)
    case downloadExecutionFailed(Error)

    public var code: Int {
        switch self {
        case .assetNotFound: return 6001
        case .resolutionNotAvailable: return 6002
        case .resolutionRequired: return 6003
        case .downloadStartFailed: return 6004
        case .networkError: return 6005
        case .downloadExecutionFailed: return 6006
        }
    }

    public var message: String {
        switch self {
        case .assetNotFound:
            return "Asset not found"
        case .resolutionNotAvailable(let res):
            return "Resolution \(res) not available"
        case .resolutionRequired:
            return "Resolution required if no presentingViewController provided"
        case .downloadStartFailed:
            return "Failed to start download"
        case .networkError(let error):
            return error.localizedDescription
        case .downloadExecutionFailed(let error):
            return error.localizedDescription
        }
    }
}

extension TPDownloadError: CustomNSError {
    public var errorCode: Int { code }
    public var errorUserInfo: [String: Any] { [NSLocalizedDescriptionKey: message] }
}
