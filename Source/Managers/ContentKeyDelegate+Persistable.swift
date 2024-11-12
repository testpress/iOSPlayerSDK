//
//  ContentKeyDelegate+Persistable.swift
//  TPStreamsSDK
//
//  Created by Prithuvi on 11/11/24.
//

import Foundation
import AVFoundation

extension ContentKeyDelegate {
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVPersistableContentKeyRequest) {
        handlePersistableContentKeyRequest(session, keyRequest: keyRequest)
    }
    
    func handlePersistableContentKeyRequest(_ session: AVContentKeySession, keyRequest: AVPersistableContentKeyRequest) {
        guard let contentKeyURL = getPersistentContentKeyURL(),
              let contentKey = FileManager.default.contents(atPath: contentKeyURL.path) else {
            requestEncryptedSPCMessage(keyRequest) { [weak self] (spcData, error) in
                self?.encryptedSPCMessageForPersistentKeyCallback(session, spcData, error, keyRequest)
            }
            return
        }
        let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: contentKey)
        keyRequest.processContentKeyResponse(keyResponse)
    }
    
    func encryptedSPCMessageForPersistentKeyCallback(_ session: AVContentKeySession, _ spcData: Data?, _ error: Error?, _ keyRequest: AVPersistableContentKeyRequest) {
        guard let spcData = spcData else { return }
        
        self.requestCKC(spcData) { ckcData, error in
            if let error = error {
                keyRequest.processContentKeyResponseError(error)
                return
            }
            guard let ckcData = ckcData else { return }
            
            do {
                if self.requestingPersistentKey {
                    let persistentKey = try keyRequest.persistableContentKey(fromKeyVendorResponse: ckcData, options: nil)
                    try self.writePersistableContentKey(contentKey: persistentKey)
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
    
    func writePersistableContentKey(contentKey: Data) throws {
        guard let fileURL = getPersistentContentKeyURL() else { return }
        
        try contentKey.write(to: fileURL, options: Data.WritingOptions.atomicWrite)
    }
    
    func getPersistentContentKeyURL() -> URL?{
        guard let contentID = self.contentID else { return nil }
        
        return contentKeyDirectory.appendingPathComponent("\(contentID)-Key")
    }
}
