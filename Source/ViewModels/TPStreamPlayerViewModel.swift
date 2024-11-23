//
//  TPStreamPlayerViewModel.swift
//  TPStreamsSDK
//
//  Created by Testpress on 14/06/24.
//

import Foundation
import Combine

@available(iOS 13.0, *)
class TPStreamPlayerViewModel: ObservableObject {
    @Published var isFullScreen = false
    @Published var noticeMessage: String? = nil
    
    var player: TPAVPlayer
    private var playerStatusObservation: NSKeyValueObservation?
    
    init(player: TPAVPlayer) {
        self.player = player
        self.showLiveStreamNotice()
        if let initializationError = player.initializationError {
            showError(error: initializationError)
        }
        setupPlayerStatusObserver(for: player)
        self.player.onError = { [weak self] error in
            self?.showError(error: error)
        }
    }
    
    private func setupPlayerStatusObserver(for player: TPAVPlayer) {
        playerStatusObservation = player.observe(\.initializationStatus, options: [.new]) { [weak self] (_, change) in
            guard let self = self else { return }

            if let status = change.newValue {
                switch status {
                case "error":
                    self.showError(error: self.player.initializationError!)
                case "ready":
                    self.noticeMessage = nil
                    self.showLiveStreamNotice()
                default:
                    break
                }
            }
        }
    }
    
    func showLiveStreamNotice(){
        guard let liveStream = player.asset?.liveStream, let noticeMessage = liveStream.noticeMessage else {
                return
            }
        
        self.setNoticeMessage(noticeMessage)
    }
    
    func showError(error: Error) {
        var message: String
        if let tpStreamPlayerError = error as? TPStreamPlayerError {
            message = "\(tpStreamPlayerError.message)\nError code: \(tpStreamPlayerError.code)"
        } else {
            message = error.localizedDescription
        }
        setNoticeMessage(message)
    }
    
    private func setNoticeMessage(_ message: String) {
        self.noticeMessage = message
    }
    
    deinit {
        playerStatusObservation?.invalidate()
    }
}
