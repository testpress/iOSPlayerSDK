//
//  TPStreamPlayer.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 31/05/23.
//

import SwiftUI
import AVKit

public struct TPStreamPlayer: View {
    @State var player = TPAVPlayer(accessToken: "5f3ded52-ace8-487e-809c-10de895872d6")
//    @State var player = AVPlayer(url: URL(string:"https://s3.eu-central-1.wasabisys.com/sampletestvideos/bigbuckbunny/bbb_sunflower_1080p_60fps_normal.mp4")!)

    @State var isPlaying: Bool = false

    public init() {
    }

    public var body: some View {
        VStack {
            TPVideoPlayer(player: player)
                .frame(width: 320, height: 180, alignment: .center)
            Button {
                isPlaying ? player.pause() : player.play()
                isPlaying.toggle()
                player.seek(to: .zero)
            } label: {
                Image(systemName: isPlaying ? "stop" : "play")
                    .padding()
            }
        }
    }
}

struct TPStreamPlayer_Previews: PreviewProvider {
    static var previews: some View {
        TPStreamPlayer()
    }
}
