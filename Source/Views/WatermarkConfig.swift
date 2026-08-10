import Foundation

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

public struct WatermarkAnimation: Equatable {
    public var type: WatermarkAnimationType
    public var duration: Int64

    public init(type: WatermarkAnimationType, duration: Int64 = 10000) {
        self.type = type
        self.duration = duration
    }
}

public enum WatermarkAnimationType: Equatable {
    case pingPong
}
