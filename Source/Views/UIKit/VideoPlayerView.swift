//
//  VideoPlayerView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 22/07/23.
//

import Foundation
import UIKit
import AVFoundation

class TPVideoPlayerUIView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    var onVideoRectChanged: ((CGRect) -> Void)?
    
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    var videoRect: CGRect { playerLayer.videoRect }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        guard layer === self.layer else { return }
        onVideoRectChanged?(playerLayer.videoRect)
    }
}
