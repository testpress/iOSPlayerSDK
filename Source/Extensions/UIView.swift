//
//  UIView.swift
//  TPStreamsSDK
//
//  Created by Testpress on 02/08/23.
//

import Foundation
import UIKit

extension UIView {
    func findRelatedViewController() -> UIViewController? {
        var responder: UIResponder? = self

        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }

        return nil
    }

    func getCurrentOrientation() -> UIInterfaceOrientation {
        if #available(iOS 13.0, *) {
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
