## 1. Watermark Models

- [ ] 1.1 Add `WatermarkConfig` struct with `text: String`, `x: Int` (default 0), `y: Int` (default 0), `color: UInt32` (ARGB, default 0xFFFFFFFF), `textSize: Double` (default 14), `opacity: Double` (default 0.3), `animation: WatermarkAnimation?` (default nil) — matching the Pigeon contract
- [ ] 1.2 Add `WatermarkAnimation` struct with `type: WatermarkAnimationType` and `duration: Int` (milliseconds, default 10000)
- [ ] 1.3 Add `WatermarkAnimationType` enum with a single `.pingPong` case (nil animation = static, matching Flutter/Android)
- [ ] 1.4 Add pure validation/normalization (`validated()`) applying the documented rules: pass empty text through (do not drop), clamp x/y to 0-100, clamp opacity to 0.0-1.0, floor duration at 100 ms, pass textSize and color through

## 2. Static Watermark Rendering

- [ ] 2.1 Add `WatermarkOverlayView` (UIKit) rendering one label per watermark with configurable text, color, opacity, and text size
- [ ] 2.2 Implement percentage positioning against the overlay bounds (player view bounds), keeping each watermark fully visible with a fixed inset (16pt), recomputed in `layoutSubviews`
- [ ] 2.3 Add `setWatermarks(_:)` and `clearWatermarks()` to `TPAVPlayer`, validating once and storing configs, forwarding to the overlay
- [ ] 2.4 Expose public `setWatermarks(_:)` and `clearWatermarks()` on `TPStreamPlayerViewController` forwarding to the player
- [ ] 2.5 Expose public `setWatermarks(_:)` and `clearWatermarks()` on `TPStreamPlayerView` (SwiftUI) forwarding to the player
- [ ] 2.6 Wire overlay into `TPStreamPlayerViewController`'s `containerView` between `subtitleView` and `controlsView` (above video and subtitles, below controls)
- [ ] 2.7 Wire overlay into `TPStreamPlayerView` (SwiftUI, via `UIViewRepresentable` in the ZStack between subtitles and controls)

## 3. Animation Support

- [ ] 3.1 Implement pingPong animation with `CAKeyframeAnimation` on `transform.translation.x`, `autoreverses = true`, `repeatCount = .infinity`: one leg per configured duration, y constant, full-span traversal (x coordinate ignored while animating)
- [ ] 3.2 Support independent animation per watermark layer
- [ ] 3.3 Pause animations when playback is not active (paused, buffering, ended) and resume from the paused position when playback resumes; watermarks remain visible while paused
- [ ] 3.4 Preserve animation continuity on update via value equality: unchanged configs keep their layer/animation, changed configs are re-created

## 4. Player Lifecycle Integration

- [ ] 4.1 Recalculate watermark positions on layout changes (rotation, fullscreen, view resize) using the overlay bounds
- [ ] 4.2 Clean up watermark overlay and animations when the player is released or deinitialized
- [ ] 4.3 Verify watermarks persist through play, pause, seek, buffering, fullscreen, and rotation without regression; verify animation pauses/resumes with playback state
- [ ] 4.4 Verify z-order: overlapping watermarks render with earlier list entries on top (Android/Flutter visual parity)
- [ ] 4.5 Verify validation: out-of-range x/y/opacity clamp, duration below 100 ms floors, empty text still rendered — without crashing
- [ ] 4.6 Update the sample application with static and animated watermark examples mirroring the Android/Flutter example (pingPong at x=0/y=50 and static entries)
- [ ] 4.7 Update SDK documentation with the watermark API reference, configuration defaults, and the note that animated watermarks ignore the x coordinate

## 5. Verification

- [ ] 5.1 Build — `xcodebuild build -project iOSPlayerSDK.xcodeproj -scheme TPStreamsSDK`
- [ ] 5.2 Cross-check model shapes, defaults, and animation semantics against the Flutter Pigeon contract (`pigeons/native_player_api.dart`) and the Android implementation (`WatermarkConfig.kt`, `WatermarkController.kt`)
