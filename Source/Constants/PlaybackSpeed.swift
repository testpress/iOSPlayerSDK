//
//  PlaybackSpeed.swift
//  TPStreamsSDK
//
//  Created by Testpress on 19/06/24.
//

import Foundation

enum PlaybackSpeed: Float, CaseIterable {
    case verySlow = 0.5
    case slow = 0.75
    case normal = 1
    case fast = 1.25
    case veryFast = 1.5
    case double = 2
    
    var label: String {
        switch self {
        case .verySlow: return "0.5x"
        case .slow: return "0.75x"
        case .normal: return "Normal"
        case .fast: return "1.25x"
        case .veryFast: return "1.5x"
        case .double: return "2x"
        }
    }
}
