import UIKit
import SwiftUI

// MARK: - ImageWatermarkOverlayView

class ImageWatermarkOverlayView: BaseWatermarkOverlayView {
    private var configs: [ImageWatermarkConfig] = []
    private var imageViews: [ImageWatermarkItemView] = []
    private var areControlsVisible: Bool = false

    func setImageWatermarks(_ newConfigs: [ImageWatermarkConfig]) {
        guard newConfigs != configs else { return }
        configs = newConfigs
        imageViews.forEach { $0.removeFromSuperview() }
        imageViews = newConfigs.map { ImageWatermarkItemView(config: $0) }
        imageViews.reversed().forEach(addSubview)
        updateVisibility(animated: false)
        setNeedsLayout()
    }

    func clearImageWatermarks() {
        setImageWatermarks([])
    }

    func setControlsVisible(_ isVisible: Bool, animated: Bool = true) {
        guard isVisible != areControlsVisible else { return }
        areControlsVisible = isVisible
        updateVisibility(animated: animated)
    }

    private func updateVisibility(animated: Bool) {
        let updateAlpha = {
            for itemView in self.imageViews {
                itemView.alpha = self.areControlsVisible ? 0.0 : CGFloat(itemView.config.opacity)
            }
        }

        if animated {
            UIView.animate(withDuration: 0.15, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: updateAlpha)
        } else {
            updateAlpha()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let area = effectiveArea else {
            imageViews.forEach { $0.isHidden = true }
            return
        }
        for itemView in imageViews {
            itemView.isHidden = false
            itemView.layoutIn(area: area)
        }
    }
}

// MARK: - ImageWatermarkItemView

private class ImageWatermarkItemView: UIImageView {
    static let imageCache = NSCache<NSString, UIImage>()

    let config: ImageWatermarkConfig
    private var dataTask: URLSessionDataTask?

    init(config: ImageWatermarkConfig) {
        self.config = config
        super.init(frame: .zero)
        setupAppearance()
        loadImage()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        dataTask?.cancel()
    }

    private func setupAppearance() {
        contentMode = .scaleAspectFit
        clipsToBounds = true
        isUserInteractionEnabled = false
        alpha = CGFloat(config.opacity)
    }

    private func loadImage() {
        let cacheKey = config.imageUrl as NSString
        if let cachedImage = Self.imageCache.object(forKey: cacheKey) {
            self.image = cachedImage
            return
        }

        guard let url = URL(string: config.imageUrl) else {
            print("[ImageWatermark] Invalid image URL: \(config.imageUrl)")
            return
        }

        dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                if (error as NSError).code != NSURLErrorCancelled {
                    print("[ImageWatermark] Failed to load image from \(url): \(error.localizedDescription)")
                }
                return
            }

            guard let data = data, let downloadedImage = UIImage(data: data) else {
                print("[ImageWatermark] Could not decode image data from \(url)")
                return
            }

            Self.imageCache.setObject(downloadedImage, forKey: cacheKey)

            DispatchQueue.main.async {
                self?.image = downloadedImage
            }
        }
        dataTask?.resume()
    }

    func layoutIn(area: CGRect) {
        let size = CGSize(width: CGFloat(config.width), height: CGFloat(config.height))
        let xFrac = CGFloat(min(max(config.x, 0), 100)) / 100.0
        let yFrac = CGFloat(min(max(config.y, 0), 100)) / 100.0

        frame = BaseWatermarkOverlayView.calculateFrame(
            in: area,
            size: size,
            xFrac: xFrac,
            yFrac: yFrac,
            reservedBottom: 0,
            inset: 0
        )
    }
}

// MARK: - SwiftUI Bridge

@available(iOS 14.0, *)
struct ImageWatermarkOverlayViewRepresentable: UIViewRepresentable {
    let imageWatermarks: [ImageWatermarkConfig]
    let isControlsVisible: Bool
    let watermarkContentRect: CGRect

    func makeUIView(context: Context) -> ImageWatermarkOverlayView {
        let view = ImageWatermarkOverlayView(frame: .zero)
        view.setImageWatermarks(imageWatermarks)
        view.setWatermarkContentRect(watermarkContentRect)
        view.setControlsVisible(isControlsVisible, animated: false)
        return view
    }

    func updateUIView(_ uiView: ImageWatermarkOverlayView, context: Context) {
        uiView.setImageWatermarks(imageWatermarks)
        uiView.setWatermarkContentRect(watermarkContentRect)
        uiView.setControlsVisible(isControlsVisible, animated: true)
    }
}
