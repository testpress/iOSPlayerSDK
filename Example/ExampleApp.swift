//
//  ExampleApp.swift
//  Example
//
//  Created by Bharath on 31/05/23.
//

import SwiftUI
import TPStreamsSDK

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        TPStreamsSDK.initialize(withOrgCode: "g2udjm")
        return true
    }
}

@main
struct ExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
