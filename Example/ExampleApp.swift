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
        TPStreamsSDK.initialize(withOrgCode: "6eafqn", authToken: "98d0f66a38144bdae77f422bb0f15649dc1897f04952cae6fbbcaab8c2b9ab6a")
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
