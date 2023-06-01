import AVFoundation

class ContentKeyManager {
    static let shared: ContentKeyManager = ContentKeyManager()
    let contentKeySession: AVContentKeySession
    let contentKeyDelegate: ContentKeyDelegate
    let contentKeyDelegateQueue = DispatchQueue(label: "com.tpstreams.iOSPlayerSDK.ContentKeyDelegateQueue")
    
    private init() {
        contentKeySession = AVContentKeySession(keySystem: .fairPlayStreaming)
        contentKeyDelegate = ContentKeyDelegate()
        contentKeySession.setDelegate(contentKeyDelegate, queue: contentKeyDelegateQueue)
    }
}
