//
//  PlayerView.swift
//  Example
//
//  Created by Prithuvi on 24/01/24.
//

import SwiftUI
import TPStreamsSDK

struct PlayerView: View {
    var title: String
    var assetId: String
    var accessToken: String
    var body: some View {
        VStack {
            let player = TPAVPlayer(assetID: assetId,accessToken: accessToken)
            TPStreamPlayerView(player: player)
                .frame(height: 240)
                .navigationBarTitle(title)
            Spacer()
        }
    }
}
