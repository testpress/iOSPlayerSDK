import UIKit
#if canImport(Toast_Swift)
import Toast_Swift
#elseif canImport(Toast)
import Toast
#endif

public class ToastHelper {
    public static func show(message: String) {
        if let window = UIApplication.shared.keyWindow {
            window.hideToast()
            window.makeToast(message)
        }
    }
}