import AVFoundation

class ContentKeyManager {
    static let shared: ContentKeyManager = ContentKeyManager()
    let contentKeySession: AVContentKeySession
    let contentKeyDelegate: ContentKeyDelegate
    let contentKeyDelegateQueue = DispatchQueue(label: "com.tpstreams.iOSPlayerSDK.ContentKeyDelegateQueue")
    private var playerMap: [String: TPAVPlayer] = [:]
    
    private init() {
        contentKeySession = AVContentKeySession(keySystem: .fairPlayStreaming)
        contentKeyDelegate = ContentKeyDelegate()
        contentKeySession.setDelegate(contentKeyDelegate, queue: contentKeyDelegateQueue)
    }
    
    func registerPlayer(_ player: TPAVPlayer, forAssetID assetID: String) {
        playerMap[assetID] = player
    }
    
    func getPlayerForAsset(_ assetID: String?) -> TPAVPlayer? {
        guard let assetID = assetID else { return nil }
        return playerMap[assetID]
    }
}
