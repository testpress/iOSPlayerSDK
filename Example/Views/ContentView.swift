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
        NavigationView {
            VStack {
                Text("Sample videos")
                    .font(.title)
                    .padding()
                NavigationLink(destination: PlayerView(title: "Non-DRM-1", assetId: "5X3sT3UXyNY", accessToken: "06d4191c-f470-476a-a0ef-58de2c9c2245")) {
                    Text("Non-DRM-1")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                NavigationLink(destination: PlayerView(title: "Non-DRM-2", assetId: "8DjR3FzHy4Z", accessToken: "0cebd232-3699-4908-81f0-3cc2fa9497f8")) {
                    Text("Non-DRM-2")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                NavigationLink(destination: PlayerView(title: "Non-DRM-3", assetId: "AeDsCzqB5Td", accessToken: "553157af-6754-4061-a089-8f6e44c7476f")) {
                    Text("Non-DRM-3")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                NavigationLink(destination: DownloadListView()) {
                    Text("Download List")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                Spacer()
            }
            .padding()
            .navigationBarTitle("Sample App")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
