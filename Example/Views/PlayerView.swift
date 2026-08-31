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
                        ),
                        WatermarkConfig(
                            text: "random-id",
                            color: 0xFF00FF00,
                            textSize: 14,
                            opacity: 0.6,
                            animation: WatermarkAnimation(type: .random, duration: 4000)
                        )
                    ])
                    .setImageWatermarks([
                        ImageWatermarkConfig(
                            imageUrl: "https://cdn.tpstreams.com/wp-content/uploads/2025/09/cropped-cropped-Logo-1.png",
                            width: 50,
                            height: 50,
                            x: 100,
                            y: 100,
                            opacity: 0.9
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
                        ),
                        WatermarkConfig(
                            text: "random-id",
                            color: 0xFF00FF00,
                            textSize: 14,
                            opacity: 0.6,
                            animation: WatermarkAnimation(type: .random, duration: 4000)
                        )
                    ])
                    .setImageWatermarks([
                        ImageWatermarkConfig(
                            imageUrl: "https://cdn.tpstreams.com/wp-content/uploads/2025/09/cropped-cropped-Logo-1.png",
                            width: 50,
                            height: 50,
                            x: 100,
                            y: 100,
                            opacity: 0.9
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
