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
import UIKit

#if SPM
let bundle = Bundle.module
#else
let bundle: Bundle = {
    #if DEBUG
    func logBundle(_ name: String, _ b: Bundle?) {
        guard let b = b else {
            print("[TPStreamsSDK] \(name) is NIL")
            return
        }
        print("[TPStreamsSDK] \(name) - ID: \(b.bundleIdentifier ?? "nil"), Path: \(b.bundlePath)")
    }
    print("[TPStreamsSDK] --- Debugging Bundle Resolution ---")
    logBundle("Bundle.main", Bundle.main)
    #endif

    var resolvedBundle: Bundle?

    #if CocoaPods
    let frameworkBundle = Bundle(for: TPStreamsSDK.self)
    #if DEBUG
    logBundle("Framework Bundle (for: TPStreamsSDK.self)", frameworkBundle)
    #endif
    
    if let resourceBundleURL = frameworkBundle.url(forResource: "TPStreamsSDK", withExtension: "bundle") {
        #if DEBUG
        print("[TPStreamsSDK] url(forResource: \"TPStreamsSDK\", withExtension: \"bundle\") -> \(resourceBundleURL.path)")
        #endif
        resolvedBundle = Bundle(url: resourceBundleURL)
        #if DEBUG
        print("[TPStreamsSDK] Bundle(url:) success: \(resolvedBundle != nil)")
        #endif
    } else {
        #if DEBUG
        print("[TPStreamsSDK] url(forResource: \"TPStreamsSDK\", withExtension: \"bundle\") -> NIL")
        #endif
    }
    #else
    let identifier = "com.tpstreams.iOSPlayerSDK"
    resolvedBundle = Bundle(identifier: identifier)
    #if DEBUG
    print("[TPStreamsSDK] Bundle(identifier: \"\(identifier)\") lookup success: \(resolvedBundle != nil)")
    #endif
    #endif

    #if DEBUG
    logBundle("Resolved Resource Bundle", resolvedBundle)
    #endif

    let finalBundle = resolvedBundle ?? Bundle.main

    #if DEBUG
    if resolvedBundle == nil {
        print("[TPStreamsSDK] WARNING: Bundle resolution failed. Falling back to Bundle.main.")
    }
    let testImage = UIImage(named: "play", in: finalBundle, compatibleWith: nil)
    print("[TPStreamsSDK] Test Resource Lookup ('play' icon): \(testImage != nil ? "OK" : "NIL")")
    print("[TPStreamsSDK] --- Debugging Bundle Resolution End ---")
    #endif

    return finalBundle
}()
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
        self.initializeSentry()
        self.initializeDatabase()
        self.removeIncompleteDownloads()
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
            SentrySDK.capture(error: error)
            debugPrint("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }
    
    private static func initializeSentry(){
        SentrySDK.start { options in
            options.dsn = "https://8ac303d4635e4f3ab06a2b7d77b3c0c1@sentry.testpress.in/9"
            options.debug = false
            options.tracesSampleRate = 1.0
            options.enablePreWarmedAppStartTracing = true
            options.attachScreenshot = false
            options.attachViewHierarchy = false
        }
        SentrySDK.configureScope { scope in
            scope.setTag(value: orgCode!, key: "orgCode")
        }
    }
    
    private static func initializeDatabase() {
        var config = Realm.Configuration(
            schemaVersion: 4,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 4 {
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
    
    private static func removeIncompleteDownloads() {
        TPStreamsDownloadManager.shared.removeIncompleteDownloads()
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
