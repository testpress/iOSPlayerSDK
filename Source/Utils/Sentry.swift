//
//  Sentry.swift
//  TPStreamsSDK
//
//  Created by Hari on 21/02/24.
//

import Foundation
import Sentry

func captureErrorInSentry(_ error: Error, _ assetID: String?, _ accessToken: String?) -> String {
    let uuid = generateRandomString()
    
    SentrySDK.capture(error: error) { scope in
        scope.setTag(value: assetID ?? "", key: "assetID")
        scope.setTag(value: uuid, key: "playerId")
        
        let additionalInfo = [
            "accessToken": accessToken
        ]
        scope.setContext(value: additionalInfo, key: "Additional Info")
    }
    
    return uuid
}

func generateRandomString(length: Int = 11) -> String {
    let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map { _ in characters.randomElement()! })
}
