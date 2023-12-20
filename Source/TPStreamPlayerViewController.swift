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

            if let initializationError = player.initializationError {
                showError(error: initializationError)
            }
            player.onError = showError
        }
    }
    public var delegate: TPStreamPlayerViewControllerDelegate?
    public var autoFullScreenOnRotate = true
    public var config = TPStreamPlayerConfiguration(){
        didSet {
            controlsView.playerConfig = config
        }
    }
    private var controlsVisibilityTimer: Timer?
    private var isFullScreen: Bool = false {
        didSet {
            controlsView.isFullScreen = isFullScreen
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
    
    private lazy var controlsView: PlayerControlsUIView = {
        guard let view = bundle.loadNibNamed("PlayerControls", owner: nil, options: nil)?.first as? PlayerControlsUIView else {
            fatalError("Could not load PlayerControls view from nib.")
        }
        view.player = TPStreamPlayer(player: self.player!)
        view.playerConfig = config
        view.frame = view.bounds
        view.isHidden = true
        view.fullScreenToggleDelegate = self
        view.parentViewController = self
        return view
    }()
    
    private lazy var errorView: UIView = {
        let view = UIView(frame: view.frame)
        view.isHidden = true
        view.backgroundColor = UIColor.black
        view.addSubview(errorMessageLabel)
        return view
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView(frame: view.bounds)
        view.backgroundColor = .black
        view.addSubview(videoView)
        view.addSubview(controlsView)
        view.addSubview(errorView)
        view.bringSubviewToFront(controlsView)
        return view
    }()
    
    private lazy var errorMessageLabel: UILabel = {
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
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        containerView.frame = containerView.superview!.bounds
        videoView.frame = containerView.bounds
        controlsView.frame = containerView.bounds
        errorView.frame = containerView.bounds
        errorMessageLabel.frame = errorView.bounds
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
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleControlsVisibility))
        containerView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func toggleControlsVisibility() {
        controlsView.isHidden = !controlsView.isHidden
        
        // Hide controls view after 10 seconds
        if !controlsView.isHidden {
            controlsVisibilityTimer?.invalidate()
            controlsVisibilityTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
                self?.controlsView.isHidden = true
            }
        }
    }
    
    private func showError(error: Error){
        errorView.isHidden = false
        containerView.bringSubviewToFront(errorView)
        if let tpStreamPlayerError = error as? TPStreamPlayerError {
            errorMessageLabel.text = "\(tpStreamPlayerError.message)\nError code: \(tpStreamPlayerError.code)"
        } else {
            errorMessageLabel.text = error.localizedDescription
        }
    }
}


extension TPStreamPlayerViewController: FullScreenToggleDelegate {
    func enterFullScreen() {
        delegate?.willEnterFullScreenMode()
        changeOrientation(orientation: .landscape)
        resizeContainerToWindow()
        delegate?.didEnterFullScreenMode()
    }
    
    func exitFullScreen() {
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
}

public protocol TPStreamPlayerViewControllerDelegate {
    func willEnterFullScreenMode()
    func didEnterFullScreenMode()
    func willExitFullScreenMode()
    func didExitFullScreenMode()
}
