//
//  ContentKeyDelegate.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 31/05/23.
//
import AVFoundation
import Sentry


class ContentKeyDelegate: NSObject, AVContentKeySessionDelegate {
    var contentID: String?
    var assetID: String?
    var accessToken: String?
    public var onError: ((Error) -> Void)?
    var requestingPersistentKey = false
    
    lazy var contentKeyDirectory: URL = {
        guard let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to determine document directory URL")
        }

        let contentKeyDirectory = documentURL.appendingPathComponent(".keys", isDirectory: true)
        if !FileManager.default.fileExists(atPath: contentKeyDirectory.path, isDirectory: nil) {
            do {
                try FileManager.default.createDirectory(at: contentKeyDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch {
                fatalError("Unable to create directory for content keys at path: \(contentKeyDirectory.path)")
            }
        }

        return contentKeyDirectory
    }()
    
    enum ProgramError: Error {
        case missingApplicationCertificate
        case noCKCReturnedByKSM
    }
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVContentKeyRequest) {
        handleFPSKeyRequest(keyRequest)
    }
    
    func contentKeySession(_ session: AVContentKeySession, didProvideRenewingContentKeyRequest keyRequest: AVContentKeyRequest) {
        handleFPSKeyRequest(keyRequest)
    }
    
    func contentKeySession(_ session: AVContentKeySession, didProvide keyRequest: AVPersistableContentKeyRequest) {
        handlePersistableFPSKeyRequest(keyRequest: keyRequest)
    }
    
    func contentKeySession(_ session: AVContentKeySession, shouldRetry keyRequest: AVContentKeyRequest,
                           reason retryReason: AVContentKeyRequest.RetryReason) -> Bool {
        switch retryReason {
        case .timedOut, .receivedResponseWithExpiredLease, .receivedObsoleteContentKey:
            return true
        default:
            return false
        }
    }
    
    func handleFPSKeyRequest(_ keyRequest: AVContentKeyRequest){
        guard let contentKeyIdentifierURL = URL(string: keyRequest.identifier as? String ??  ""),
              let contentID = contentKeyIdentifierURL.host
        else {
            self.contentID = nil
            debugPrint("Failed to retrieve the assetID from the keyRequest!")
            return
        }
        self.contentID = contentID
        
        let encryptedSPCMessageCallback = { [weak self] (spcData: Data?, error: Error?) in
            guard let strongSelf = self else { return }
            strongSelf.encryptedSPCMessageCallback(keyRequest, spcData, error)
        }
        requestEncryptedSPCMessage(keyRequest, encryptedSPCMessageCallback)
    }
    
    func handlePersistableFPSKeyRequest(keyRequest: AVPersistableContentKeyRequest) {
        guard let contentKeyURL = getPersistentContentKeyURL(),
              let contentKey = FileManager.default.contents(atPath: contentKeyURL.path) else {
            requestEncryptedSPCMessage(keyRequest) { [weak self] (spcData, error) in
                self?.encryptedSPCMessageForPersistentKeyCallback(spcData, error, keyRequest)
            }
            return
        }
        
        let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: contentKey)
        keyRequest.processContentKeyResponse(keyResponse)
    }
    
    func getPersistentContentKeyURL() -> URL?{
        guard let contentID = self.contentID else { return nil }
        
        return contentKeyDirectory.appendingPathComponent("\(contentID)-Key")
    }
    
    func requestEncryptedSPCMessage(_ keyRequest: AVContentKeyRequest, _ encryptedSPCMessageCallback: @escaping (_ : Data?, _ : Error?) -> Void) {
        
        do {
            let applicationCertificate = try self.getApplicationCertificate()
            keyRequest.makeStreamingContentKeyRequestData(forApp: applicationCertificate,
                                                          contentIdentifier: contentID!.data(using: .utf8),
                                                          options: [AVContentKeyRequestProtocolVersionsKey: [1]],
                                                          completionHandler:encryptedSPCMessageCallback)
            
        } catch {
            captureErrorInSentry(error, assetID, accessToken)
            keyRequest.processContentKeyResponseError(error)
        }
    }
    
    func getApplicationCertificate() throws -> Data {
        guard let url = URL(string: "https://app.tpstreams.com/static/fairplay.cer"),
              let applicationCertificate = try? Data(contentsOf: url) else {
            throw ProgramError.missingApplicationCertificate
        }
        
        return applicationCertificate
    }
    
    func encryptedSPCMessageCallback(_ keyRequest: AVContentKeyRequest, _ spcData: Data?, _ error: Error?) {
        if let error = error {
            keyRequest.processContentKeyResponseError(error)
            return
        }
        guard let spcData = spcData else { return }
        
        self.requestCKC(spcData) { ckcData, error in
            if let error = error {
                self.onError?(error)
                keyRequest.processContentKeyResponseError(error)
                return
            }
            
            let keyResponse = AVContentKeyResponse(fairPlayStreamingKeyResponseData: ckcData!)
            keyRequest.processContentKeyResponse(keyResponse)
        }
    }
    
    func encryptedSPCMessageForPersistentKeyCallback(_ spcData: Data?, _ error: Error?, _ keyRequest: AVPersistableContentKeyRequest) {
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
    
    func writePersistableContentKey(contentKey: Data) throws {
        guard let fileURL = getPersistentContentKeyURL() else { return }
        
        try contentKey.write(to: fileURL, options: Data.WritingOptions.atomicWrite)
    }
    
    func requestCKC(_ spcData: Data, _ completion: @escaping(Data?, Error?) -> Void) {
        guard let assetID = assetID,
              let accessToken = accessToken else { return }
        TPStreamsSDK.provider.API.getDRMLicense(assetID, accessToken, spcData, contentID!, completion)
    }
    
    func setAssetDetails(_ assetID: String, _ accessToken: String) {
        self.assetID = assetID
        self.accessToken = accessToken
    }
}
