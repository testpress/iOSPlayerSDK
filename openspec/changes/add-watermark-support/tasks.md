## 1. Watermark Models

- [x] 1.1 Add `WatermarkConfig` struct with `text: String`, `x: Int64` (default 0), `y: Int64` (default 0), `color: Int64` (ARGB, default 0xFFFFFFFF), `textSize: Double` (default 14), `opacity: Double` (default 0.3), `animation: WatermarkAnimation?` (default nil) — matching the Pigeon contract
- [x] 1.2 Add `WatermarkAnimation` struct with `type: WatermarkAnimationType` and `duration: Int64` (milliseconds, default 10000)
- [x] 1.3 Add `WatermarkAnimationType` enum with a single `.pingPong` case (nil animation = static, matching Flutter/Android)

## 2. Static Watermark Rendering

- [x] 2.1 Add `WatermarkOverlayView` (UIKit) rendering one label per watermark with configurable text, color, opacity, and text size
- [x] 2.2 Implement percentage positioning against the overlay bounds (player view bounds), keeping each watermark fully visible with a fixed inset (16pt), recomputed in `layoutSubviews`
- [x] 2.3 Add `watermarks: [WatermarkConfig]` to `TPStreamPlayerConfiguration` with builder `setWatermarks(_:)` (default empty); normalize once when the config is applied to the overlay
- [x] 2.4 Extend `TPStreamPlayerViewController.config.didSet` to re-apply the watermark overlay (runtime config changes on the UIKit path)
- [x] 2.5 Apply `playerViewConfig.watermarks` to the overlay when `TPStreamPlayerView` is set up (init-time, matching its other config fields)
- [x] 2.6 Wire overlay into `TPStreamPlayerViewController`'s `containerView` between `videoView` and `subtitleView` (above video, below subtitles and controls). Pass `SubtitleView.reservedBottomBandHeight` as the reserved bottom height so watermarks stay above the subtitle band.
- [x] 2.7 Wire overlay into `TPStreamPlayerView` (SwiftUI, via `UIViewRepresentable` in the ZStack before the subtitle view — above video, below subtitles and controls). Pass reserved bottom height when subtitles are active.

## 3. Animation Support

- [x] 3.1 Implement pingPong animation with `CAKeyframeAnimation` on `transform.translation.x`, `autoreverses = true`, `repeatCount = .infinity`: one leg per configured duration, y constant, full-span traversal (x coordinate ignored while animating)
- [x] 3.2 Support independent animation per watermark layer
- [x] 3.3 Pause animations when playback is not active (paused, buffering, ended) and resume from the paused position when playback resumes; watermarks remain visible while paused. Playback state is observed by the presentation views (they already hold the player), not `TPAVPlayer`
- [x] 3.4 Preserve animation continuity on update via value equality: unchanged configs keep their layer/animation, changed configs are re-created

## 4. Player Lifecycle Integration

- [x] 4.1 Recalculate watermark positions on layout changes (rotation, fullscreen, view resize) using the overlay bounds
- [x] 4.2 Clean up watermark overlay and animations when the player view is released or deinitialized
- [x] 4.3 Verify watermarks persist through play, pause, seek, buffering, fullscreen, and rotation without regression; verify animation pauses/resumes with playback state
- [x] 4.4 Verify z-order: overlapping watermarks render with earlier list entries on top (Android/Flutter visual parity)
- [x] 4.5 Verify normalization: out-of-range x/y/opacity clamp, duration below 100 ms floors, empty text still rendered — without crashing
- [x] 4.6 Update the sample application with static and animated watermark examples mirroring the Android/Flutter example (pingPong at x=0/y=50 and static entries)
- [x] 4.7 Update SDK documentation with the watermark configuration reference, configuration defaults, and the note that animated watermarks ignore the x coordinate

## 5. Verification

- [x] 5.1 Build — `xcodebuild build -project iOSPlayerSDK.xcodeproj -scheme TPStreamsSDK`
- [x] 5.2 Cross-check model shapes, defaults, and animation semantics against the Flutter Pigeon contract (`pigeons/native_player_api.dart`) and the Android implementation (`WatermarkConfig.kt`, `WatermarkController.kt`)
