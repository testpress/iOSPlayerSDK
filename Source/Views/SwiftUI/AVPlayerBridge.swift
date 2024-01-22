//
//  TPVideoPlayer.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 31/05/23.
//
import Foundation
import SwiftUI
import AVKit


@available(iOS 13.0, *)
struct AVPlayerBridge: UIViewRepresentable {
    var player: TPAVPlayer
    
    func makeUIView(context: Context) -> TPVideoPlayerUIView {
        let videoPlaybackView = TPVideoPlayerUIView()
        videoPlaybackView.player = self.player
        return videoPlaybackView
    }
    
    func updateUIView(_ uiView: TPVideoPlayerUIView, context: Context) { }
}
