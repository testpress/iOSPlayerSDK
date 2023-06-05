//
//  TPStreamPlayer.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 31/05/23.
//

import SwiftUI
import AVKit

public struct TPStreamPlayer: View {
    var player: TPAVPlayer
    
    public init(player: TPAVPlayer) {
        self.player = player
    }

    public var body: some View {
        VStack {
            AVPlayerBridge(player: player)
                .onAppear(){
                    player.play()
                }
        }.background(Color.black)
    }
}
