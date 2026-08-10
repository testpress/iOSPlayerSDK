import UIKit
import SwiftUI

class WatermarkOverlayView: UIView {

    private let inset: CGFloat = 16
    private var watermarks: [WatermarkConfig] = []
    private var labels: [UILabel] = []

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
        let clamped = configs.map(clampingToDocumentedDefaults)
        guard clamped != watermarks else { return }
        watermarks = clamped
        rebuildWatermarkLabels()
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        for (label, config) in zip(labels, watermarks) {
            label.frame = positionedFrame(for: label, at: config)
        }
    }

    /// Clamps out-of-range values to the bounds pinned by the Flutter/Android
    /// contract (x/y 0-100, opacity 0-1) so invalid configs render instead of
    /// crashing — Android's `require()` crash is a documented upstream bug we
    /// deliberately don't reproduce.
    private func clampingToDocumentedDefaults(_ config: WatermarkConfig) -> WatermarkConfig {
        var config = config
        config.x = min(max(config.x, 0), 100)
        config.y = min(max(config.y, 0), 100)
        config.opacity = min(max(config.opacity, 0), 1)
        return config
    }

    private func rebuildWatermarkLabels() {
        labels.forEach { $0.removeFromSuperview() }
        labels = watermarks.map(makeLabel)
        labels.reversed().forEach(addSubview)
    }

    private func makeLabel(for config: WatermarkConfig) -> UILabel {
        let label = UILabel()
        label.text = config.text
        label.font = UIFont.systemFont(ofSize: CGFloat(config.textSize))
        label.textColor = color(for: config)
        label.numberOfLines = 0
        return label
    }

    private func positionedFrame(for label: UILabel, at config: WatermarkConfig) -> CGRect {
        let maxWidth = max(bounds.width - 2 * inset, 0)
        let size = label.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        let horizontalSpan = max(bounds.width - size.width - 2 * inset, 0)
        let verticalSpan = max(bounds.height - size.height - 2 * inset, 0)
        let x = inset + horizontalSpan * CGFloat(config.x) / 100
        let y = inset + verticalSpan * CGFloat(config.y) / 100
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

    func makeUIView(context: Context) -> WatermarkOverlayView {
        WatermarkOverlayView(frame: .zero)
    }

    func updateUIView(_ uiView: WatermarkOverlayView, context: Context) {
        uiView.setWatermarks(watermarks)
    }
}
