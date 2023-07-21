//
//  TPStreamPlayerUIKitView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 20/07/23.
//

import Foundation
import UIKit


public class TPStreamUIKitPlayerView: UIView {
    private var player: TPAVPlayer!
    private var controlsVisibilityTimer: Timer?
    
    private lazy var videoPlayerView: TPVideoPlayerUIView = {
        let view = TPVideoPlayerUIView(frame: bounds)
        view.player = player
        return view
    }()
    
    private lazy var playerControlsView: PlayerControlsUIKitView = {
        guard let views = bundle.loadNibNamed("PlayerControls", owner: nil, options: nil) as? [PlayerControlsUIKitView],
              let playerControlsView = views.first else {
            fatalError("Could not load PlayerControls view from nib.")
        }
        playerControlsView.frame = bounds
        playerControlsView.isHidden = true
        return playerControlsView
    }()
    
    public init(frame: CGRect, player: TPAVPlayer) {
        super.init(frame: frame)
        
        self.player = player
        setupViews()
        setupTapGesture()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(videoPlayerView)
        addSubview(playerControlsView)
        bringSubviewToFront(playerControlsView)
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleControlsVisiblity))
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func toggleControlsVisiblity() {
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
