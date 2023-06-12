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
            let player = TPAVPlayer(assetID: "8eaHZjXt6km",
                                    accessToken: "16b608ba-9979-45a0-94fb-b27c1a86b3c1")
            TPStreamPlayerView(player: player)
                .frame(height: 240)
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
