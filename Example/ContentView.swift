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
            let player = TPAVPlayer(assetID: "5X3sT3UXyNY",
                                    accessToken: "06d4191c-f470-476a-a0ef-58de2c9c2245")
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
