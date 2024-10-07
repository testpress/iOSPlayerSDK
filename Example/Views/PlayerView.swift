//
//  PlayerView.swift
//  Example
//
//  Created by Prithuvi on 07/10/24.
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
            Button(action: {
                startOfflineDownload()
            }) {
                Text("Start Offline Download")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            Spacer()
        }
    }
    
    func startOfflineDownload() {
         print("Starting offline download...")
         TPStreamsDownloadManager.shared.startDownload(assetID: assetId, accessToken: accessToken, resolution: "240p")
     }
}
