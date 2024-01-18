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
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
