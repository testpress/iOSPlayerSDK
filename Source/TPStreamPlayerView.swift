//
//  TPStreamPlayer.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 31/05/23.
//

import SwiftUI

public struct TPStreamPlayerView: View {
    var player: TPAVPlayer
    
    public init(player: TPAVPlayer) {
        self.player = player
    }

    public var body: some View {
        ZStack {
            AVPlayerBridge(player: player)
            PlayerControlsView(player: player)
        }.background(Color.black)
    }
}
