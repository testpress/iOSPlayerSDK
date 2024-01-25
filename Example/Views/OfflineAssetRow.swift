//
//  OfflineAssetRow.swift
//  Example
//
//  Created by Prithuvi on 23/01/24.
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
                
                Text("\(formatDate(date: offlineAsset.createdAt)) • \(formatDuration(seconds: offlineAsset.duration)) • \(String(format: "%.2f MB", offlineAsset.size / 8 / 1024 / 1024))")
                    .font(.caption)
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
            TPStreamsDownloadManager.shared.pauseDownload(offlineAsset)
        }
    }

    private func resumeButton(_ offlineAsset: OfflineAsset) -> ActionSheet.Button {
        return .default(Text("Resume")) {
            TPStreamsDownloadManager.shared.resumeDownload(offlineAsset)
        }
    }

    func formatDuration(seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        
        if let formattedString = formatter.string(from: seconds) {
            return formattedString
        } else {
            return "0s"
        }
    }

    func formatDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        let formattedString = dateFormatter.string(from: date)
        return formattedString
    }
}


