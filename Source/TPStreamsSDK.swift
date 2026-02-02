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

#elseif CocoaPods
let appBundle = Bundle(for: TPStreamsSDK.self)

let bundle: Bundle = {
    #if DEBUG
    print("[TPStreamsSDK] 🔍 Resolving bundle...")
    print("[TPStreamsSDK] Framework bundle: \(appBundle.bundlePath)")
    #endif
    
    if let url = appBundle.url(forResource: "TPStreamsSDK", withExtension: "bundle"),
       let resourceBundle = Bundle(url: url) {
        #if DEBUG
        print("[TPStreamsSDK] ✅ Found TPStreamsSDK.bundle at: \(url.path)")
        #endif
        return resourceBundle
    }
    
    #if DEBUG
    print("[TPStreamsSDK] ⚠️ TPStreamsSDK.bundle not found, falling back to Bundle.main")
    #endif
    return Bundle.main
}()

#else
let bundle = Bundle(identifier: "com.tpstreams.iOSPlayerSDK") ?? Bundle(for: TPStreamsSDK.self)
#endif

#if DEBUG && CocoaPods
private let _ = {
    print("[TPStreamsSDK] 🎯 Final bundle: \(bundle.bundlePath)")
    
    // Test icon loading
    let testIcons = ["play", "pause", "forward", "rewind", "maximize", "minimize"]
    let foundIcons = testIcons.filter { UIImage(named: $0, in: bundle, compatibleWith: nil) != nil }
    
    if foundIcons.count == testIcons.count {
        print("[TPStreamsSDK] ✅ All \(testIcons.count) icons loaded successfully")
    } else {
        let missing = testIcons.filter { !foundIcons.contains($0) }
        print("[TPStreamsSDK] ⚠️ Found \(foundIcons.count)/\(testIcons.count) icons")
        print("[TPStreamsSDK] ❌ Missing: \(missing.joined(separator: ", "))")
    }
    print("[TPStreamsSDK] 🏁 Bundle resolution complete\n")
    return ()
}()
#endif


// MARK: - Internal Asset Helper
/// Load an image from the SDK's resource bundle
/// - Parameter name: The name of the image asset
/// - Returns: UIImage if found, nil otherwise
internal func loadSDKImage(_ name: String) -> UIImage? {
    return UIImage(named: name, in: bundle, compatibleWith: nil)
}

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
