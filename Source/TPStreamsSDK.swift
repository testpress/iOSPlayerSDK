//
//  TPStreamsSDK.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 01/06/23.
//

import Foundation
import AVFoundation
// import Sentry
import RealmSwift

#if SPM
let bundle = Bundle.module
#elseif CocoaPods
let appBundle = Bundle(for: TPStreamsSDK.self)
let bundle = Bundle(url: appBundle.url(forResource: "TPStreamsSDK", withExtension: "bundle")!)!
#else
let bundle = Bundle(identifier: "com.tpstreams.iOSPlayerSDK")! // Access bundle using identifier when directly including the framework
#endif


public class TPStreamsSDK {
    internal static var orgCode: String?
    internal static var provider: Provider = .tpstreams
    internal static var authToken: String?
    
    public static func initialize(for provider: Provider = .tpstreams, withOrgCode orgCode: String, usingAuthToken authToken: String? = nil) {
        self.orgCode = orgCode
        self.provider = provider
        self.authToken = authToken
        self.validateAuthToken()
        self.activateAudioSession()
        // self.initializeSentry()
        self.initializeDatabase()
        self.removePartiallyDeletedVideos()
    }
    
    private static func validateAuthToken() {
        guard provider != .tpstreams || authToken == nil else {
            fatalError("If the provider is .tpstreams, authToken must be nil.")
        }
    }
    
    private static func activateAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
        } catch {
            // SentrySDK.capture(error: error)
            debugPrint("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }
    
    // private static func initializeSentry(){
    //     SentrySDK.start { options in
    //         options.dsn = "https://8ac303d4635e4f3ab06a2b7d77b3c0c1@sentry.testpress.in/9"
    //         options.debug = false
    //         options.tracesSampleRate = 1.0
    //         options.enablePreWarmedAppStartTracing = true
    //         options.attachScreenshot = false
    //         options.attachViewHierarchy = false
    //     }
    //     SentrySDK.configureScope { scope in
    //         scope.setTag(value: orgCode!, key: "orgCode")
    //     }
    // }
    
    private static func initializeDatabase() {
        var config = Realm.Configuration(
            schemaVersion: 3,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 3 {
                        // No manual migration needed.
                        // Realm automatically handles newly added optional properties.
                }
            }
        )
        config.fileURL!.deleteLastPathComponent()
        config.fileURL!.appendPathComponent("TPStreamsPlayerSDK")
        config.fileURL!.appendPathExtension("realm")
        Realm.Configuration.defaultConfiguration = config
    }
    
    private static func removePartiallyDeletedVideos() {
        TPStreamsDownloadManager.shared.removePartiallyDeletedVideos()
    }
}

public enum Provider {
    case testpress
    case tpstreams
    
    internal var API: BaseAPI.Type {
        switch self {
        case .testpress:
            return TestpressAPI.self
        case .tpstreams:
            return StreamsAPI.self
        }
    }
}
