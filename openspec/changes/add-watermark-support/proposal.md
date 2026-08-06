## Why

The Android SDK and the Flutter SDK already expose a watermark API, and the Flutter bridge's iOS implementation (`NativePlayerView.swift`) stubs `setWatermarks`/`clearWatermarks` as no-ops ("currently not supported on iOS"). Content providers on iOS cannot display user-identifying or branding watermarks during playback, and Flutter applications get an inconsistent cross-platform experience. This change implements the existing cross-platform contract on iOS, bringing it to parity with the Android/Flutter implementations.

The source of truth for the API shape is the Flutter Pigeon contract (`pigeons/native_player_api.dart`), which the Android implementation maps 1:1. This proposal matches that contract, not a redesigned variant.

## What Changes

- Add public watermark models matching the Pigeon contract: `WatermarkConfig` (`text`, `x`, `y`, `color`, `textSize`, `opacity`, `animation`) and `WatermarkAnimation` (`type`, `duration` in milliseconds) with the same defaults (opacity `0.3`, duration `10000`, min `100`).
- Add public `setWatermarks(_:)` and `clearWatermarks()` on `TPAVPlayer` (which owns the normalized state and overlay lifecycle), forwarded publicly from both presentation paths: `TPStreamPlayerViewController` (UIKit) and `TPStreamPlayerView` (SwiftUI).
- Render one or more text watermarks over the video content using percentage-based x/y positioning against the player view bounds, with each watermark kept fully visible inside a small fixed inset.
- Support static watermarks and a `pingPong` animation that bounces the watermark horizontally (left→right→left), one leg per configured duration, matching the Android `ValueAnimator` REVERSE behavior. The animation pauses when playback pauses or ends and resumes on play; the watermark stays visible.
- Reposition watermarks on rotation, fullscreen transitions, and view resize.
- Remove all watermarks and stop all animations when the player is released or deinitialized.
- Normalize configurations at set time with documented defaults: clamp x/y and opacity to bounds, floor animation duration at 100 ms; empty text passes through and still renders (matching Android/Flutter). Never crash on invalid input (divergence from Android's `require()` crash, which is a known Android bug). The models themselves are plain data with no validation, matching the codebase convention.
- Update the sample app and SDK documentation with static and animated watermark examples mirroring the Android/Flutter examples.

## Capabilities

### New Capabilities

- `watermark`: Display one or more text watermarks over video playback with percentage-based positioning, configurable appearance, optional pingPong animation, and API parity with the existing Android/Flutter SDKs.

### Modified Capabilities

None — no existing specs to modify.

## Impact

- **Public API**: New `WatermarkConfig`, `WatermarkAnimation`, `WatermarkAnimationType`, and `setWatermarks(_:)`/`clearWatermarks()` on `TPAVPlayer`, `TPStreamPlayerViewController`, and `TPStreamPlayerView`. Backward compatible; no existing APIs change.
- **Playback UI**: Watermark overlay layer rendered above video content (and subtitles), below player controls, in both UIKit and SwiftUI paths.
- **Lifecycle**: Watermark cleanup on player release; repositioning on layout changes (rotation, fullscreen, resize).
- **Sample app**: New watermark examples in the demo application.
- **Docs**: SDK documentation updated with the watermark API and configuration reference.
- **Consumers**: The existing Flutter SDK bridge consumes the API through the Pigeon-generated `NativePlayerApi` (`setWatermarks`/`clearWatermarks`), which maps directly onto the new `TPAVPlayer`/`TPStreamPlayerViewController` methods without platform-specific changes.
