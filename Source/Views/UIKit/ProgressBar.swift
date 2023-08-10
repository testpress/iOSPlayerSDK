import Foundation
import UIKit

class ProgressBar: UIControl {
    public var player: TPStreamPlayer!{
        didSet {
            player.addObserver(self, forKeyPath: #keyPath(TPStreamPlayer.currentTime), options: .new, context: nil)
        }
    }
    private var totalWidth: CGFloat {
        return frame.width
    }
    private var isDragging = false
    private var draggedLocation: CGFloat = 0
    private var watchedWidth: CGFloat = 0
    private var bufferedWidth: CGFloat = 0

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        addTargetEvents()
        setupTapGesture()
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
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: self)
        let tappedPosition = tapLocation.x
        let seconds = getSecondsAtPosition(tappedPosition)
        player.goTo(seconds: seconds)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(TPStreamPlayer.currentTime) {
            watchedWidth = calculateWidthForValue(value: player.currentTime.doubleValue)
            bufferedWidth = calculateWidthForValue(value: player.bufferedDuration)
            setNeedsDisplay()
        }
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
    
    private func updateDraggedLocation(with event: UIEvent) {
        if let touch = event.touches(for: self)?.first {
            let touchLocation = touch.location(in: self)
            draggedLocation = touchLocation.x
        }
    }
    
    private func calculateWidthForValue(value: Float64) -> CGFloat {
        let percentage = CGFloat(value / player.videoDuration)
        return totalWidth * percentage
    }
    
    private func getSecondsAtPosition(_ location: CGFloat) -> Float64 {
        let percentage = Double(location / totalWidth)
        return player.videoDuration * percentage
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let barHeight: CGFloat = 3
        let centerY = rect.height / 2 - barHeight
        
        // Draw the gray background bar
        context.setFillColor(UIColor.gray.withAlphaComponent(0.7).cgColor)
        context.fill(CGRect(x: 0, y: centerY, width: rect.width, height: barHeight))
        
        // Draw the buffered progress bar
        context.setFillColor(UIColor.white.withAlphaComponent(0.6).cgColor)
        context.fill(CGRect(x: 0, y: centerY, width: bufferedWidth, height: barHeight))

        // Draw the played progress bar
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(x: 0, y: centerY, width: watchedWidth, height: barHeight))

        // Draw the draggable circle
        context.setFillColor(UIColor.red.cgColor)
        let circleCenterX = isDragging ? draggedLocation : watchedWidth
        context.fillEllipse(in: CGRect(x: circleCenterX - 9, y: rect.height / 2 - 9, width: 16, height: 16))
    }
}
