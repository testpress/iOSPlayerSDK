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
    
    @IBAction func showOptionsMenu(_ sender: Any) {
        let optionsMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        optionsMenu.addAction(UIAlertAction(title: "Playback Speed", style: .default) { _ in self.showPlaybackSpeedMenu()})
        optionsMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentActionSheet(menu: optionsMenu)
    }

    func showPlaybackSpeedMenu(){
        let playbackSpeedMenu = createPlaybackSpeedMenu()
        presentActionSheet(menu: playbackSpeedMenu)
    }
    
    func createPlaybackSpeedMenu() -> UIAlertController {
        let playbackSpeedMenu = UIAlertController(title: "Playback Speed", message: nil, preferredStyle: .actionSheet)

        for playbackSpeed in PlaybackSpeed.allCases {
            let action = createActionForPlaybackSpeed(playbackSpeed)
            playbackSpeedMenu.addAction(action)
        }

        playbackSpeedMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        return playbackSpeedMenu
    }
    
    func createActionForPlaybackSpeed(_ playbackSpeed: PlaybackSpeed) -> UIAlertAction {
        let action = UIAlertAction(title: playbackSpeed.label, style: .default) { [weak self] _ in
            self?.player.changePlaybackSpeed(playbackSpeed)
        }

        if playbackSpeed == .normal && self.player.currentPlaybackSpeed.rawValue == 0.0 || (playbackSpeed.rawValue == self.player.currentPlaybackSpeed.rawValue) {
            action.setValue(UIImage(named: "checkmark", in: bundle, compatibleWith: nil), forKey: "image")
        }
        return action
    }
    
    func presentActionSheet(menu: UIAlertController) {
        let presentingViewController = self.findRelatedViewController()
        presentingViewController?.present(menu, animated: true, completion: nil)
    }
}
