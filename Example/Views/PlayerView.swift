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
    var body: some View {
        VStack {
            if (TPStreamsDownloadManager.shared.isAssetDownloaded(assetID: assetId!)){
                let player = TPAVPlayer(offlineAssetId: assetId!)
                let playerViewConfig = TPStreamPlayerConfigurationBuilder()
                    .setPreferredForwardDuration(15)
                    .setPreferredRewindDuration(5)
                    .setprogressBarThumbColor(.systemBlue)
                    .setwatchedProgressTrackColor(.systemBlue)
                    .enableCaptions(true)
                    .autoSelectFirstSubtitle(true)
                    .setUserId("example-user")
                    .setWatermarks([
                        WatermarkConfig(
                            text: "example-user",
                            x: 50,
                            y: 50,
                            color: 0xFFFFFFFF,
                            textSize: 14,
                            opacity: 0.3
                        ),
                        WatermarkConfig(
                            text: "example-user",
                            x: 200,
                            y: 100,
                            color: 0xFFFF0000,
                            textSize: 20,
                            opacity: 0.5,
                            animation: WatermarkAnimation(type: .pingPong, duration: 10000)
                        )
                    ])
                    .build()
                TPStreamPlayerView(player: player, playerViewConfig: playerViewConfig)
                    .frame(height: 240)
                    .navigationBarTitle(title ?? "")
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
                    .showDownloadOption()
                    .enableCaptions(true)
                    .autoSelectFirstSubtitle(true)
                    .setStartInFullscreen(false)
                    .enableFullscreen(false)
                    .enablePlaybackSpeed(false)
                    .showResolutionOptions(false)
                    .enableSeekButtons(false)
                    .setUserId("example-user")
                    .setWatermarks([
                        WatermarkConfig(
                            text: "example-user",
                            x: 50,
                            y: 50,
                            color: 0xFFFFFFFF,
                            textSize: 14,
                            opacity: 0.3
                        ),
                        WatermarkConfig(
                            text: "example-user",
                            x: 200,
                            y: 100,
                            color: 0xFFFF0000,
                            textSize: 20,
                            opacity: 0.5,
                            animation: WatermarkAnimation(type: .pingPong, duration: 10000)
                        )
                    ])
                    .build()
                TPStreamPlayerView(player: player, playerViewConfig: playerViewConfig)
                    .frame(height: 240)
                    .navigationBarTitle(title ?? "")
                    .onDisappear {
                        player.pause()
                    }
            }
        }
    }
}
