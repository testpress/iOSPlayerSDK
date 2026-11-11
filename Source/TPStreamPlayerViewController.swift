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
            player.onError = showError
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
                textWatermarkOverlayView.setReservedBottomHeight(subtitleReservedHeight)
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
    public var autoFullScreenOnRotate = true
    public var config = TPStreamPlayerConfiguration(){
        didSet {
            controlsView.playerConfig = config
            textWatermarkOverlayView.setWatermarks(config.watermarks.compactMap { $0 as? TextWatermarkConfig })
            imageWatermarkOverlayView.setImageWatermarks(config.watermarks.compactMap { $0 as? ImageWatermarkConfig })
        }
    }
    private var controlsVisibilityTimer: Timer?
    private weak var fullScreenViewController: TPStreamFullScreenViewController?
    private var orientationObserver: Any?
    private var lastDeviceOrientation: UIDeviceOrientation = .unknown
    private var isPresentingFullScreen = false
    private var isManualFullScreen = false
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
        if let observer = orientationObserver {
            NotificationCenter.default.removeObserver(observer)
            orientationObserver = nil
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
        if let fullScreenVC = fullScreenViewController {
            let dismisser = fullScreenVC.presentingViewController ?? fullScreenVC
            dismisser.dismiss(animated: false)
        }
        playerStatusObservation = nil
        playerTimeControlObservation = nil
        if let observer = playerTimeObserver, let player = player {
            player.removeTimeObserver(observer)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(containerView)
        
        setupTapGesture()
        setupOrientationObserver()
        handlePlayerInitializationError()
        controlsView.selectedSubtitleTrack = activeSubtitleTrack
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if config.startInFullscreen && !isFullScreen {
            enterFullScreen()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isFullScreen && !isPresentingFullScreen && (isMovingFromParent || isBeingDismissed || navigationController?.isBeingDismissed == true) {
            exitFullScreen()
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutContainerSubviews()
    }

    private func layoutContainerSubviews() {
        containerView.frame = containerView.superview!.bounds
        videoView.frame = containerView.bounds
        subtitleView.frame = containerView.bounds
        textWatermarkOverlayView.frame = containerView.bounds
        textWatermarkOverlayView.setWatermarkContentRect(videoView.videoRect)
        textWatermarkOverlayView.setReservedBottomHeight(subtitleReservedHeight)
        imageWatermarkOverlayView.frame = containerView.bounds
        imageWatermarkOverlayView.setWatermarkContentRect(videoView.videoRect)
        controlsView.frame = containerView.bounds
        noticeView.frame = containerView.bounds
        noticeMessageLabel.frame = noticeView.bounds
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.layoutContainerSubviews()
        })
    }

    private func setupOrientationObserver() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleDeviceOrientationChange()
        }
    }

    private func handleDeviceOrientationChange() {
        guard autoFullScreenOnRotate else { return }
        let isVisible = isFullScreen ? (fullScreenViewController?.view.window != nil) : (isViewLoaded && view.window != nil)
        guard isVisible else { return }

        let currentOrientation = UIDevice.current.orientation
        guard currentOrientation == .portrait || currentOrientation == .landscapeLeft || currentOrientation == .landscapeRight else { return }
        guard currentOrientation != lastDeviceOrientation else { return }
        lastDeviceOrientation = currentOrientation
        
        if currentOrientation == .landscapeLeft || currentOrientation == .landscapeRight {
            if isFullScreen {
                isManualFullScreen = false
            } else if !isManualFullScreen {
                enterFullScreen()
            }
        } else if currentOrientation == .portrait {
            if isFullScreen {
                if !isManualFullScreen {
                    exitFullScreen()
                }
            } else {
                isManualFullScreen = false
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
    private var currentWindowScene: UIWindowScene? {
        if let scene = view.window?.windowScene {
            return scene
        }
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
    }

    private var topMostViewController: UIViewController? {
        let root = view.window?.rootViewController
            ?? currentWindowScene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? self.parent
            ?? self
        var top: UIViewController = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    public func enterFullScreen() {
        enterFullScreen(retryCount: 0)
    }

    private func enterFullScreen(retryCount: Int) {
        guard !isFullScreen, !isPresentingFullScreen else { return }
        guard let presenter = topMostViewController, presenter.view.window != nil else { return }
        if presenter.isBeingPresented || presenter.isBeingDismissed {
            guard retryCount < 3 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.enterFullScreen(retryCount: retryCount + 1)
            }
            return
        }

        if !UIDevice.current.orientation.isLandscape {
            isManualFullScreen = true
        }

        lastDeviceOrientation = UIDevice.current.orientation
        delegate?.willEnterFullScreenMode()

        let fullScreenVC = TPStreamFullScreenViewController()
        fullScreenVC.modalPresentationStyle = .fullScreen
        fullScreenVC.targetOrientation = targetLandscapeOrientation(for: UIDevice.current.orientation)
        fullScreenVC.onLayout = { [weak self] in
            self?.layoutContainerSubviews()
        }
        self.fullScreenViewController = fullScreenVC

        containerView.removeFromSuperview()
        fullScreenVC.view.addSubview(containerView)
        containerView.frame = fullScreenVC.view.bounds
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controlsView.parentViewController = fullScreenVC

        isPresentingFullScreen = true
        presenter.present(fullScreenVC, animated: false) { [weak self] in
            guard let self = self else { return }
            self.isPresentingFullScreen = false
            self.isFullScreen = true
            let isStillPortrait = self.currentWindowScene?.interfaceOrientation.isPortrait ?? UIApplication.shared.statusBarOrientation.isPortrait
            if isStillPortrait {
                self.changeOrientation(orientation: fullScreenVC.targetOrientation)
            }
            self.layoutContainerSubviews()
            self.delegate?.didEnterFullScreenMode()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.rollbackFullScreenPresentationStateIfNeeded()
        }
    }

    private func rollbackFullScreenPresentationStateIfNeeded() {
        guard isPresentingFullScreen,
              fullScreenViewController?.presentingViewController == nil,
              fullScreenViewController?.isBeingPresented != true else { return }
        isPresentingFullScreen = false
        containerView.removeFromSuperview()
        view.addSubview(containerView)
        containerView.frame = view.bounds
        controlsView.parentViewController = self
        fullScreenViewController = nil
        layoutContainerSubviews()
    }

    private func targetLandscapeOrientation(for deviceOrientation: UIDeviceOrientation) -> UIInterfaceOrientationMask {
        switch deviceOrientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .landscapeRight
        }
    }

    public func exitFullScreen() {
        guard isFullScreen else { return }

        if UIDevice.current.orientation.isLandscape {
            isManualFullScreen = true
        }

        lastDeviceOrientation = UIDevice.current.orientation
        delegate?.willExitFullScreenMode()

        guard let fullScreenVC = self.fullScreenViewController else {
            cleanupFullScreenHierarchy()
            changeOrientation(orientation: .portrait, animated: false)
            return
        }

        if let presented = fullScreenVC.presentedViewController {
            presented.dismiss(animated: false)
        }

        let dismisser = fullScreenVC.presentingViewController ?? fullScreenVC
        UIView.performWithoutAnimation {
            dismisser.dismiss(animated: false) { [weak self] in
                guard let self = self else { return }
                self.changeOrientation(orientation: .portrait, animated: false)
                self.cleanupFullScreenHierarchy()
            }
        }
    }

    private func cleanupFullScreenHierarchy() {
        containerView.removeFromSuperview()
        view.addSubview(containerView)
        containerView.frame = view.bounds
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controlsView.parentViewController = self
        fullScreenViewController = nil
        isFullScreen = false
        layoutContainerSubviews()
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didExitFullScreenMode()
        }
    }

    func changeOrientation(orientation: UIInterfaceOrientationMask, animated: Bool = true) {
        if #available(iOS 16.0, *) {
            guard let scene = currentWindowScene else { return }
            if animated {
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation)) { error in
                    print("[TPStreamsSDK] requestGeometryUpdate failed: \(error.localizedDescription)")
                }
            } else {
                UIView.performWithoutAnimation {
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation)) { error in
                        print("[TPStreamsSDK] requestGeometryUpdate failed: \(error.localizedDescription)")
                    }
                    CATransaction.commit()
                }
            }
        } else {
            UIDevice.current.setValue(orientation.toUIInterfaceOrientation.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
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
