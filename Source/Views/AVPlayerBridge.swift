//
//  TPVideoPlayer.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 31/05/23.
//
import Foundation
import SwiftUI
import UIKit
import AVKit


class TPVideoPlayerUIView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}


struct AVPlayerBridge: UIViewRepresentable {
    var player: TPAVPlayer

    func makeUIView(context: Context) -> TPVideoPlayerUIView {
        let videoPlaybackView = TPVideoPlayerUIView()
        videoPlaybackView.player = self.player
        return videoPlaybackView
    }

    func updateUIView(_ uiView: TPVideoPlayerUIView, context: Context) { }
}
