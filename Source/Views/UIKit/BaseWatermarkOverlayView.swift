import UIKit

// MARK: - BaseWatermarkOverlayView

class BaseWatermarkOverlayView: UIView {
    static let inset: CGFloat = 16
    static let reservedBandGap: CGFloat = 4

    private(set) var reservedBottomHeight: CGFloat = 0
    private(set) var watermarkContentRect: CGRect?

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

    var effectiveArea: CGRect? {
        let area = watermarkContentRect ?? (bounds.isEmpty ? nil : bounds)
        guard let area = area, !area.isEmpty else { return nil }
        return area
    }

    static func calculateFrame(
        in area: CGRect,
        size: CGSize,
        xFrac: CGFloat,
        yFrac: CGFloat,
        reservedBottom: CGFloat = 0,
        inset: CGFloat = inset
    ) -> CGRect {
        let minX = area.origin.x + inset
        let maxX = max(area.origin.x + area.width - size.width - inset, minX)
        let minY = area.origin.y + inset
        let bottomInset = reservedBottom > 0 ? reservedBottom + reservedBandGap : inset
        let maxY = max(area.origin.y + area.height - size.height - bottomInset, minY)

        return CGRect(
            x: minX + (maxX - minX) * xFrac,
            y: minY + (maxY - minY) * yFrac,
            width: size.width,
            height: size.height
        )
    }
}
