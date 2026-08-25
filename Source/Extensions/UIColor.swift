//
//  UIColor.swift
//  TPStreamsSDK
//
//  Created by Testpress on 25/08/26.
//

import UIKit

extension UIColor {
    convenience init(argb: Int64, opacity: Double = 1.0) {
        let value = UInt32(truncatingIfNeeded: argb)
        let alpha = CGFloat((value >> 24) & 0xFF) / 255.0
        let red = CGFloat((value >> 16) & 0xFF) / 255.0
        let green = CGFloat((value >> 8) & 0xFF) / 255.0
        let blue = CGFloat(value & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha * CGFloat(opacity))
    }
}
