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
    public var brandingImage: UIImage?
    public var brandingPosition: BrandingPosition = .topRight
    public var brandingMargin: UIEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 10)
}

public enum BrandingPosition {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
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
    
    public func setBrandingImage(_ image: UIImage?) -> Self {
        configuration.brandingImage = image
        return self
    }

    public func setBrandingPosition(_ position: BrandingPosition) -> Self {
        configuration.brandingPosition = position
        return self
    }

    public func setBrandingMargin(_ margin: UIEdgeInsets) -> Self {
        configuration.brandingMargin = margin
        return self
    }
    
    public func build() -> TPStreamPlayerConfiguration {
        return configuration
    }
}
