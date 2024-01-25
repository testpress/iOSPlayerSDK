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
    public var watchedProgressTrackColor: UIColor = .red
    public var progressBarThumbColor: UIColor = .red
    public var showDownloadOption: Bool = false
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
    
    public func setwatchedProgressTrackColor(_ color: UIColor) -> Self {
        configuration.watchedProgressTrackColor = color
        return self
    }
    
    public func setprogressBarThumbColor(_ color: UIColor) -> Self {
        configuration.progressBarThumbColor = color
        return self
    }
    
    public func showDownloadOption() -> Self {
        configuration.showDownloadOption = true
        return self
    }
    
    public func build() -> TPStreamPlayerConfiguration {
        return configuration
    }
}
