//
//  DownloadListView.swift
//  Example
//
//  Created by Prithuvi on 24/01/24.
//

import SwiftUI
import TPStreamsSDK

struct DownloadListView: View {
    @ObservedObject private var appDownloadManager = AppDownloadManager()

    var body: some View {
        List($appDownloadManager.offlineAssets, id: \.self) { offlineAsset in
            OfflineAssetRow(offlineAsset: offlineAsset)
        }
        .navigationTitle("Downloads")
        .overlay(
            Group {
                if appDownloadManager.offlineAssets.isEmpty {
                    Text("No downloads available")
                }
            }
        )
    }
}
