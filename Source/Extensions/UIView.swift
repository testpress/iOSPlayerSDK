//
//  UIView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 02/08/23.
//

import Foundation
import UIKit

extension UIView {
    func getCurrentOrientation() -> UIInterfaceOrientation {
        if #available(iOS 16.0, *) {
            if let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation {
                return orientation
            }
        } else {
            let deviceOrientation = UIDevice.current.orientation
            switch deviceOrientation {
            case .portrait:
                return .portrait
            case .portraitUpsideDown:
                return .portraitUpsideDown
            case .landscapeLeft:
                return .landscapeLeft
            case .landscapeRight:
                return .landscapeRight
            default:
                break
            }
        }

        return .unknown
    }
}
