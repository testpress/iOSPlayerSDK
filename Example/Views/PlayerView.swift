//
//  PlayerView.swift
//  Example
//
//  Created by Prithuvi on 24/01/24.
//

import SwiftUI
import TPStreamsSDK

struct PlayerView: View {
    var title: String? = nil
    var assetId: String?  = nil
    var accessToken: String?  = nil
    var offlineAsset: OfflineAsset? = nil
    
    var body: some View {
        VStack {
            if let offlineAsset = offlineAsset {
                let player = TPAVPlayer(offlineAsset: offlineAsset)
                TPStreamPlayerView(player: player)
                    .frame(height: 240)
                    .navigationBarTitle(title ?? offlineAsset.title)
                    .onDisappear {
                        player.pause()
                    }
                Spacer()
            } else if let assetId = assetId, let accessToken = accessToken {
                let player = TPAVPlayer(assetID: assetId, accessToken: accessToken)
                TPStreamPlayerView(player: player)
                    .frame(height: 240)
                    .navigationBarTitle(title ?? "")
                    .onDisappear {
                        player.pause()
                    }
                Spacer()
            }
        }
    }
}
