import UIKit
import SwiftUI

class WatermarkOverlayView: UIView {

    private let inset: CGFloat = 16
    /// Minimum gap kept between the watermark and the reserved bottom band.
    private let reservedBandGap: CGFloat = 4
    private var watermarks: [WatermarkConfig] = []
    private var labels: [UILabel] = []
    private var reservedBottomHeight: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    func setWatermarks(_ configs: [WatermarkConfig]) {
        let clamped = configs.map(clampedToValidBounds)
        guard clamped != watermarks else { return }
        watermarks = clamped
        rebuildWatermarkLabels()
        setNeedsLayout()
    }

    /// Reserves a band of `height` at the bottom (e.g. for subtitles) that watermarks
    /// must stay above. Watermark positions are then mapped to the remaining space
    /// above the band, keeping a small gap. Pass 0 to disable.
    func setReservedBottomHeight(_ height: CGFloat) {
        let clamped = max(height, 0)
        guard clamped != reservedBottomHeight else { return }
        reservedBottomHeight = clamped
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        for (label, config) in zip(labels, watermarks) {
            label.frame = positionedFrame(for: label, at: config)
        }
    }

    /// Clamps out-of-range values to valid bounds for watermark configuration.
    private func clampedToValidBounds(_ config: WatermarkConfig) -> WatermarkConfig {
        var config = config
        config.x = min(max(config.x, 0), 100)
        config.y = min(max(config.y, 0), 100)
        config.opacity = min(max(config.opacity, 0), 1)
        return config
    }

    private func rebuildWatermarkLabels() {
        labels.forEach { $0.removeFromSuperview() }
        labels = watermarks.map(watermarkLabel(for:))
        labels.reversed().forEach(addSubview)
    }

    private func watermarkLabel(for config: WatermarkConfig) -> UILabel {
        let label = UILabel()
        label.text = config.text
        label.font = UIFont.systemFont(ofSize: CGFloat(config.textSize))
        label.textColor = color(for: config)
        label.numberOfLines = 0
        label.clipsToBounds = true
        return label
    }

    private func positionedFrame(for label: UILabel, at config: WatermarkConfig) -> CGRect {
        let maxWidth = max(bounds.width - 2 * inset, 0)
        let size = label.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        let horizontalSpan = max(bounds.width - size.width - 2 * inset, 0)
        let x = inset + horizontalSpan * CGFloat(config.x) / 100

        let top = inset
        let bottomLimit: CGFloat
        if reservedBottomHeight > 0 {
            // Stay just above the reserved band instead of applying the full inset.
            bottomLimit = max(bounds.height - size.height - reservedBottomHeight - reservedBandGap, top)
        } else {
            bottomLimit = bounds.height - size.height - inset
        }
        let y = top + (bottomLimit - top) * CGFloat(config.y) / 100
        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }

    private func color(for config: WatermarkConfig) -> UIColor {
        let value = UInt32(truncatingIfNeeded: config.color)
        let alpha = CGFloat((value >> 24) & 0xFF) / 255
        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255
        return UIColor(red: red, green: green, blue: blue, alpha: alpha * CGFloat(config.opacity))
    }
}

@available(iOS 14.0, *)
struct WatermarkOverlayViewRepresentable: UIViewRepresentable {
    let watermarks: [WatermarkConfig]
    let reservedBottomHeight: CGFloat

    func makeUIView(context: Context) -> WatermarkOverlayView {
        WatermarkOverlayView(frame: .zero)
    }

    func updateUIView(_ uiView: WatermarkOverlayView, context: Context) {
        uiView.setWatermarks(watermarks)
        uiView.setReservedBottomHeight(reservedBottomHeight)
    }
}
