//
//  Sentry.swift
//  TPStreamsSDK
//
//  Created by Hari on 21/02/24.
//

import Foundation
import Sentry

func captureErrorInSentry(_ error: Error, _ assetID: String?, _ accessToken: String?) -> UUID {
    let uuid = UUID()
    
    SentrySDK.capture(error: error) { scope in
        scope.setTag(value: assetID ?? "", key: "assetID")
        scope.setTag(value: uuid.uuidString, key: "playerId")
        
        let additionalInfo = [
            "accessToken": accessToken
        ]
        scope.setContext(value: additionalInfo, key: "Additional Info")
    }
    
    return uuid
}
