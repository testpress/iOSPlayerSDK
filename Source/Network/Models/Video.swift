//
//  Video.swift
//  TPStreamsSDK
//
//  Created by Testpress on 13/06/24.
//

import Foundation
import RealmSwift

public enum ContentProtectionType: Int, PersistableEnum {
    case drm = 1
    case aes = 2

    public static func fromString(_ type: String?) -> ContentProtectionType? {
        guard let type = type?.lowercased() else { return nil }
        if type == "drm" { return .drm }
        if type == "aes" { return .aes }
        return nil
    }
}

public struct Video {
    let id: String?
    let playbackURL: String
    let status: String
    let drmEncrypted: Bool
    let duration: Double
    let thumbnailURL: String?
    let contentProtectionType: ContentProtectionType?
    
    var isAESEncrypted: Bool {
        return contentProtectionType == .aes
    }

    var keyIdentifier: String? {
        return id
    }
}
