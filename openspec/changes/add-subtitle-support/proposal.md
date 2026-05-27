## Why

The Android SDK already supports subtitles/captions with WebVTT sidecar tracks. iOS parity is needed — users who consume content with captions on Android expect the same experience on iOS. The backend already returns subtitle track metadata in the API response; the SDK just needs to parse it, download the WebVTT files, and render them in sync with playback.

## What Changes

- New `SubtitleView` (UIView) — self-contained view that downloads WebVTT from a track URL, parses with SwiftSubtitles, and renders the cue at the current playback time
- Both `StreamsAPIParser` and `TestpressAPIParser` extract subtitle tracks from the `video` response dict (uses `SubtitleTrack` model already on main)
- `TPStreamPlayerViewController` adds `SubtitleView` as a subview of `containerView` (between videoView and noticeView)
- `TPStreamPlayerView` (SwiftUI) adds a SwiftUI subtitle view in its ZStack
- Settings menu in both UIKit and SwiftUI gains a "Captions" entry listing available subtitle languages
- `TPStreamPlayerConfiguration` gets `autoSelectFirstSubtitle` flag; on player ready and auto select the first subtitle from the api
- `enableCaptions` config flag wired into `showSettingsButton` so the settings button appears when only captions are enabled
- `SwiftSubtitles` added as a dependency in both `Package.swift` and `TPStreamsSDK.podspec`

## Capabilities

### New Capabilities
- `subtitle-support`: Parse subtitle tracks from API responses, download and render WebVTT subtitles in sync with video playback, and allow language selection from the settings menu

### Modified Capabilities
<!-- No existing capabilities are changing at the spec level -->

## Impact

- **New files**: `SubtitleView.swift`, SwiftUI subtitle view
- **Modified files**: `StreamsAPIParser.swift`, `TestpressAPIParser.swift`, `TPStreamPlayerViewController.swift`, `TPStreamPlayerView.swift`, `TPStreamPlayerConfiguration.swift`, `PlayerControlsUIView.swift`, `PlayerSettingsButton.swift`, `Package.swift`, `TPStreamsSDK.podspec`
- **New dependency**: `dagronf/SwiftSubtitles` (MIT, iOS 12+ compatible)
- **No public API changes** — all subtitle control is internal through the settings UI and config flags
