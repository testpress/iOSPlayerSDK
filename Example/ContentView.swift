//
//  ContentView.swift
//  Example
//
//  Created by Bharath on 31/05/23.
//

import SwiftUI
import TPStreamsSDK
import AVKit

struct ContentView: View {
    var body: some View {
        VStack {
            let player = TPAVPlayer(assetID: "peBmzxeQ7Mf",
                                    accessToken: "d7ebb4b2-8dee-4dff-bb00-e833195b0756")
            TPStreamPlayerView(player: player)
                .frame(height: 240)
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
        // https://app.tpstreams.com/embed/6eafqn/95hBGFAhQYR/?access_token=7d4e2ffb-3492-4cd4-8e5c-41b7af2f3e7f
        TPStreamsDownloadManager.shared.startDownload(assetID: "95hBGFAhQYR", accessToken: "7d4e2ffb-3492-4cd4-8e5c-41b7af2f3e7f", resolution: "240p")
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
