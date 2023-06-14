//
//  MediaControlsView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 06/06/23.
//

import SwiftUI

struct MediaControlsView: View {
    @EnvironmentObject var player: TPStreamPlayer
    
    var body: some View {
        HStack() {
            Spacer()
            Button(action: player.rewind) {
                Image("rewind", bundle: bundle)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .brightness(-0.1)
            }
            Spacer()
            if player.status == .buffering {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
            } else {
                Button(action: togglePlay) {
                    Image(player.status == .paused ? "play" : "pause",bundle: bundle)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .brightness(-0.1)
                }
            }
            Spacer()
            Button(action: player.forward) {
                Image("forward", bundle: bundle)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .brightness(-0.1)
            }
            Spacer()
        }
    }
    
    
    public func togglePlay(){
        if player.status == .paused {
            player.play()
        } else {
            player.pause()
        }
    }
    
}
