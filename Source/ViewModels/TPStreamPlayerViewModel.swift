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
    
    init(player: TPAVPlayer) {
        self.player = player
        self.player.onError = { [weak self] error in
            self?.showError(error: error)
        }
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
}
