//
//  ContentView.swift
//  Example
//
//  Created by Bharath on 31/05/23.
//

import SwiftUI
import iOSPlayerSDK

struct ContentView: View {
    var body: some View {
        VStack {
            TPStreamPlayer()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
