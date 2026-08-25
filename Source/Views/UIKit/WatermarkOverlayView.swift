import UIKit
import SwiftUI

// MARK: - WatermarkOverlayView

class WatermarkOverlayView: UIView {
    private var watermarks: [WatermarkConfig] = []
    private var watermarkLabels: [WatermarkLabel] = []
    private var reservedBottomHeight: CGFloat = 0
    private var watermarkContentRect: CGRect?
    private var isPaused = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    func setWatermarks(_ configs: [WatermarkConfig]) {
        guard configs != watermarks else { return }
        watermarks = configs
        watermarkLabels.forEach { $0.removeFromSuperview() }
        watermarkLabels = configs.map { WatermarkLabel(config: $0) }
        watermarkLabels.reversed().forEach(addSubview)
        setNeedsLayout()
    }

    func setReservedBottomHeight(_ height: CGFloat) {
        let clamped = max(height, 0)
        guard clamped != reservedBottomHeight else { return }
        reservedBottomHeight = clamped
        setNeedsLayout()
    }

    func setWatermarkContentRect(_ rect: CGRect) {
        let effective = rect.isNull || rect.isEmpty ? nil : rect
        guard effective != watermarkContentRect else { return }
        watermarkContentRect = effective
        setNeedsLayout()
    }

    func pauseWatermarks() {
        guard !isPaused else { return }
        isPaused = true
        watermarkLabels.forEach { $0.pause() }
    }

    func resumeWatermarks() {
        guard isPaused else { return }
        isPaused = false
        watermarkLabels.forEach { $0.resume() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let area = watermarkContentRect ?? (bounds.isEmpty ? nil : bounds)
        guard let area = area, !area.isEmpty else {
            watermarkLabels.forEach { $0.isHidden = true }
            return
        }
        for label in watermarkLabels {
            label.isHidden = false
            label.layoutIn(area: area, reservedBottom: reservedBottomHeight, isPaused: isPaused)
        }
    }
}

// MARK: - WatermarkLabel

private class WatermarkLabel: UILabel {
    static let inset: CGFloat = 16
    static let reservedBandGap: CGFloat = 4

    let config: WatermarkConfig
    private var xFrac: CGFloat = 0
    private var yFrac: CGFloat = 0
    private var isFrozen = false
    private var animationStartTime: CFTimeInterval?
    private var lastHorizontalSpan: CGFloat?
    private var timer: Timer?
    private var timeRemaining: TimeInterval = 0
    private var lastMoveTimestamp: CFTimeInterval = 0
    private var lastContentArea: CGRect = .zero
    private var lastReservedBottom: CGFloat = 0

    init(config: WatermarkConfig) {
        self.config = config
        super.init(frame: .zero)
        setupAppearance()
        initCoordinates()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }

    private func setupAppearance() {
        text = config.text
        font = UIFont.systemFont(ofSize: CGFloat(config.textSize))
        textColor = UIColor(argb: config.color, opacity: min(max(config.opacity, 0), 1))
        numberOfLines = 0
        clipsToBounds = true
    }

    private func initCoordinates() {
        let duration = Double(max(config.animation?.duration ?? 10000, 100)) / 1000.0
        timeRemaining = duration

        switch config.animation?.type {
        case .random:
            xFrac = .random(in: 0...1)
            yFrac = .random(in: 0...1)
        case .pingPong:
            xFrac = 0
            yFrac = CGFloat(min(max(config.y, 0), 100)) / 100.0
        case .none:
            xFrac = CGFloat(min(max(config.x, 0), 100)) / 100.0
            yFrac = CGFloat(min(max(config.y, 0), 100)) / 100.0
        }
    }

    func layoutIn(area: CGRect, reservedBottom: CGFloat, isPaused: Bool) {
        self.lastContentArea = area
        self.lastReservedBottom = reservedBottom
        self.isFrozen = isPaused

        layer.transform = CATransform3DIdentity
        frame = calculateFrame(in: area, reservedBottom: reservedBottom)

        if let animation = config.animation {
            switch animation.type {
            case .pingPong:
                setupPingPongAnimation(duration: max(animation.duration, 100), area: area)
            case .random:
                if !isPaused && timer == nil {
                    scheduleRandomTimer(interval: timeRemaining)
                }
            }
        }
    }

    func pause() {
        guard !isFrozen else { return }
        isFrozen = true
        if config.animation?.type == .random {
            timer?.invalidate()
            timer = nil
            let elapsed = CACurrentMediaTime() - lastMoveTimestamp
            timeRemaining = max(0, timeRemaining - elapsed)
        }
        pauseLayer(layer)
    }

    func resume() {
        guard isFrozen else { return }
        isFrozen = false
        resumeLayer(layer)
        if config.animation?.type == .random {
            let duration = Double(max(config.animation?.duration ?? 10000, 100)) / 1000.0
            let interval = timeRemaining > 0 ? timeRemaining : duration
            scheduleRandomTimer(interval: interval)
        }
    }

    private func calculateFrame(in area: CGRect, reservedBottom: CGFloat) -> CGRect {
        let maxWidth = max(area.width - 2 * Self.inset, 0)
        let size = sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        let minX = area.origin.x + Self.inset
        let maxX = max(area.origin.x + area.width - size.width - Self.inset, minX)
        let minY = area.origin.y + Self.inset
        let bottomInset = reservedBottom > 0 ? reservedBottom + Self.reservedBandGap : Self.inset
        let maxY = max(area.origin.y + area.height - size.height - bottomInset, minY)

        return CGRect(
            x: minX + (maxX - minX) * xFrac,
            y: minY + (maxY - minY) * yFrac,
            width: size.width,
            height: size.height
        )
    }

    private func scheduleRandomTimer(interval: TimeInterval) {
        timer?.invalidate()
        lastMoveTimestamp = CACurrentMediaTime()
        timeRemaining = interval

        timer = Timer.scheduledTimer(withTimeInterval: max(interval, 0.05), repeats: false) { [weak self] _ in
            self?.moveToNextRandomPosition()
        }
    }

    private func moveToNextRandomPosition() {
        guard let animation = config.animation, lastContentArea.width > 0 else { return }
        xFrac = .random(in: 0...1)
        yFrac = .random(in: 0...1)

        let duration = Double(max(animation.duration, 100)) / 1000.0
        let newFrame = calculateFrame(in: lastContentArea, reservedBottom: lastReservedBottom)

        if !isFrozen {
            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
                self.frame = newFrame
            }
            scheduleRandomTimer(interval: duration)
        } else {
            frame = newFrame
        }
    }

    private func setupPingPongAnimation(duration: Int64, area: CGRect) {
        let horizontalSpan = max(area.width - frame.width - 2 * Self.inset, 0)
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.values = [0, horizontalSpan]
        anim.keyTimes = [0, 1]
        anim.duration = Double(duration) / 1000.0
        anim.autoreverses = true
        anim.repeatCount = .infinity

        let now = CACurrentMediaTime()
        if let storedStartTime = animationStartTime, let storedSpan = lastHorizontalSpan, storedSpan > 0 {
            let elapsed = now - storedStartTime
            let roundTrip = anim.duration * 2
            anim.timeOffset = elapsed.truncatingRemainder(dividingBy: roundTrip)
        } else {
            animationStartTime = now
        }
        lastHorizontalSpan = horizontalSpan

        layer.removeAllAnimations()
        layer.add(anim, forKey: "watermarkAnimation")
        if isFrozen {
            pauseLayer(layer)
        }
    }

    private func pauseLayer(_ layer: CALayer) {
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0
        layer.timeOffset = pausedTime
    }

    private func resumeLayer(_ layer: CALayer) {
        let pausedTime = layer.timeOffset
        layer.speed = 1
        layer.timeOffset = 0
        layer.beginTime = 0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
}

// MARK: - SwiftUI Bridge

@available(iOS 14.0, *)
struct WatermarkOverlayViewRepresentable: UIViewRepresentable {
    let watermarks: [WatermarkConfig]
    let reservedBottomHeight: CGFloat
    let labelsAreFrozen: Bool
    let watermarkContentRect: CGRect

    func makeUIView(context: Context) -> WatermarkOverlayView {
        let view = WatermarkOverlayView(frame: .zero)
        view.setWatermarks(watermarks)
        view.setReservedBottomHeight(reservedBottomHeight)
        view.setWatermarkContentRect(watermarkContentRect)
        if labelsAreFrozen {
            view.pauseWatermarks()
        }
        return view
    }

    func updateUIView(_ uiView: WatermarkOverlayView, context: Context) {
        uiView.setWatermarks(watermarks)
        uiView.setReservedBottomHeight(reservedBottomHeight)
        uiView.setWatermarkContentRect(watermarkContentRect)
        if labelsAreFrozen {
            uiView.pauseWatermarks()
        } else {
            uiView.resumeWatermarks()
        }
    }
}
