//
//  PlayerControlsUIKitView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 20/07/23.
//

import Foundation
import UIKit

let ACTION_SHEET_PREFERRED_STYLE: UIAlertController.Style  = UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet

class PlayerControlsUIView: UIView, UIAdaptivePresentationControllerDelegate {
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var currentTimelabel: UILabel!
    @IBOutlet weak var videoDurationLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var fullScreenToggleButton: UIButton!
    @IBOutlet weak var progressBar: ProgressBar!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var rewindSeekNoticeLabel: UILabel!
    @IBOutlet weak var forwardSeekNoticeLabel: UILabel!
    
    @IBOutlet weak var liveIndicatorContainer: UIView!

    private lazy var liveIndicatorView: LiveIndicatorView = {
        let indicatorView = LiveIndicatorView(frame: liveIndicatorContainer.bounds)
        return indicatorView
    }()
    
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
            fullScreenToggleButton.isHidden = !playerConfig.enableFullscreen
            forwardButton.isHidden = !playerConfig.enableSeekButtons
            rewindButton.isHidden = !playerConfig.enableSeekButtons
            settingsButton.isHidden = !playerConfig.showSettingsButton
        }
    }
    
    weak var parentViewController: UIViewController?
    private var settingsWindow: UIWindow?
    var selectedSubtitleTrack: SubtitleTrack?
    var onSubtitleTrackSelected: ((SubtitleTrack?) -> Void)?
    weak var fullScreenToggleDelegate: FullScreenToggleDelegate?
    weak var controlsDelegate: PlayerControlsDelegate?
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
            if player.isLive {
                liveIndicatorView.isBehindLiveEdge = player.isBehindLiveEdge
            }
        } else if keyPath == #keyPath(TPStreamPlayer.isVideoDurationInitialized) && player.isVideoDurationInitialized {
            videoDurationLabel.text = timeStringFromSeconds(player.playableDuration)
        }
    }
    
    private func handlePlayerStatusChange(){
        switch player.status {
        case "ready":
            if (player.isLive){
                setUpLiveIndicator()
            }
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
    
    private func setUpLiveIndicator() {
        videoDurationLabel.isHidden = true
        liveIndicatorContainer.isHidden = false
        
        liveIndicatorContainer.addSubview(liveIndicatorView)
        setupLiveIndicatorTapGesture()
    }
    
    private func setupLiveIndicatorTapGesture() {
        var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleLiveLabelTap))
        liveIndicatorContainer.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func handleLiveLabelTap() {
        if let player = player, player.isBehindLiveEdge == true {
            player.goTo(seconds: player.playableDuration)
        }
    }
    
    @IBAction func playOrPauseButton(_ sender: Any) {
        if player.status == "paused" {
            player.play()
        } else if player.status == "ended" {
            controlsDelegate?.didTapReplay()
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
        var optionsMenu = SettingsMenuDefinition(title: nil, message: nil)

        if playerConfig.enablePlaybackSpeed {
            optionsMenu.options.append(SettingsOption(title: "Playback Speed") { [weak self] in
                self?.showPlaybackSpeedMenu()
            })
        }

        if playerConfig.enableCaptions, let tracks = player.asset?.video?.tracks, !tracks.isEmpty {
            optionsMenu.options.append(SettingsOption(title: "Captions") { [weak self] in
                self?.showCaptionsMenu()
            })
        }

        if !player.player.isPlaybackOffline {
            addOnlinePlaybackButtons(to: &optionsMenu)
        }
        presentSettingsMenu(optionsMenu)
    }

    private func showCaptionsMenu() {
        guard let captionsMenu = createCaptionsMenu() else { return }
        presentSettingsMenu(captionsMenu)
    }

    private func createCaptionsMenu() -> SettingsMenuDefinition? {
        guard let tracks = player.asset?.video?.tracks else { return nil }
        var captionsMenu = SettingsMenuDefinition(title: "Captions", message: nil)

        captionsMenu.options.append(createActionForCaptionTrack(nil))

        for track in tracks {
            let action = createActionForCaptionTrack(track)
            captionsMenu.options.append(action)
        }

        return captionsMenu
    }

    private func createActionForCaptionTrack(_ track: SubtitleTrack?) -> SettingsOption {
        let title = track?.displayName ?? "Off"
        var action = SettingsOption(title: title) { [weak self] in
            self?.selectedSubtitleTrack = track
            self?.onSubtitleTrackSelected?(track)
        }
        if track?.url == selectedSubtitleTrack?.url {
            action.selected = true
        }
        return action
    }

    private func addOnlinePlaybackButtons(to menu: inout SettingsMenuDefinition) {
        if playerConfig.showResolutionOptions {
            menu.options.append(SettingsOption(title: "Video Quality") { [weak self] in
                self?.showVideoQualityMenu()
            })
        }

        if playerConfig.showDownloadOption {
            menu.options.append(SettingsOption(title: "Download") { [weak self] in
                self?.showDownloadQualityMenu()
            })
        }
    }

    private func showPlaybackSpeedMenu(){
        let playbackSpeedMenu = createPlaybackSpeedMenu()
        presentSettingsMenu(playbackSpeedMenu)
    }

    private func showVideoQualityMenu(){
        let videoQualityMenu = createVideoQualityMenu()
        presentSettingsMenu(videoQualityMenu)
    }

    private func showDownloadQualityMenu(){
        let downloadQualityMenu = createDownloadQualityMenu()
        presentSettingsMenu(downloadQualityMenu)
    }

    private func createPlaybackSpeedMenu() -> SettingsMenuDefinition {
        var playbackSpeedMenu = SettingsMenuDefinition(title: "Playback Speed", message: nil)

        for playbackSpeed in PlaybackSpeed.allCases {
            let action = createActionForPlaybackSpeed(playbackSpeed)
            playbackSpeedMenu.options.append(action)
        }

        return playbackSpeedMenu
    }

    private func createVideoQualityMenu() -> SettingsMenuDefinition {
        var qualityMenu = SettingsMenuDefinition(title: "Available resolutions", message: "Video quality adjusts based on your internet speed. Your selection sets the highest possible quality.")
        for quality in self.player.availableVideoQualities {
            let action = createActionForVideoQuality(quality)
            qualityMenu.options.append(action)
        }
        return qualityMenu
    }

    private func createDownloadQualityMenu() -> SettingsMenuDefinition {
        var qualityMenu = SettingsMenuDefinition(title: "Available resolutions", message: nil)
        for quality in player.availableVideoQualities.dropFirst() {
            let action = createActionForDownload(quality)
            qualityMenu.options.append(action)
        }
        return qualityMenu
    }

    private func createActionForPlaybackSpeed(_ playbackSpeed: PlaybackSpeed) -> SettingsOption {
        var action = SettingsOption(title: playbackSpeed.label) { [weak self] in
            self?.player.changePlaybackSpeed(playbackSpeed)
        }

        if playbackSpeed == .normal && self.player.currentPlaybackSpeed.rawValue == 0.0 || (playbackSpeed.rawValue == self.player.currentPlaybackSpeed.rawValue) {
            action.selected = true
        }
        return action
    }

    private func createActionForVideoQuality(_ quality: VideoQuality) -> SettingsOption {
        let label = VideoQualityUtils.getDisplayLabel(for: quality)
        var action = SettingsOption(title: label, handler: { [weak self] in
            self?.player.changeVideoQuality(quality)
        })

        if (quality.bitrate == player.currentVideoQuality?.bitrate) {
            action.selected = true
        }

        return action
    }

    private func createActionForDownload(_ quality: VideoQuality) -> SettingsOption {
        let action = SettingsOption(title: quality.resolution, handler: { [weak self] in
            guard let self, let asset = self.player.asset else { return }
            do {
                try TPStreamsDownloadManager.shared.enqueueDownload(
                    asset: asset,
                    accessToken: self.player.player.accessToken,
                    videoQuality: quality,
                    metadata: self.playerConfig.downloadMetadata,
                    offlineLicenseDurationSeconds: self.playerConfig.licenseDurationSeconds
                )
            } catch {
                print("Error downloading video: \(error)")
            }
        })

        return action
    }

    private func presentSettingsMenu(_ definition: SettingsMenuDefinition) {
        let alert = UIAlertController(
            title: definition.title, message: definition.message, preferredStyle: ACTION_SHEET_PREFERRED_STYLE
        )
        let rotatedWindow = makeRotatedSettingsWindow()
        for option in definition.options {
            let action = UIAlertAction(title: option.title, style: .default) { [weak self, weak rotatedWindow] _ in
                if let rotatedWindow {
                    self?.dismissSettingsMenu(in: rotatedWindow)
                }
                option.handler()
            }
            if option.selected {
                action.setValue(UIImage(named: "checkmark", in: bundle, compatibleWith: nil), forKey: "image")
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self, weak rotatedWindow] _ in
            if let rotatedWindow {
                self?.dismissSettingsMenu(in: rotatedWindow)
            }
        })

        if let rotatedWindow {
            rotatedWindow.rootViewController?.present(alert, animated: true)
            alert.presentationController?.delegate = self
        } else {
            parentViewController?.present(alert, animated: true)
        }
    }

    private func makeRotatedSettingsWindow() -> UIWindow? {
        guard isFullScreen, let container = superview, !container.transform.isIdentity,
              let playerWindow = container.window, let scene = playerWindow.windowScene else { return nil }

        dismissSettingsMenu()
        let window = UIWindow(windowScene: scene)
        window.windowLevel = UIWindow.Level(rawValue: playerWindow.windowLevel.rawValue + 1)
        window.overrideUserInterfaceStyle = container.traitCollection.userInterfaceStyle
        window.tintColor = container.tintColor
        let presenter = UIViewController()
        presenter.view.backgroundColor = .clear
        window.rootViewController = presenter
        settingsWindow = window
        updateSettingsMenuGeometry()
        // Keep the player window key so it continues receiving physical rotation events.
        window.isHidden = false
        return window
    }

    func updateSettingsMenuGeometry() {
        guard let settingsWindow, let container = superview, let playerWindow = container.window else { return }
        settingsWindow.bounds.size = container.bounds.size
        settingsWindow.center = playerWindow.center
        settingsWindow.transform = container.transform
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if let window = presentationController.presentingViewController.viewIfLoaded?.window {
            dismissSettingsMenu(in: window)
        }
    }

    private func dismissSettingsMenu(in window: UIWindow) {
        guard settingsWindow === window else { return }
        dismissSettingsMenu()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            dismissSettingsMenu()
        }
    }

    func dismissSettingsMenu() {
        settingsWindow?.isHidden = true
        settingsWindow = nil
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

protocol PlayerControlsDelegate: AnyObject {
    func didTapReplay()
}

protocol FullScreenToggleDelegate: AnyObject {
    func enterFullScreen()
    func exitFullScreen()
}

private struct SettingsMenuDefinition {
    let title: String?
    let message: String?
    var options: [SettingsOption] = []
}

private struct SettingsOption {
    let title: String
    var selected = false
    let handler: () -> Void
}
