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
            playerControlsView.isFullScreen = isFullScreen
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    override public var prefersStatusBarHidden: Bool {
        return isFullScreen
    }
    
    private lazy var videoView: TPVideoPlayerUIView = {
        let playerView = TPVideoPlayerUIView(frame: view.frame)
        playerView.backgroundColor = .black
        playerView.player = player
        return playerView
    }()
    
    private lazy var controlsView: PlayerControlsUIView = {
        guard let playerControlsView = bundle.loadNibNamed("PlayerControls", owner: nil, options: nil)?.first as? PlayerControlsUIView else {
                    fatalError("Could not load PlayerControls view from nib.")
                }
        playerControlsView.player = TPStreamPlayer(player: self.player!)
        playerControlsView.frame = view.bounds
        playerControlsView.isHidden = true
        playerControlsView.fullScreenToggleDelegate = self
        return playerControlsView
    }()
    
    private lazy var playerDisplayView: UIView = {
        let view = UIView(frame: view.bounds)
        view.backgroundColor = .black
        view.addSubview(videoPlayerView)
        view.addSubview(playerControlsView)
        view.bringSubviewToFront(playerControlsView)
        return view
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(playerDisplayView)
        setupTapGesture()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerDisplayView.frame = playerDisplayView.superview!.bounds
        videoPlayerView.frame = playerDisplayView.bounds
        playerControlsView.frame = playerDisplayView.bounds
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if playerDisplayView.getCurrentOrientation().isLandscape {
            enterFullScreen()
        } else {
            exitFullScreen()
        }
    }
        
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleControlsVisibility))
        playerDisplayView.addGestureRecognizer(tapGesture)
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
        
        if let window = UIApplication.shared.keyWindow{
            presentPlayerView(in: window)
            isFullScreen = true
        }
    }
    
    func exitFullScreen() {
        changeOrientation(orientation: .portrait)

        presentPlayerView(in: view)
        isFullScreen = false
    }
    
    func presentPlayerView(in: UIView){
        playerDisplayView.removeFromSuperview()
        view.addSubview(playerDisplayView)
        playerDisplayView.frame = view.bounds
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
