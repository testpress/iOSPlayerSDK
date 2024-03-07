//
//  TPStreamsSDK.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 01/06/23.
//

import Foundation
import AVFoundation
import Sentry
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
    
    public static func initialize(for provider: Provider = .tpstreams, withOrgCode orgCode: String) {
        self.orgCode = orgCode
        self.provider = provider
        self.activateAudioSession()
        self.initializeSentry()
        self.initializeDatabase()
    }
    
    private static func activateAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
        } catch {
            SentrySDK.capture(error: error)
            debugPrint("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }
    
    private static func initializeSentry(){
        SentrySDK.start { options in
            options.dsn = "https://044aaee46f1d40f48e5c4046ad3926d2@sentry.testpress.in/12"
            options.debug = false
            options.tracesSampleRate = 1.0
            options.enablePreWarmedAppStartTracing = true
            options.attachScreenshot = false
            options.attachViewHierarchy = false
        }
        SentrySDK.configureScope { scope in
            scope.setTag(value: "orgCode", key: orgCode!)
        }
    }

    private static func initializeDatabase() {
        Realm.Configuration.defaultConfiguration = Realm.Configuration(schemaVersion: 1)
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
