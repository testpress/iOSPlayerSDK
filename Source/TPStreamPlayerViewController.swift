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
    
    private lazy var videoPlayerView: TPVideoPlayerUIView = {
        let playerView = TPVideoPlayerUIView(frame: view.frame)
        playerView.backgroundColor = .black
        playerView.player = player
        return playerView
    }()
    
    private lazy var playerControlsView: PlayerControlsUIView = {
        guard let playerControlsView = bundle.loadNibNamed("PlayerControls", owner: nil, options: nil)?.first as? PlayerControlsUIView else {
                    fatalError("Could not load PlayerControls view from nib.")
                }
        playerControlsView.player = TPStreamPlayer(player: self.player!)
        playerControlsView.frame = view.bounds
        playerControlsView.isHidden = true
        return playerControlsView
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupTapGesture()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPlayerView.frame = view.bounds
        playerControlsView.frame = view.bounds
    }
    
    private func setupViews() {
        view.backgroundColor = .black
        view.addSubview(videoPlayerView)
        view.addSubview(playerControlsView)
        view.bringSubviewToFront(playerControlsView)
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleControlsVisibility))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func toggleControlsVisibility() {
        playerControlsView.isHidden = !playerControlsView.isHidden
        
        // Hide controls view after 10 seconds
        if !playerControlsView.isHidden {
            controlsVisibilityTimer?.invalidate()
            controlsVisibilityTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
                self?.playerControlsView.isHidden = true
            }
        }
    }
}
