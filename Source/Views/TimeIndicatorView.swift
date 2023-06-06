//
//  TimeIndicatorView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 06/06/23.
//

import SwiftUI

struct TimeIndicatorView: View {
    @EnvironmentObject var player: TPStreamPlayer
    
    var body: some View {
        HStack {
            Text(timeStringFromSeconds(player.currentTime ?? 0))
                .foregroundColor(Color.white)
                .fontWeight(.bold)
                .font(.subheadline)
            
            Text("/")
                .foregroundColor(Color.white.opacity(0.6))
                .fontWeight(.bold)
            
            Text(timeStringFromSeconds(player.videoDuration))
                .foregroundColor(Color.white.opacity(0.6))
                .fontWeight(.bold)
                .font(.subheadline)
        }
    }
    
    func timeStringFromSeconds(_ seconds: Float64) -> String {
        guard seconds.isFinite || !seconds.isNaN else {
            return "00:00"
        }

        let totalSeconds = Int(seconds.rounded())
        let minutes = (totalSeconds / 60) % 60
        let hours = totalSeconds / 3600

        let formattedTime: String
        if hours > 0 {
            formattedTime = String(format: "%02d:%02d:%02d", hours, minutes, totalSeconds % 60)
        } else {
            formattedTime = String(format: "%02d:%02d", minutes, totalSeconds % 60)
        }

        return formattedTime
    }
}

