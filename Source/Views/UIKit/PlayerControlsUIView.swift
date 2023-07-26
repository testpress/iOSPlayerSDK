//
//  PlayerControlsUIKitView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 20/07/23.
//

import Foundation
import UIKit

class PlayerControlsUIView: UIView {
    @IBOutlet weak var playPauseButton: UIButton!
    
    var player: TPStreamPlayer! {
        didSet {
            addPlayerStatusChangeObserver()
        }
    }
    
    private func addPlayerStatusChangeObserver() {
        player.addObserver(self, forKeyPath: #keyPath(TPStreamPlayer.status), options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(TPStreamPlayer.status) {
            handlePlayerStatusChange()
        }
    }
    
    private func handlePlayerStatusChange(){
        switch player.status {
        case "playing":
            playPauseButton.setImage(UIImage(named: "pause", in: bundle, compatibleWith: nil), for: .normal)
        case "paused":
            playPauseButton.setImage(UIImage(named: "play", in: bundle, compatibleWith: nil), for: .normal)
        case "buffering":
            print("buffering")
        default:
            break
        }
    }
    @IBAction func playOrPauseButton(_ sender: Any) {
        if player.status == "paused" {
            player.play()
        } else {
            player.pause()
        }
    }
    
    @IBAction func rewind(_ sender: UIButton) {
        player.rewind()
    }
    
    @IBAction func forward(_ sender: Any) {
        player.forward()
    }
    
}
