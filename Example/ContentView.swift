//
//  ContentView.swift
//  Example
//
//  Created by Bharath on 31/05/23.
//

import SwiftUI
import TPStreamsSDK

struct ContentView: View {
    var body: some View {
        VStack {
            var player = TPAVPlayer(accessToken: "5f3ded52-ace8-487e-809c-10de895872d6")
            TPStreamPlayer(player: player)
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
