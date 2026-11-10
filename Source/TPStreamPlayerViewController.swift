//
//  TPStreamPlayerUIKitView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 20/07/23.
//

import Foundation
import UIKit
import CoreMedia


public class TPStreamPlayerViewController: UIViewController {
    public var player: TPAVPlayer?{
        didSet {
            if let obs = playerTimeObserver, let oldPlayer = oldValue {
                oldPlayer.removeTimeObserver(obs)
                playerTimeObserver = nil
            }
            guard let player = player else { return }
            if isViewLoaded {
                handlePlayerInitializationError()
            }
            setupPlayerStatusObserver(for: player)
            setupPlayerTimeControlObserver(for: player)
            setupPlayerTimeObserver()
            showLiveStreamNotice()
            player.onError = { [weak self] error, sentryIssueId in
                self?.showError(error: error, sentryIssueId: sentryIssueId)
            }
        }
    }
    private var playerStatusObservation: NSKeyValueObservation?
    private var playerTimeControlObservation: NSKeyValueObservation?
    private var playerTimeObserver: Any?
    
    public var activeSubtitleTrack: SubtitleTrack? {
        didSet {
            guard activeSubtitleTrack != oldValue else { return }
            subtitleView.setTrack(activeSubtitleTrack)
            if isViewLoaded {
                controlsView.selectedSubtitleTrack = activeSubtitleTrack
                layoutContainerSubviews()
            }
            delegate?.onSubtitleStateChanged(enabled: activeSubtitleTrack != nil, language: activeSubtitleTrack?.language)
        }
    }

    /// Height of the bottom band reserved for subtitles, when captions are enabled
    /// and a track is selected. Otherwise no space is reserved.
    private var subtitleReservedHeight: CGFloat {
        config.enableCaptions && activeSubtitleTrack != nil ? SubtitleView.reservedBottomBandHeight : 0
    }
    
    public var delegate: TPStreamPlayerViewControllerDelegate?
    public var autoFullScreenOnRotate = true {
        didSet { updateDeviceOrientationObservation() }
    }
    public var config = TPStreamPlayerConfiguration(){
        didSet {
            controlsView.playerConfig = config
            textWatermarkOverlayView.setWatermarks(config.watermarks.compactMap { $0 as? TextWatermarkConfig })
            imageWatermarkOverlayView.setImageWatermarks(config.watermarks.compactMap { $0 as? ImageWatermarkConfig })
        }
    }
    private var controlsVisibilityTimer: Timer?
    private var fullscreenOverlay: FullscreenOverlayView?
    private var pendingFullscreenEntry = false
    private var hasAttachedPlayer = false
    private var deviceOrientationObserver: NSObjectProtocol?
    public private(set) var isFullScreen: Bool = false {
        didSet {
            controlsView.isFullScreen = isFullScreen
            subtitleView.isFullScreen = isFullScreen
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    override public var prefersStatusBarHidden: Bool {
        return isFullScreen
    }
    
    private lazy var videoView: TPVideoPlayerUIView = {
        let view = TPVideoPlayerUIView(frame: view.frame)
        view.backgroundColor = .black
        view.player = player
        view.onVideoRectChanged = { [weak self] rect in
            self?.textWatermarkOverlayView.setWatermarkContentRect(rect)
            self?.imageWatermarkOverlayView.setWatermarkContentRect(rect)
        }
        return view
    }()
    
    private lazy var controlsView: PlayerControlsUIView = {
        guard let view = bundle.loadNibNamed("PlayerControls", owner: nil, options: nil)?.first as? PlayerControlsUIView else {
            fatalError("Could not load PlayerControls view from nib.")
        }
        view.player = TPStreamPlayer(player: self.player!, userId: config.userId)
        view.playerConfig = config
        view.frame = view.bounds
        view.isHidden = true
        view.fullScreenToggleDelegate = self
        view.controlsDelegate = self
        view.parentViewController = self
        view.onSubtitleTrackSelected = { [weak self] track in
            self?.activeSubtitleTrack = track
        }
        return view
    }()
    
    private lazy var subtitleView: SubtitleView = {
        let view = SubtitleView(frame: .zero)
        return view
    }()
    
    private lazy var textWatermarkOverlayView = TextWatermarkOverlayView(frame: .zero)
    private lazy var imageWatermarkOverlayView = ImageWatermarkOverlayView(frame: .zero)
    
    private lazy var noticeView: UIView = {
        let view = UIView(frame: view.frame)
        view.isHidden = true
        view.backgroundColor = UIColor.black
        view.addSubview(noticeMessageLabel)
        return view
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView(frame: view.bounds)
        view.backgroundColor = .black
        view.addSubview(videoView)
        view.addSubview(textWatermarkOverlayView)
        view.addSubview(imageWatermarkOverlayView)
        view.addSubview(subtitleView)
        view.addSubview(controlsView)
        view.addSubview(noticeView)
        view.bringSubviewToFront(controlsView)
        return view
    }()
    
    private lazy var noticeMessageLabel: UILabel = {
        let messageLabel = UILabel(frame: view.frame)
        messageLabel.textAlignment = .center
        messageLabel.textColor = .white
        messageLabel.numberOfLines = 4
        return messageLabel
    }()
    
    deinit {
        if let observer = deviceOrientationObserver {
            NotificationCenter.default.removeObserver(observer)
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
        fullscreenOverlay?.removeFromSuperview()
        playerStatusObservation = nil
        playerTimeControlObservation = nil
        if let observer = playerTimeObserver, let player = player {
            player.removeTimeObserver(observer)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(containerView)
        // Flutter attaches the player view directly, without controller appearance callbacks.
        let attachmentView = WindowAttachmentView(frame: .zero)
        attachmentView.isUserInteractionEnabled = false
        attachmentView.onWindowChanged = { [weak self] in self?.playerWindowChanged() }
        view.addSubview(attachmentView)

        setupTapGesture()
        handlePlayerInitializationError()
        controlsView.selectedSubtitleTrack = activeSubtitleTrack
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if config.startInFullscreen && !isFullScreen {
            enterFullScreen()
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutContainerSubviews()
    }

    private func playerWindowChanged() {
        if view.window == nil {
            pendingFullscreenEntry = false
        }
        updateDeviceOrientationObservation()
        // Reparent the container after UIKit finishes propagating the window change.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let window = self.view.window
            if self.isFullScreen, window == nil || self.fullscreenOverlay?.window !== window {
                self.exitFullScreen()
            }
            guard window != nil, !self.isFullScreen else { return }
            let startInFullscreen = !self.hasAttachedPlayer && self.config.startInFullscreen
            self.hasAttachedPlayer = true
            if self.pendingFullscreenEntry || startInFullscreen {
                self.enterFullScreen()
            }
        }
    }

    private func updateDeviceOrientationObservation() {
        if autoFullScreenOnRotate && viewIfLoaded?.window != nil {
            guard deviceOrientationObserver == nil else { return }
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            deviceOrientationObserver = NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification, object: UIDevice.current, queue: .main
            ) { [weak self] _ in
                self?.deviceOrientationChanged()
            }
        } else if let observer = deviceOrientationObserver {
            NotificationCenter.default.removeObserver(observer)
            deviceOrientationObserver = nil
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
    }

    private func deviceOrientationChanged() {
        guard autoFullScreenOnRotate, let window = viewIfLoaded?.window, window.isKeyWindow,
              !view.isHidden, !window.isHidden else { return }

        let orientation = UIDevice.current.orientation
        if orientation == .portrait {
            if fullscreenOverlay?.openedAutomatically == true {
                exitFullScreen()
            }
        } else if orientation.isLandscape {
            let angle: CGFloat = orientation == .landscapeLeft ? .pi / 2 : -.pi / 2
            if let overlay = fullscreenOverlay {
                guard overlay.openedAutomatically, overlay.rotationAngle != angle else { return }
                overlay.rotationAngle = angle
                layoutContainerSubviews()
            } else {
                enterFullScreen(automatically: true, rotationAngle: angle)
            }
        }
    }

    private func layoutContainerSubviews() {
        var contentBounds: CGRect?
        if let overlay = fullscreenOverlay {
            let bounds = overlay.bounds
            let orientation = overlay.window?.windowScene?.interfaceOrientation
            let rotatesPlayer = orientation == nil || orientation == .unknown
                ? bounds.height > bounds.width
                : orientation?.isPortrait == true
            containerView.transform = rotatesPlayer ? CGAffineTransform(rotationAngle: overlay.rotationAngle) : .identity
            containerView.bounds.size = rotatesPlayer
                ? CGSize(width: bounds.height, height: bounds.width)
                : bounds.size
            containerView.center = CGPoint(x: bounds.midX, y: bounds.midY)

            if rotatesPlayer {
                let insets = overlay.safeAreaInsets
                let rotatedInsets = overlay.rotationAngle > 0
                    ? UIEdgeInsets(top: insets.right, left: insets.top, bottom: insets.left, right: insets.bottom)
                    : UIEdgeInsets(top: insets.left, left: insets.bottom, bottom: insets.right, right: insets.top)
                contentBounds = containerView.bounds.inset(by: rotatedInsets)
            }
        } else {
            containerView.frame = view.bounds
        }

        videoView.frame = containerView.bounds
        subtitleView.frame = contentBounds ?? containerView.bounds
        textWatermarkOverlayView.frame = containerView.bounds
        textWatermarkOverlayView.setWatermarkContentRect(videoView.videoRect)
        let subtitleBottomInset = containerView.bounds.maxY - subtitleView.frame.maxY
        textWatermarkOverlayView.setReservedBottomHeight(
            subtitleReservedHeight > 0 ? subtitleReservedHeight + subtitleBottomInset : 0
        )
        imageWatermarkOverlayView.frame = containerView.bounds
        imageWatermarkOverlayView.setWatermarkContentRect(videoView.videoRect)
        controlsView.frame = contentBounds ?? containerView.bounds
        noticeView.frame = containerView.bounds
        noticeMessageLabel.frame = contentBounds ?? noticeView.bounds
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let previousOrientation = view.window?.windowScene?.interfaceOrientation
        let wasFullScreen = isFullScreen
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            self.layoutContainerSubviews()
            guard self.autoFullScreenOnRotate, self.isFullScreen == wasFullScreen,
                  let window = self.view.window, !self.view.isHidden, !window.isHidden,
                  let orientation = window.windowScene?.interfaceOrientation,
                  orientation != previousOrientation else { return }
            if orientation.isLandscape {
                self.enterFullScreen(automatically: true)
            } else if orientation.isPortrait && previousOrientation?.isLandscape == true,
                      self.fullscreenOverlay?.openedAutomatically == true {
                self.exitFullScreen()
            }
        }
    }
    
    private func setupPlayerStatusObserver(for player: TPAVPlayer) {
        playerStatusObservation = player.observe(\.initializationStatus, options: [.new]) { [weak self] (_, change) in
            guard let self = self else { return }

            if let status = change.newValue {
                switch status {
                case "error":
                    let errorInfo = self.player!.initializationErrorContext!
                    self.showError(error: errorInfo.error, sentryIssueId: errorInfo.sentryIssueId)
                case "ready":
                    self.noticeView.isHidden = true
                    self.showLiveStreamNotice()
                    if self.config.autoSelectFirstSubtitle,
                       self.activeSubtitleTrack == nil,
                       let firstTrack = self.player?.asset?.video?.tracks.first {
                        self.activeSubtitleTrack = firstTrack
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func setupPlayerTimeControlObserver(for player: TPAVPlayer) {
        playerTimeControlObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            guard let self = self else { return }
            if player.timeControlStatus == .playing {
                self.textWatermarkOverlayView.resumeWatermarks()
            } else {
                self.textWatermarkOverlayView.pauseWatermarks()
            }
        }
        if player.timeControlStatus == .playing {
            textWatermarkOverlayView.resumeWatermarks()
        } else {
            textWatermarkOverlayView.pauseWatermarks()
        }
    }
    
    private func setupPlayerTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        playerTimeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.subtitleView.updateSubtitle(at: CMTimeGetSeconds(time))
        }
    }
    
    private func showLiveStreamNotice(){
        guard let player = player,
                  let liveStream = player.asset?.liveStream,
                  let noticeMessage = liveStream.noticeMessage else {
                return
            }
        
        if liveStream.transcodeRecordedVideo && player.asset?.video != nil {
            return
        }
        
        showNotice(withMessage: noticeMessage)
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleControlsVisibility))
        containerView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func toggleControlsVisibility() {
        controlsView.isHidden = !controlsView.isHidden
        imageWatermarkOverlayView.setControlsVisible(!controlsView.isHidden)
        
        // Hide controls view after 10 seconds
        if !controlsView.isHidden {
            controlsVisibilityTimer?.invalidate()
            controlsVisibilityTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
                self?.controlsView.isHidden = true
                self?.imageWatermarkOverlayView.setControlsVisible(false)
            }
        }
    }
    
    private func handlePlayerInitializationError() {
        guard let player = player, let errorContext = player.initializationErrorContext else { return }
        
        showError(error: errorContext.error, sentryIssueId: errorContext.sentryIssueId)
    }
    
    private func showError(error: Error, sentryIssueId: String?) {
        var message: String
        if let tpStreamPlayerError = error as? TPStreamPlayerError {
            message = "\(tpStreamPlayerError.message)\nError code: \(tpStreamPlayerError.code)"
        } else {
            message = error.localizedDescription
        }
        
        if let sentryIssueId = sentryIssueId {
            message += "\nPlayerId: \(sentryIssueId)"
        }
        
        showNotice(withMessage: message)
    }
    
    private func showNotice(withMessage message: String){
        noticeView.isHidden = false
        containerView.bringSubviewToFront(noticeView)
        noticeMessageLabel.text = message
    }
}


extension TPStreamPlayerViewController: FullScreenToggleDelegate, PlayerControlsDelegate {
    public func enterFullScreen() {
        enterFullScreen(automatically: false)
    }

    private func enterFullScreen(automatically: Bool, rotationAngle: CGFloat? = nil) {
        guard !isFullScreen else { return }
        guard let window = view.window else {
            pendingFullscreenEntry = true
            return
        }
        pendingFullscreenEntry = false
        hasAttachedPlayer = true

        delegate?.willEnterFullScreenMode()
        let overlay = FullscreenOverlayView(frame: window.bounds)
        overlay.openedAutomatically = automatically
        overlay.rotationAngle = rotationAngle ?? .pi / 2
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = .black
        overlay.onLayout = { [weak self] in self?.layoutContainerSubviews() }
        fullscreenOverlay = overlay
        window.addSubview(overlay)
        overlay.addSubview(containerView)
        isFullScreen = true
        layoutContainerSubviews()

        if rotationAngle == nil, let scene = window.windowScene,
           !scene.interfaceOrientation.isLandscape,
           !UIApplication.shared.supportedInterfaceOrientations(for: window).intersection(.landscape).isEmpty {
            overlay.requestedLandscape = true
            changeOrientation(orientation: .landscape, in: scene) { [weak overlay] _ in
                DispatchQueue.main.async {
                    overlay?.requestedLandscape = false
                }
            }
        }
        delegate?.didEnterFullScreenMode()
    }
    
    public func exitFullScreen() {
        pendingFullscreenEntry = false
        guard isFullScreen else { return }
        delegate?.willExitFullScreenMode()
        let scene = fullscreenOverlay?.window?.windowScene
        let requestedLandscape = fullscreenOverlay?.requestedLandscape == true

        containerView.transform = .identity
        view.addSubview(containerView)
        fullscreenOverlay?.removeFromSuperview()
        fullscreenOverlay = nil
        isFullScreen = false
        layoutContainerSubviews()

        if let scene, scene.interfaceOrientation.isLandscape || requestedLandscape {
            changeOrientation(orientation: .portrait, in: scene)
        }
        delegate?.didExitFullScreenMode()
    }
    
    private func changeOrientation(
        orientation: UIInterfaceOrientationMask,
        in scene: UIWindowScene,
        onError: ((Error) -> Void)? = nil
    ) {
        if #available(iOS 16.0, *) {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation), errorHandler: onError)
        } else {
            UIDevice.current.setValue(orientation.toUIInterfaceOrientation.rawValue, forKey: "orientation")
        }
    }

    func didTapReplay() {
        controlsView.player?.replay()
        delegate?.didTapReplay()
    }
}

public protocol TPStreamPlayerViewControllerDelegate {
    func willEnterFullScreenMode()
    func didEnterFullScreenMode()
    func willExitFullScreenMode()
    func didExitFullScreenMode()
    func didTapReplay()
    func onSubtitleStateChanged(enabled: Bool, language: String?)
}

public extension TPStreamPlayerViewControllerDelegate {
    func didTapReplay() {}
    func onSubtitleStateChanged(enabled: Bool, language: String?) {}
}

private final class WindowAttachmentView: UIView {
    var onWindowChanged: (() -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        onWindowChanged?()
    }
}

private final class FullscreenOverlayView: UIView {
    var openedAutomatically = false
    var rotationAngle: CGFloat = .pi / 2
    var requestedLandscape = false
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setNeedsLayout()
    }
}
