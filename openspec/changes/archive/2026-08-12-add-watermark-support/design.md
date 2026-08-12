## Context

The iOS Player SDK has two presentation paths: a UIKit path (`TPStreamPlayerViewController`, layering `videoView` (AVPlayerLayer) → `watermarkOverlayView` → `subtitleView` → `controlsView` inside `containerView`, with `noticeView` on top) and a SwiftUI path (`TPStreamPlayerView`, a ZStack of the video view, controls, and an optional `SubtitleTextView`). Playback is driven by `TPAVPlayer`.

The cross-platform watermark contract is defined by the Flutter Pigeon API (`pigeons/native_player_api.dart` in the Flutter SDK), implemented 1:1 by the Android SDK (`WatermarkConfig.kt`, `WatermarkController.kt`, `TPStreamsPlayerView.setWatermarks`). The Flutter bridge's iOS side (`NativePlayerView.swift`) currently stubs `setWatermarks`/`clearWatermarks` as no-ops. This design implements that contract on iOS. The Flutter plugin holds a `TPStreamPlayerViewController` and a `TPAVPlayer` directly (it never touches the internal `TPStreamPlayer` manager); watermarks are exposed through the VC's configuration, which the plugin can set.

## Goals / Non-Goals

**Goals:**
- Public models matching the Pigeon contract, exposed as `watermarks` on `TPStreamPlayerConfiguration` (builder `setWatermarks(_:)`); the UIKit path supports runtime updates through the existing mutable `config` property.
- Watermark overlay above video, below subtitles and player controls, in both UIKit and SwiftUI paths. Watermarks respect the subtitle reserved bottom band to avoid overlap.
- Percentage positioning against the player view bounds, recalculated on layout changes, watermarks always fully visible.
- Normalization with documented defaults; never crash on invalid input.
- `pingPong` animation matching Android behavior (horizontal bounce, pause/resume with playback).

**Non-Goals:**
- Image/logo watermarks, interactivity, custom animation types, text formatting, rotation/scaling, persistence across player instances.
- Embedding watermarks into the video stream (overlay only).
- Redesigning the cross-platform contract (shape, defaults, and semantics are pinned by the existing Flutter/Android implementations).
- Fixing the Android SDK's `require()` crash (tracked as an upstream Android issue).

## Decisions

**1. Contract pinned to the Flutter Pigeon API, verified against Android.**
The public models and semantics mirror `pigeons/native_player_api.dart` exactly: `WatermarkConfig(text, x: Int, y: Int, color: ARGB, textSize: Double, opacity: Double, animation: WatermarkAnimation?)` with defaults `x=0`, `y=0`, `color=0xFFFFFFFF`, `textSize=14`, `opacity=0.3`, `animation=nil`; `WatermarkAnimation(type, duration: Int ms)` with default `10000` and floor `100`. The Android SDK (`WatermarkConfig.kt`) has identical shapes and defaults (opacity `0.3f`, duration `10000L`, `MIN_DURATION_MS=100`), so matching Flutter matches Android. Field types follow the Pigeon-generated Swift (`NativePlayerApi.g.swift`): `x/y` Int64, `color` Int64 (ARGB), `textSize`/`opacity` Double, `duration` Int64. The iOS surface is the player configuration (Decision 2) rather than the imperative Pigeon methods — a documented platform divergence; model shapes, defaults, and semantics remain pinned. *Alternatives:* inventing an iOS-specific design (original draft) — rejected because it fabricated defaults (opacity 1.0, duration 2000) that exist nowhere in Flutter or Android.

**2. Watermark configuration lives in `TPStreamPlayerConfiguration`; no API on `TPAVPlayer`.**
Watermarks are content-presentation configuration, so they are declared in the player configuration: `TPStreamPlayerConfiguration.watermarks: [WatermarkConfig]` (builder `setWatermarks(_:)`, default empty). `TPAVPlayer` stays a pure playback engine with no watermark surface. Both presentation paths apply the configuration: `TPStreamPlayerViewController` already exposes `public var config` with a `didSet` that re-applies to the controls (Source/TPStreamPlayerViewController.swift:44) — that observer is extended to re-apply the watermark overlay, giving runtime updates on the UIKit path (mutating `config.watermarks` re-applies without player recreation). `TPStreamPlayerView` (SwiftUI) applies `playerViewConfig.watermarks` at setup, matching how its other configuration fields behave (init-time). The internal `TPStreamPlayer` manager is not part of the API because the bridge never uses it. *Alternatives:* imperative `setWatermarks(_:)`/`clearWatermarks()` on `TPAVPlayer` (previous draft) — rejected per product decision: watermarks are configuration, and the config property is already runtime-mutable, so a second imperative surface on the player would duplicate state and split ownership.

**3. Overlay as one shared `WatermarkOverlayView` (UIKit), reused by SwiftUI via `UIViewRepresentable`.**
Same pattern as subtitles: the UIKit path inserts it into `containerView` between `videoView` and `subtitleView` (z-order: video → watermarks → subtitles → controls); the SwiftUI path wraps it in a representable inside the ZStack, before the subtitle view. Rendering, layout, and animation logic live in one file; the UI-path code is thin wiring only. The overlay is owned by the presentation views (which read the config), not by `TPAVPlayer`. Positioning against view bounds (decision 4) removes any dependency on `AVPlayerLayer.videoRect` or the private `playerLayer` property.

When subtitles are active, the overlay receives a reserved bottom height (`SubtitleView.reservedBottomBandHeight`) that defines the vertical region occupied by subtitles. Watermarks are constrained to position above this band, preventing overlap between watermark text and subtitle text. This is handled by `WatermarkOverlayView.setReservedBottomHeight(_:)` — a generic API that takes a height value without knowledge of subtitles. Watermark labels have `clipsToBounds = true` to prevent oversized watermarks from bleeding into the reserved area.

**4. Percentage positioning against player view bounds, watermark kept fully visible inside a fixed inset.**
Matches Android `WatermarkController.placeAt`: x/y are percentages of the overlay's bounds (which equal the player view bounds in both UI paths); the watermark's leading/trailing edges are clamped so it stays fully on-screen with a small inset (Android uses 16dp; iOS uses 16pt). x=0 aligns the leading edge to the left inset, x=100 aligns the trailing edge to the right inset. Positions are recomputed on every layout pass. *Alternatives:* positioning against `AVPlayerLayer.videoRect` (original draft) — rejected: Android positions against the player view, so parity requires view-relative coordinates; it also avoids the private-`playerLayer` access problem entirely.

**5. `pingPong` animation via `CAKeyframeAnimation` with `autoreverses`, per watermark, pause/resume with playback.**
The animation moves the watermark horizontally across the full available span (x coordinate is ignored while animating, y stays at its configured percentage), one leg per configured duration, then reverses — a true bounce, identical to Android's `ValueAnimator.ofFloat(0f,1f)` with `repeatMode = REVERSE`. The full cycle therefore takes 2×duration. `CAKeyframeAnimation` on `transform.translation.x` with `autoreverses = true` and `repeatCount = .infinity` runs off the main thread. The animation pauses when the player is not playing (paused, buffering, ended) and resumes when playing resumes, matching Android's `updateVisibilityForState`; the watermark remains visible. Playback state is observed by the presentation views (they already hold the player); `TPAVPlayer` has no watermark surface. Each watermark has its own layer and animation. Note: the Flutter doc comment calls this "a sweep effect", but the Android behavior (and therefore what Flutter apps see today) is a bounce — the spec pins the bounce; the Flutter comment should be corrected separately.

**6. Normalization applied once at `setWatermarks(_:)` time; models stay plain data.**
Matching the codebase convention — existing models (e.g. `SubtitleTrack`) carry no validation — `WatermarkConfig`/`WatermarkAnimation` are plain value types with no `validated()` method. Normalization happens when the configuration is applied to the overlay (at setup, and on each config change on the UIKit path): empty text passes through and still renders (matching Android, which creates an empty `TextView`); x/y are clamped to 0-100 and opacity to 0-1 (Android crashes via `require()` here — documented divergence, tracked as an upstream Android bug); animation duration is floored at 100 ms (`coerceAtLeast` semantics, matching `WatermarkAnimation.MIN_DURATION_MS`); textSize and color pass through untouched (Android validates neither); a missing animation means static (Android's `null`). No "invalid color" or "unknown animation type" states exist because the Pigeon contract cannot produce them. *Alternatives:* clamping vs. throwing was decided as clamp — the SDK never crashes, and the only values affected are ones Android cannot render at all, so no behavior mismatch is observable on valid configs. Dropping empty text was rejected because it would diverge from what Flutter apps see on Android.

**7. Z-order: earlier entries render on top (match Android).**
Matches Android's current stacking from `getWatermarkInsertIndex` (fixed-index insertion puts the first config on top). Flutter apps with overlapping watermarks — including the Flutter example's two `pingPong` entries at `y=50` that cross paths — see first-on-top on Android today, so iOS mirrors that for visual parity. *Alternatives:* later-on-top (painter's algorithm) — rejected because overlapping watermarks would look different from Android.

## Risks / Trade-offs

- **Duplicate integration points (UIKit + SwiftUI)** → shared `WatermarkOverlayView` keeps rendering/animation in one file; UI-path code is thin wiring only.
- **Animation semantics ambiguity ("sweep" vs bounce)** → pinned to Android's actual bounce behavior in the spec; Flutter doc comment updated separately.
- **Invalid config divergence from Android** → iOS clamps, Android crashes; unobservable for valid configs, and Android's crash is a bug (upstream issue). Until Android is fixed, the same Flutter config behaves identically for all valid inputs.
- **Z-order tied to Android's insertion order** → first-on-top matches what Flutter apps see on Android today; if Android later changes stacking, iOS should follow.
- **Paused animation during buffering** → matches Android (`isPlaying` is false while buffering); documented in the spec so it is not mistaken for a regression.
- **Perf with many animated watermarks** → Core Animation runs off the main thread; matching Android, there is no hard cap — the spec's 10-watermark test scenario is a floor, not a limit.

## Migration Plan

Additive change; no existing API changes. New files only (watermark models, `WatermarkOverlayView`, overlay wiring in both UI paths, sample app + docs). Rollback = revert the change; applications that never call `setWatermarks` are unaffected. The Flutter plugin's no-op stubs (`NativePlayerView.swift`) are then implemented against the new API in a follow-up change.
