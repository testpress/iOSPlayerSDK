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
                // https://app.tpstreams.com/embed/g2udjm/7T8MstHRh8u/?access_token=7367f42f-42a8-4058-96e7-844efc8bb596
                nonDRMNavigationLink(title: "DRM-1", assetId: "7T8MstHRh8u", accessToken: "7367f42f-42a8-4058-96e7-844efc8bb596")
                nonDRMNavigationLink(title: "Non-DRM-2", assetId: "72c9RRHj3M8", accessToken: "47c686d7-a50b-41f9-b2cd-0660960c357f")
                nonDRMNavigationLink(title: "Non-DRM-3", assetId: "9JRmKJXZSMe", accessToken: "1ae5e10e-fc85-4aa9-9a0a-6c195e9b0034")
                downloadListNavigationLink()
                Spacer()
            }
            .padding()
            .navigationBarTitle("Sample App")
        }
    }
    
    private func nonDRMNavigationLink(title: String, assetId: String, accessToken: String) -> some View {
        NavigationLink(destination: PlayerView(title: title, assetId: assetId, accessToken: accessToken)) {
            Text(title)
                .font(.headline)
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
        }
    }
    
    private func downloadListNavigationLink() -> some View {
        NavigationLink(destination: DownloadListView()) {
            Text("Download List")
                .font(.headline)
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
