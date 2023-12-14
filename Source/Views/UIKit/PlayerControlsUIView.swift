//
//  PlayerControlsUIKitView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 20/07/23.
//

import Foundation
import UIKit

let ACTION_SHEET_PREFERRED_STYLE: UIAlertController.Style  = UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet

class PlayerControlsUIView: UIView {
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var currentTimelabel: UILabel!
    @IBOutlet weak var videoDurationLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var fullScreenToggleButton: UIButton!
    @IBOutlet weak var progressBar: ProgressBar!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var rewindSeekNoticeLabel: UILabel!
    @IBOutlet weak var forwardSeekNoticeLabel: UILabel!
    
    var player: TPStreamPlayer! {
        didSet {
            progressBar.player = player
            player.addObserver(self, forKeyPath: #keyPath(TPStreamPlayer.status), options: .new, context: nil)
            player.addObserver(self, forKeyPath: #keyPath(TPStreamPlayer.currentTime), options: .new, context: nil)
            player.addObserver(self, forKeyPath: #keyPath(TPStreamPlayer.isVideoDurationInitialized), options: .new, context: nil)
        }
    }
    var playerConfig: TPStreamPlayerConfiguration!{
        didSet {
            progressBar.watchedProgressTrackColor = playerConfig.watchedProgressTrackColor
            progressBar.progressBarThumbColor = playerConfig.progressBarThumbColor
        }
    }
    
    var parentViewController: UIViewController?
    var fullScreenToggleDelegate: FullScreenToggleDelegate?
    var isFullScreen: Bool = false {
        didSet {
           updateFullScreenButtonIcon()
           progressBar.setNeedsDisplay()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(TPStreamPlayer.status) {
            handlePlayerStatusChange()
        } else if keyPath == #keyPath(TPStreamPlayer.currentTime) && player.isVideoDurationInitialized {
            currentTimelabel.text = timeStringFromSeconds(player.currentTime.doubleValue)
        } else if keyPath == #keyPath(TPStreamPlayer.isVideoDurationInitialized) && player.isVideoDurationInitialized {
            videoDurationLabel.text = timeStringFromSeconds(player.videoDuration)
        }
    }
    
    private func handlePlayerStatusChange(){
        switch player.status {
        case "playing":
            playPauseButton.setImage(UIImage(named: "pause", in: bundle, compatibleWith: nil), for: .normal)
        case "paused":
            playPauseButton.setImage(UIImage(named: "play", in: bundle, compatibleWith: nil), for: .normal)
        case "ended":
            playPauseButton.setImage(UIImage(named: "reload", in: bundle, compatibleWith: nil), for: .normal)
        case "buffering":
            playPauseButton.isHidden = true
            loadingIndicator.startAnimating()
        default:
            break
        }
        
        if (player.status != "buffering"){
            playPauseButton.isHidden = false
            loadingIndicator.stopAnimating()
        }
        forwardButton.isEnabled = player.status != "ended"
    }
    
    @IBAction func playOrPauseButton(_ sender: Any) {
        if player.status == "paused" {
            player.play()
        } else if player.status == "ended" {
            player.goTo(seconds: 0.0)
            player.play()
        } else {
            player.pause()
        }
    }
    
    @IBAction func rewind(_ sender: UIButton) {
        let rewindDuration = playerConfig.preferredRewindDuration
        player.rewind(rewindDuration)
        animateSeekNoticeWithDuration(rewindDuration, label: rewindSeekNoticeLabel, isForward: false)
    }
    
    @IBAction func forward(_ sender: Any) {
        let forwardDuration = playerConfig.preferredForwardDuration
        player.forward(forwardDuration)
        animateSeekNoticeWithDuration(forwardDuration, label: forwardSeekNoticeLabel, isForward: true)
    }
    
    private func animateSeekNoticeWithDuration(_ duration: TimeInterval, label: UILabel, isForward: Bool) {
        label.isHidden = false
        label.text = isForward ? "+\(Int(duration))s" : "-\(Int(duration))s"
        
        UIView.animate(withDuration: 0.5, animations: {
            label.transform = CGAffineTransform(translationX: isForward ? 12 : -12, y: 0)
            label.alpha = 1.0
        }, completion: { _ in
            label.isHidden = true
            label.transform = .identity
            label.alpha = 0.0
        })
    }
    
    @IBAction func showOptionsMenu(_ sender: Any) {
        let optionsMenu = UIAlertController(title: nil, message: nil, preferredStyle: ACTION_SHEET_PREFERRED_STYLE)
        optionsMenu.addAction(UIAlertAction(title: "Playback Speed", style: .default) { _ in self.showPlaybackSpeedMenu()})
        optionsMenu.addAction(UIAlertAction(title: "Video Quality", style: .default, handler: { action in self.showVideoQualityMenu()}))
        optionsMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        parentViewController?.present(optionsMenu, animated: true, completion: nil)
    }

    func showPlaybackSpeedMenu(){
        let playbackSpeedMenu = createPlaybackSpeedMenu()
        parentViewController?.present(playbackSpeedMenu, animated: true, completion: nil)
    }
    
    func showVideoQualityMenu(){
        let videoQualityMenu = createVideoQualityMenu()
        parentViewController?.present(videoQualityMenu, animated: true, completion: nil)
    }
    
    func createPlaybackSpeedMenu() -> UIAlertController {
        let playbackSpeedMenu = UIAlertController(title: "Playback Speed", message: nil, preferredStyle: ACTION_SHEET_PREFERRED_STYLE)

        for playbackSpeed in PlaybackSpeed.allCases {
            let action = createActionForPlaybackSpeed(playbackSpeed)
            playbackSpeedMenu.addAction(action)
        }

        playbackSpeedMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        return playbackSpeedMenu
    }
    
    func createVideoQualityMenu() -> UIAlertController {
        let qualityMenu = UIAlertController(title: "Available resolutions", message: nil, preferredStyle: ACTION_SHEET_PREFERRED_STYLE)
        for quality in self.player.availableVideoQualities {
            let action = createActionForVideoQuality(quality)
            qualityMenu.addAction(action)
        }
        qualityMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        return qualityMenu
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
    
    func createActionForVideoQuality(_ quality: VideoQuality) -> UIAlertAction {
        let action = UIAlertAction(title: quality.resolution, style: .default, handler: { (_) in
            self.player.changeVideoQuality(quality)
        })
        
        if (quality.bitrate == player.currentVideoQuality?.bitrate) {
            action.setValue(UIImage(named: "checkmark", in: bundle, compatibleWith: nil), forKey: "image")
        }
        
        return action
    }
        
    @IBAction func toggleFullScreen(_ sender: Any) {
        if isFullScreen {
            fullScreenToggleDelegate?.exitFullScreen()
        } else {
            fullScreenToggleDelegate?.enterFullScreen()
        }
    }
    
    func updateFullScreenButtonIcon(){
        if isFullScreen {
            fullScreenToggleButton.setImage(UIImage(named: "minimize", in: bundle, compatibleWith: nil), for: .normal)
        } else{
            fullScreenToggleButton.setImage(UIImage(named: "maximize", in: bundle, compatibleWith: nil), for: .normal)
        }
    }
}

protocol FullScreenToggleDelegate {
    func enterFullScreen()
    func exitFullScreen()
}
