//
//  TPStreamsSDK.swift
//  iOSPlayerSDK
//
//  Created by Bharath on 01/06/23.
//

import Foundation
import AVFoundation


public class TPStreamsSDK {
    internal static var orgCode: String?
    internal static var provider: Provider = .tpstreams
    
    public static func initialize(for provider: Provider = .tpstreams, withOrgCode orgCode: String) {
        self.orgCode = orgCode
        self.provider = provider
        self.activateAudioSession()
    }
    
    private static func activateAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
        } catch {
            debugPrint("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
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
