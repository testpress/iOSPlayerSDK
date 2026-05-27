//
//  TPStreamPlayerUIKitView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 20/07/23.
//

import Foundation
import UIKit


public class TPStreamPlayerViewController: UIViewController {
    public var player: TPAVPlayer?{
        didSet {
            guard let player = player else { return }
            if isViewLoaded {
                handlePlayerInitializationError()
            }
            setupPlayerStatusObserver(for: player)
            showLiveStreamNotice()
            player.onError = showError
        }
    }
    private var playerStatusObervervation: NSKeyValueObservation?
    public var delegate: TPStreamPlayerViewControllerDelegate?
    public var autoFullScreenOnRotate = true
    public var config = TPStreamPlayerConfiguration(){
        didSet {
            overlayView.playerConfig = config
        }
    }
    private var controlsVisibilityTimer: Timer?
    public private(set) var isFullScreen: Bool = false {
        didSet {
            overlayView.isFullScreen = isFullScreen
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
        return view
    }()
    
    private lazy var overlayView: PlayerOverlay = {
        guard let overlay = bundle.loadNibNamed("PlayerOverlay", owner: nil, options: nil)?.first as? PlayerOverlay else {
            fatalError("Could not load PlayerOverlay view from nib.")
        }
        overlay.player = TPStreamPlayer(player: self.player!)
        overlay.playerConfig = config
        overlay.frame = overlay.bounds
        overlay.controls.isHidden = true
        overlay.fullScreenToggleDelegate = self
        overlay.controlsDelegate = self
        overlay.parentViewController = self
        return overlay
    }()
    
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
        view.addSubview(overlayView)
        view.addSubview(noticeView)
        view.bringSubviewToFront(overlayView)
        return view
    }()
    
    private lazy var noticeMessageLabel: UILabel = {
        let messageLabel = UILabel(frame: view.frame)
        messageLabel.textAlignment = .center
        messageLabel.textColor = .white
        messageLabel.numberOfLines = 4
        return messageLabel
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(containerView)
        
        setupTapGesture()
        handlePlayerInitializationError()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if config.startInFullscreen && !isFullScreen {
            enterFullScreen()
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        containerView.frame = containerView.superview!.bounds
        videoView.frame = containerView.bounds
        overlayView.frame = containerView.bounds
        noticeView.frame = containerView.bounds
        noticeMessageLabel.frame = noticeView.bounds
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        guard autoFullScreenOnRotate else { return }
        if containerView.getCurrentOrientation().isLandscape {
            enterFullScreen()
        } else {
            exitFullScreen()
        }
    }
    
    private func setupPlayerStatusObserver(for player: TPAVPlayer) {
        playerStatusObervervation = player.observe(\.initializationStatus, options: [.new]) { [weak self] (_, change) in
            guard let self = self else { return }

            if let status = change.newValue {
                switch status {
                case "error":
                    let errorInfo = self.player!.initializationErrorContext!
                    self.showError(error: errorInfo.error, sentryIssueId: errorInfo.sentryIssueId)
                case "ready":
                    self.noticeView.isHidden = true
                    self.showLiveStreamNotice()
                default:
                    break
                }
            }
        }
    }
    
    private func showLiveStreamNotice(){
        guard let player = player,
                  let liveStream = player.asset?.liveStream,
                  let noticeMessage = liveStream.noticeMessage else {
                return
            }
        
        showNotice(withMessage: noticeMessage)
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleControlsVisibility))
        containerView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func toggleControlsVisibility() {
        overlayView.controls.isHidden = !overlayView.controls.isHidden
        
        // Hide controls container after 10 seconds
        if !overlayView.controls.isHidden {
            controlsVisibilityTimer?.invalidate()
            controlsVisibilityTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
                self?.overlayView.controls.isHidden = true
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
        delegate?.willEnterFullScreenMode()
        changeOrientation(orientation: .landscape)
        resizeContainerToWindow()
        delegate?.didEnterFullScreenMode()
    }
    
    public func exitFullScreen() {
        delegate?.willExitFullScreenMode()
        changeOrientation(orientation: .portrait)
        resizeContainerToParentView()
        delegate?.didExitFullScreenMode()
    }
    
    func resizeContainerToWindow(){
        if let window = UIApplication.shared.keyWindow{
            containerView.removeFromSuperview()
            window.addSubview(containerView)
            containerView.frame = window.bounds
            isFullScreen = true
        }
    }
    
    func resizeContainerToParentView(){
        containerView.removeFromSuperview()
        view.addSubview(containerView)
        containerView.frame = view.bounds
        isFullScreen = false
    }
    
    func changeOrientation(orientation: UIInterfaceOrientationMask) {
        if #available(iOS 16.0, *) {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
        } else {
            UIDevice.current.setValue(orientation.toUIInterfaceOrientation.rawValue, forKey: "orientation")
        }
    }

    func didTapReplay() {
        overlayView.player?.replay()
        delegate?.didTapReplay()
    }
}

public protocol TPStreamPlayerViewControllerDelegate {
    func willEnterFullScreenMode()
    func didEnterFullScreenMode()
    func willExitFullScreenMode()
    func didExitFullScreenMode()
    func didTapReplay()
}

public extension TPStreamPlayerViewControllerDelegate {
    func didTapReplay() {}
}
