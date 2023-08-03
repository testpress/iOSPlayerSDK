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
}
