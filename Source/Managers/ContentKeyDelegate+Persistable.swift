//
//  ContentKeyDelegate+Persistable.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 11/11/24.
//

import Foundation
import AVFoundation

let DEFAULT_LICENSE_EXPIRY_SECONDS: Double = 15 * 24 * 60 * 60 //15 days

extension ContentKeyDelegate {
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVPersistableContentKeyRequest) {
        handlePersistableContentKeyRequest(session, keyRequest: keyRequest)
    }
    
    func handlePersistableContentKeyRequest(_ session: AVContentKeySession, keyRequest: AVPersistableContentKeyRequest) {
        if let offlineKey = loadOfflineContentKey() {
            assignOfflineKey(keyRequest, contentKey: offlineKey)
        } else {
            fetchContentKeyFromNetwork(session, keyRequest)
        }
    }
    
    private func loadOfflineContentKey() -> Data? {
        guard let contentKeyURL = getPersistentContentKeyURL() else { return nil }
        return getPersistentContentKey(contentKeyURL)
    }
    
    private func assignOfflineKey(_ keyRequest: AVPersistableContentKeyRequest, contentKey: Data) {
        let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: contentKey)
        keyRequest.processContentKeyResponse(keyResponse)
    }
    
    private func fetchContentKeyFromNetwork(_ session: AVContentKeySession, _ keyRequest: AVPersistableContentKeyRequest) {
        requestEncryptedSPCMessage(keyRequest) { [weak self] (spcData, error) in
            self?.retrieveAndStoreContentKey(session, spcData, error, keyRequest)
        }
    }
    
    func retrieveAndStoreContentKey(_ session: AVContentKeySession, _ spcData: Data?, _ error: Error?, _ keyRequest: AVPersistableContentKeyRequest) {
        guard let spcData = spcData else { return }
        
        self.requestCKC(spcData) { ckcData, error in
            if let error = error {
                self.onError?(error)
                keyRequest.processContentKeyResponseError(error)
                return
            }
            guard let ckcData = ckcData else { return }
            
            do {
                if self.requestingPersistentKey {
                    let persistentKey = try keyRequest.persistableContentKey(fromKeyVendorResponse: ckcData, options: nil)
                    let expiryDate = Date().addingTimeInterval(self.licenseDurationSeconds ?? DEFAULT_LICENSE_EXPIRY_SECONDS)
                    try self.storePersistentContentKey(contentKey: persistentKey, expiryDate: expiryDate)
                }
                
                let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: ckcData)
                keyRequest.processContentKeyResponse(keyResponse)
            } catch {
                print(error)
            }
            
            self.requestingPersistentKey = false
        }
    }
    
    func isPersistentContentKeyExistsOnDisk() -> Bool{
        guard let url = getPersistentContentKeyURL() else { return false }
        
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    func getPersistentContentKey(_ contentKeyURL: URL) -> Data? {
        return FileManager.default.contents(atPath: contentKeyURL.path)
    }
    
    func storePersistentContentKey(contentKey: Data, expiryDate: Date) throws {
        guard let fileURL = getPersistentContentKeyURL() else { return }
        
        try contentKey.write(to: fileURL, options: Data.WritingOptions.atomicWrite)
        if let assetID = self.assetID {
            TPStreamsDownloadManager.shared.updateOfflineLicenseExpiry(assetID, expiryDate: expiryDate)
        }
    }

    func cleanupPersistentContentKey() {
        if let keyURL = getPersistentContentKeyURL() {
            try? FileManager.default.removeItem(at: keyURL)
        }
        if let assetID = self.assetID {
            TPStreamsDownloadManager.shared.updateOfflineLicenseExpiry(assetID, expiryDate: nil)
        }
    }
    
    func getPersistentContentKeyURL() -> URL?{
        guard let contentID = self.contentID else { return nil }
        
        return contentKeyDirectory.appendingPathComponent("\(contentID)-Key")
    }
}
