//
//  Time.swift
//  TPStreamsSDK
//
//  Created by Testpress on 01/08/23.
//

import Foundation

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
