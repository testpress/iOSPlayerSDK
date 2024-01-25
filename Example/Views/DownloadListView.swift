//
//  DownloadListView.swift
//  Example
//
//  Created by Prithuvi on 24/01/24.
//

import SwiftUI
import TPStreamsSDK

struct DownloadListView: View {
    @State private var offlineAssets: [OfflineAsset] = []
    
    var body: some View {
        List($offlineAssets, id: \.self) { offlineAsset in
            OfflineAssetRow(offlineAsset: offlineAsset)
        }
        .onAppear {
            offlineAssets = TPStreamsDownloadManager.shared.getAllOfflineAssets()
        }
        .overlay(
            Group {
                if offlineAssets.isEmpty {
                    Text("No downloads available")
                }
            }
        )
    }
}
