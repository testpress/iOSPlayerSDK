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
    
    public init() {
    }

    public var body: some View {
        VStack {
            TPVideoPlayer(player: player)
                .onAppear(){
                    player.play()
                }
        }.background(Color.black)
    }
}

struct TPStreamPlayer_Previews: PreviewProvider {
    static var previews: some View {
        TPStreamPlayer()
    }
}
