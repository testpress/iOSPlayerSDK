import Foundation

/// Configuration for displaying a text watermark over video playback.
///
/// Note: The `x` and `y` coordinates are ignored when `.random` animation is used
/// because both X and Y coordinates are randomized across the full video area.
/// When `.pingPong` animation is used, the `x` coordinate is ignored because the animation
/// spans horizontally from edge to edge.
public struct WatermarkConfig: Equatable {
    public var text: String
    public var x: Int64
    public var y: Int64
    public var color: Int64
    public var textSize: Double
    public var opacity: Double
    public var animation: WatermarkAnimation?

    public init(
        text: String,
        x: Int64 = 0,
        y: Int64 = 0,
        color: Int64 = 0xFFFFFFFF,
        textSize: Double = 14,
        opacity: Double = 0.3,
        animation: WatermarkAnimation? = nil
    ) {
        self.text = text
        self.x = x
        self.y = y
        self.color = color
        self.textSize = textSize
        self.opacity = opacity
        self.animation = animation
    }
}

/// Configuration for watermark animations.
public struct WatermarkAnimation: Equatable {
    public var type: WatermarkAnimationType
    /// Duration in milliseconds for the animation cycle or random position dwell time.
    public var duration: Int64

    public init(type: WatermarkAnimationType, duration: Int64 = 10000) {
        self.type = type
        self.duration = duration
    }
}

/// Supported watermark animation types.
public enum WatermarkAnimationType: Equatable {
    /// Bounces horizontally from edge to edge (ignoring configured `x` coordinate).
    case pingPong
    /// Periodically places the watermark at an unpredictable random position within the visible video area
    /// (ignoring both `x` and `y` coordinates).
    case random
}
