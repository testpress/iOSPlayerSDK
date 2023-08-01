//
//  TimeIndicatorView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 06/06/23.
//

import SwiftUI

@available(iOS 13.0, *)
struct TimeIndicatorView: View {
    @EnvironmentObject var player: TPStreamPlayerObservable
    
    var body: some View {
        HStack {
            Text(timeStringFromSeconds(player.observedCurrentTime ?? 0))
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
}

