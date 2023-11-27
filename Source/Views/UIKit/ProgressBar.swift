import Foundation
import UIKit

fileprivate let DRAGGABLE_THUMB_SIZE = 12.0

class ProgressBar: UIControl {
    public var player: TPStreamPlayer!{
        didSet {
            player.addObserver(self, forKeyPath: #keyPath(TPStreamPlayer.currentTime), options: .new, context: nil)
        }
    }
    private var totalWidth: CGFloat {
        return frame.width - DRAGGABLE_THUMB_SIZE
    }
    private var isDragging = false
    private var draggedLocation: CGFloat = 0
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        addTargetEvents()
        setupTapGesture()
        addObserver(self, forKeyPath: #keyPath(bounds), options: [.old, .new], context: nil)
    }
    
    private func addTargetEvents() {
        addTarget(self, action: #selector(handleTouchDown(_:for:)), for: .touchDown)
        addTarget(self, action: #selector(handleDrag(_:for:)), for: [.touchDragInside, .touchDragOutside, .touchDragEnter, .touchDragExit])
        addTarget(self, action: #selector(handleTouchUpInside(_:for:)), for: .touchUpInside)
        addTarget(self, action: #selector(handleTouchUpOutside(_:for:)), for: [.touchUpOutside, .touchCancel])
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
        
    @objc private func handleTouchDown(_ sender: UIControl, for event: UIEvent) {
        isDragging = true
        updateDraggedLocation(with: event)
        setNeedsDisplay()
    }
    
    @objc private func handleDrag(_ sender: UIControl, for event: UIEvent) {
        updateDraggedLocation(with: event)
        setNeedsDisplay()
    }
    
    @objc private func handleTouchUpInside(_ sender: UIControl, for event: UIEvent) {
        isDragging = false
        updateDraggedLocation(with: event)
        setNeedsDisplay()
        
        let seconds = getSecondsAtPosition(draggedLocation)
        player.goTo(seconds: seconds)
    }
    
    @objc private func handleTouchUpOutside(_ sender: UIControl, for event: UIEvent) {
        isDragging = false
        setNeedsDisplay()
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: self)
        let seconds = getSecondsAtPosition(tapLocation.x)
        player.goTo(seconds: seconds)
    }
    
    private func updateDraggedLocation(with event: UIEvent) {
        if let touch = event.touches(for: self)?.first {
            let touchLocation = touch.location(in: self)
            draggedLocation = min(touchLocation.x, totalWidth)
        }
    }
    
    private func getSecondsAtPosition(_ location: CGFloat) -> Float64 {
        let percentage = min(Double(location / totalWidth), 100.0)
        return player.videoDuration * percentage
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case #keyPath(TPStreamPlayer.currentTime):
            setNeedsDisplay()
        case #keyPath(bounds):
            if let newBounds = change?[.newKey] as? CGRect, let oldBounds = change?[.oldKey] as? CGRect, newBounds != oldBounds {
                setNeedsDisplay()
            }
        default:
            break
        }
    }
    
    private func calculateWidthForValue(value: Float64) -> CGFloat {
        let percentage = min(CGFloat(value / player.videoDuration), 100.0)
        return totalWidth * percentage
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let watchedWidth = calculateWidthForValue(value: player.currentTime.doubleValue)
        let bufferedWidth = calculateWidthForValue(value: player.bufferedDuration)
        
        drawBar(context, width: totalWidth, color: UIColor.gray.withAlphaComponent(0.7).cgColor) // Gray background bar
        drawBar(context, width: bufferedWidth, color: UIColor.white.withAlphaComponent(0.6).cgColor) // Buffered progress bar
        drawBar(context, width: watchedWidth, color: UIColor.red.cgColor) // Watched progress bar
        drawDraggableThumb(context, watchedWidth)
    }
    
    private func drawBar(_ context: CGContext, width: CGFloat, color: CGColor){
        context.setFillColor(color)
        context.fill(CGRect(x: DRAGGABLE_THUMB_SIZE / 2, y: 5, width: width, height: 3))
    }
    
    private func drawDraggableThumb(_ context: CGContext, _ watchedWidth: CGFloat){
        context.setFillColor(UIColor.red.cgColor)
        let circleCenterX = (isDragging ? draggedLocation : watchedWidth)
        let size = isDragging ? DRAGGABLE_THUMB_SIZE + 2 : DRAGGABLE_THUMB_SIZE
        context.fillEllipse(in: CGRect(x: max(0, circleCenterX), y: 0, width: size, height: size))
    }
}
