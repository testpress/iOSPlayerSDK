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
    
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
