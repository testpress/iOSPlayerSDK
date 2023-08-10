//
//  TPStreamPlayerUIKitView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 20/07/23.
//

import Foundation
import UIKit


public class TPStreamPlayerViewController: UIViewController {
    public var player: TPAVPlayer?
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
        view.frame = view.bounds
        view.isHidden = true
        view.fullScreenToggleDelegate = self
        view.parentViewController = self
        return view
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView(frame: view.bounds)
        view.backgroundColor = .black
        view.addSubview(videoView)
        view.addSubview(controlsView)
        view.bringSubviewToFront(controlsView)
        return view
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
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
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
}


extension TPStreamPlayerViewController: FullScreenToggleDelegate {
    func enterFullScreen() {
        changeOrientation(orientation: .landscape)
        resizeContainerToWindow()
    }
    
    func exitFullScreen() {
        changeOrientation(orientation: .portrait)
        resizeContainerToParentView()
    }
    
    func resizeContainerToWindow(){
        if let window = UIApplication.shared.keyWindow{
            containerView.removeFromSuperview()
            window.addSubview(containerView)
            containerView.frame = view.bounds
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
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        }
    }
}
