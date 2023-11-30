//
//  TPStreamPlayerConfiguration.swift
//  TPStreamsSDK
//
//  Created by Testpress on 29/11/23.
//

import Foundation
import UIKit

public struct TPStreamPlayerConfiguration {
    public var preferredForwardDuration: TimeInterval = 10.0
    public var preferredRewindDuration: TimeInterval = 10.0
}


public class TPStreamPlayerConfigurationBuilder {
    private var configuration: TPStreamPlayerConfiguration
    
    public init() {
        self.configuration = TPStreamPlayerConfiguration()
    }
    
    public func setPreferredForwardDuration(_ duration: TimeInterval) -> Self {
        configuration.preferredForwardDuration = duration
        return self
    }
    
    public func setPreferredRewindDuration(_ duration: TimeInterval) -> Self {
        configuration.preferredRewindDuration = duration
        return self
    }
    
    public func build() -> TPStreamPlayerConfiguration {
        return configuration
    }
}
