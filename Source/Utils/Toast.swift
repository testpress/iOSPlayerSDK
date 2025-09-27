import UIKit

#if CocoaPods
import Toast_Swift
#else
import Toast
#endif

internal class ToastHelper {
    internal static func show(message: String) {
        DispatchQueue.main.async {
            let window: UIWindow?
            if #available(iOS 13.0, *) {
                window = UIApplication.shared.connectedScenes
                    .filter({ $0.activationState == .foregroundActive })
                    .compactMap({ $0 as? UIWindowScene })
                    .first?.windows
                    .first(where: { $0.isKeyWindow })
            } else {
                window = UIApplication.shared.keyWindow
            }
            
            if let window = window {
                window.hideToast()
                window.makeToast(message)
            }
        }
    }
}