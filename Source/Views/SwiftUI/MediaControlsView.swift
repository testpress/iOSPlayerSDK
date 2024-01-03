//
//  MediaControlsView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 06/06/23.
//

import SwiftUI
import AVKit

@available(iOS 14.0, *)
struct MediaControlsView: View {
    @EnvironmentObject var player: TPStreamPlayerObservable
    
    var body: some View {
        HStack() {
            Spacer()
            Button(action: { player.rewind() }) {
                Image("rewind", bundle: bundle)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .brightness(-0.1)
            }
            Spacer()
            if player.observedStatus == "buffering" {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
            } else {
                Button(action: togglePlay) {
                    Image(player.observedStatus == "paused" ? "play" : "pause", bundle: bundle)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .brightness(-0.1)
                }
            }
            Spacer()
            Button(action: {player.forward()}) {
                Image("forward", bundle: bundle)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .brightness(-0.1)
            }
            Spacer()
        }
    }
    
    
    public func togglePlay(){
        if player.status == "paused" {
            player.play()
            TPStreamsDownloadManager.shared.startDownload(asset: player.asset!, bitRate: 100_000)
        } else {
            //player.pause()
            print("hihihi",player.asset!.video.playbackURL)
            let offlineAsset = TPStreamsDownloadManager.shared.getDownloadedAsset(srcURL: player.asset!.video.playbackURL)
            player.replaceCurrentItem(offlineAsset: offlineAsset!)
            player.play()
        }
    }
    
}
