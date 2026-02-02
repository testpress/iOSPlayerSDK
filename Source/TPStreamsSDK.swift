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

private func isValidTPStreamsResourceBundle(_ b: Bundle) -> Bool {
    return b.path(forResource: "Assets", ofType: "car") != nil
}

let bundle: Bundle = {
    #if DEBUG
    print("[TPStreamsSDK] 🔍 Resolving resource bundle...")
    print("[TPStreamsSDK] 📍 Framework Path: \(appBundle.bundlePath)")
    #endif

    // 1) Primary: inside framework bundle
    if let url = appBundle.url(forResource: "TPStreamsSDK", withExtension: "bundle"),
       let candidate = Bundle(url: url),
       isValidTPStreamsResourceBundle(candidate) {

        #if DEBUG
        print("[TPStreamsSDK] ✅ Located: \(url.lastPathComponent) at \(url.deletingLastPathComponent().path)")
        print("[TPStreamsSDK] 🎯 Active Resource Bundle: \(candidate.bundlePath)")
        #endif

        return candidate
    }

    #if DEBUG
    print("[TPStreamsSDK] ⚠️ SDK bundle not found in framework. Scanning all loaded bundles...")
    #endif

    // 2) Fallback: scan everything loaded (modular apps fix)
    for base in (Bundle.allFrameworks + Bundle.allBundles) {
        if let url = base.url(forResource: "TPStreamsSDK", withExtension: "bundle"),
           let candidate = Bundle(url: url),
           isValidTPStreamsResourceBundle(candidate) {

            #if DEBUG
            print("[TPStreamsSDK] ✅ Located: \(url.lastPathComponent) during scan")
            print("[TPStreamsSDK] 🎯 Active Resource Bundle: \(candidate.bundlePath)")
            #endif

            return candidate
        }
    }

    #if DEBUG
    print("[TPStreamsSDK] ❌ Resource bundle NOT FOUND. Falling back to Bundle.main")
    #endif
    return Bundle.main
}()

#else
let bundle = Bundle(identifier: "com.tpstreams.iOSPlayerSDK") ?? Bundle(for: TPStreamsSDK.self)
#endif

// MARK: - Internal Asset Helper
/// Load an image from the SDK's resource bundle
/// - Parameter name: The name of the image asset
/// - Returns: UIImage if found, nil otherwise
internal func loadSDKImage(_ name: String) -> UIImage? {
    let img = UIImage(named: name, in: bundle, compatibleWith: nil)
    #if DEBUG
    if img == nil {
        print("[TPStreamsSDK] ❌ Failed to load image: '\(name)'")
        print("[TPStreamsSDK] 🔍 Searched In: \(bundle.bundlePath)")
    } else {
        let path = bundle.path(forResource: name, ofType: nil) ?? "\(bundle.bundlePath)/Assets.car/\(name)"
        print("[TPStreamsSDK] 🖼️ Loaded: '\(name)'")
        print("[TPStreamsSDK] 📍 Path: \(path)")
    }
    #endif
    return img
}

/// Load a storyboard from the SDK's resource bundle
/// - Parameter name: The name of the storyboard
/// - Returns: UIStoryboard scoped to the SDK bundle
internal func loadSDKStoryboard(_ name: String) -> UIStoryboard {
    return UIStoryboard(name: name, bundle: bundle)
}

/// Load a NIB from the SDK's resource bundle
/// - Parameter name: The name of the NIB
/// - Parameter owner: The owner of the NIB
/// - Parameter options: The options for the NIB
/// - Returns: The first object in the NIB if found
internal func loadSDKNib(_ name: String, owner: Any? = nil, options: [UINib.OptionsKey : Any]? = nil) -> Any? {
    #if DEBUG
    print("[TPStreamsSDK] 🧩 Loading NIB: '\(name)'")
    #endif
    return bundle.loadNibNamed(name, owner: owner, options: options)?.first
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
        
        #if DEBUG && CocoaPods
        TPStreamsDebugLogger.logBundleResolution()
        #endif
        
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
