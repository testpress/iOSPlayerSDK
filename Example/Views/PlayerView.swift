//
//  PlayerView.swift
//  Example
//
//  Created by Prithuvi on 07/10/24.
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
                let player = TPAVPlayer(offlineAssetId: offlineAsset.assetId)
                let playerViewConfig = TPStreamPlayerConfigurationBuilder()
                    .setPreferredForwardDuration(15)
                    .setPreferredRewindDuration(5)
                    .setprogressBarThumbColor(.systemBlue)
                    .setwatchedProgressTrackColor(.systemBlue)
                    .build()
                TPStreamPlayerView(player: player, playerViewConfig: playerViewConfig)
                    .frame(height: 240)
                    .navigationBarTitle(title ?? offlineAsset.title)
                    .onDisappear {
                        player.pause()
                    }
                Spacer()
            } else if let assetId = assetId, let accessToken = accessToken {
                let player = TPAVPlayer(assetID: assetId, accessToken: accessToken)
                let playerViewConfig = TPStreamPlayerConfigurationBuilder()
                    .setPreferredForwardDuration(15)
                    .setPreferredRewindDuration(5)
                    .setprogressBarThumbColor(.systemBlue)
                    .setwatchedProgressTrackColor(.systemBlue)
                    .build()
                TPStreamPlayerView(player: player, playerViewConfig: playerViewConfig)
                    .frame(height: 240)
                    .navigationBarTitle(title ?? "")
                    .onDisappear {
                        player.pause()
                    }
                Button(action: {
                    startOfflineDownload()
                }) {
                    Text("Start Offline Download")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                    Spacer()
                }
            }
        }
    }
    
    func startOfflineDownload() {
        TPStreamsDownloadManager.shared.startDownload(assetID: assetId!, accessToken: accessToken!, resolution: "240p")
    }
}
