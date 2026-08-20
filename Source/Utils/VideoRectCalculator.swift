import CoreGraphics

enum VideoRectCalculator {

    static func calculate(
        videoSize: CGSize,
        containerSize: CGSize
    ) -> CGRect {
        guard
            videoSize.width > 0,
            videoSize.height > 0,
            containerSize.width > 0,
            containerSize.height > 0
        else {
            return .zero
        }

        let videoAspect = videoSize.width / videoSize.height
        let containerAspect = containerSize.width / containerSize.height

        let renderedSize: CGSize

        if videoAspect > containerAspect {
            renderedSize = CGSize(
                width: containerSize.width,
                height: containerSize.width / videoAspect
            )
        } else {
            renderedSize = CGSize(
                width: containerSize.height * videoAspect,
                height: containerSize.height
            )
        }

        return CGRect(
            x: (containerSize.width - renderedSize.width) / 2,
            y: (containerSize.height - renderedSize.height) / 2,
            width: renderedSize.width,
            height: renderedSize.height
        )
    }
}
