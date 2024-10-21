//
//  Time.swift
//  StoryboardExample
//
//  Created by Prithuvi on 21/10/24.
//

import Foundation

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

