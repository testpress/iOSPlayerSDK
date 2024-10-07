//
//  OfflineAssetRow.swift
//  Example
//
//  Created by Prithuvi on 07/10/24.
//

import Foundation
import SwiftUI
import TPStreamsSDK

struct OfflineAssetRow: View {
    @State private var showActionSheet = false
    @Binding private var offlineAsset: OfflineAsset
    
    init(offlineAsset: Binding<OfflineAsset>) {
        _offlineAsset = offlineAsset
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(offlineAsset.title)
                    .font(.headline)
                
                ProgressView(value: offlineAsset.percentageCompleted, total: 100)
                
                Text("\(formatDate(date: offlineAsset.createdAt)) • \(formatDuration(seconds: offlineAsset.duration)) • \(String(format: "%.2f MB", offlineAsset.size / 8 / 1024 / 1024)) • \(offlineAsset.status)")                    .font(.caption)
            }
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(title: Text("Options"), buttons: getButtons(offlineAsset))
        }
        .onTapGesture {
            showActionSheet = true
        }
        .padding(10)
    }
    
    func getButtons(_ offlineAsset: OfflineAsset) -> [ActionSheet.Button] {
        switch (offlineAsset.status) {
        case Status.inProgress.rawValue:
            return [pauseButton(offlineAsset), .cancel()]
        case Status.paused.rawValue:
            return [resumeButton(offlineAsset), .cancel()]
        default:
            return [.cancel()]
        }
    }

    private func pauseButton(_ offlineAsset: OfflineAsset) -> ActionSheet.Button {
        return .default(Text("Pause")) {
            TPStreamsDownloadManager.shared.pauseDownload(offlineAsset.assetId)
        }
    }

    private func resumeButton(_ offlineAsset: OfflineAsset) -> ActionSheet.Button {
        return .default(Text("Resume")) {
            TPStreamsDownloadManager.shared.resumeDownload(offlineAsset.assetId)
        }
    }
}
