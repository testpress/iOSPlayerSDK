//
//  UIInterfaceOrientationMask.swift
//  TPStreamsSDK
//
//  Created by Testpress on 16/11/23.
//

import Foundation
import UIKit


extension UIInterfaceOrientationMask {
    var toUIInterfaceOrientation: UIInterfaceOrientation {
        switch self {
        case .portrait:
            return UIInterfaceOrientation.portrait
        case .landscape:
            return UIInterfaceOrientation.landscapeRight
        default:
            return UIInterfaceOrientation.unknown
        }
    }
}
