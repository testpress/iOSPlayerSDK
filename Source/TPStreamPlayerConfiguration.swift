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
    public var downloadMetadata: [String: Any]? = nil
    public var licenseDurationSeconds: Double? = nil
    public var startInFullscreen: Bool = false
    public var enableFullscreen: Bool = true
    public var enablePlaybackSpeed: Bool = true
    public var showResolutionOptions: Bool = true
    public var enableSeekButtons: Bool = true
    public var enableCaptions: Bool = false
    
    public var showSettingsButton: Bool {
        return enablePlaybackSpeed || showResolutionOptions || showDownloadOption
    }
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
    
    public func setDownloadMetadata(_ metadata: [String: Any]?) -> Self {
        configuration.downloadMetadata = metadata
        return self
    }
    
    public func setLicenseDurationSeconds(_ seconds: Double?) -> Self {
        configuration.licenseDurationSeconds = seconds
        return self
    }
    
    public func setStartInFullscreen(_ startInFullscreen: Bool) -> Self {
        configuration.startInFullscreen = startInFullscreen
        return self
    }
    
    public func enableFullscreen(_ enable: Bool) -> Self {
        configuration.enableFullscreen = enable
        return self
    }
    
    public func enablePlaybackSpeed(_ enable: Bool) -> Self {
        configuration.enablePlaybackSpeed = enable
        return self
    }
    
    public func showResolutionOptions(_ show: Bool) -> Self {
        configuration.showResolutionOptions = show
        return self
    }
    
    public func enableSeekButtons(_ enable: Bool) -> Self {
        configuration.enableSeekButtons = enable
        return self
    }
    
    public func enableCaptions(_ enable: Bool) -> Self {
        configuration.enableCaptions = enable
        return self
    }
    
    public func build() -> TPStreamPlayerConfiguration {
        return configuration
    }
}
