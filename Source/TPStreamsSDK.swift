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
    
    public static func initialize(orgCode: String) {
        self.orgCode = orgCode
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
