## 1. API Parsing

- [ ] 1.1 Update `StreamsAPIParser.parseVideo(from:)` to extract tracks from the `video.tracks` response dict
- [ ] 1.2 Update `TestpressAPIParser.parseVideo(from:)` to extract tracks from the `video.tracks` response dict

## 2. Dependency Setup

- [ ] 2.1 Add `dagronf/SwiftSubtitles` SPM dependency to `Package.swift`
- [ ] 2.2 Add `SwiftSubtitles` pod dependency to `TPStreamsSDK.podspec`

## 3. SubtitleView (UIKit)

- [ ] 3.1 Create `SubtitleView` as a UIView subclass with a `UILabel` for rendering subtitle text
- [ ] 3.2 Add `setTrack(_ track: SubtitleTrack?)` method that stores the track, downloads WebVTT via `URLSession`, parses with `Subtitles(content:expectedExtension: "vtt")`, and caches the cues
- [ ] 3.3 Add KVO observation of `TPStreamPlayer.currentTime` to look up active cue and update the label text
- [ ] 3.4 Properly remove KVO observer in `deinit` / `willMove(toSuperview: nil)`
- [ ] 3.5 Show empty state while WebVTT is downloading
- [ ] 3.6 Handle download failures gracefully (hide subtitle view)

## 4. UIKit Integration

- [ ] 4.1 Add `startWithCaption: Bool` to `TPStreamPlayerConfiguration` and builder method
- [ ] 4.2 Verify `enableCaptions` builder method exists (already in struct)
- [ ] 4.3 Add `SubtitleView` as lazy var in `TPStreamPlayerViewController` and add as subview of `containerView`
- [ ] 4.4 Size `SubtitleView` in `viewDidLayoutSubviews`
- [ ] 4.5 Add "Captions" option to `PlayerControlsUIView.showOptionsMenu()`, only when `enableCaptions == true` and tracks exist
- [ ] 4.6 Build captions submenu showing available languages with checkmark on active, plus "Off" option
- [ ] 4.7 On language selection, pass the track to `SubtitleView.setTrack()`; on "Off", pass `nil`
- [ ] 4.8 Implement auto-selection on player "ready": if `startWithCaption == true`, auto-set the first available subtitle track
- [ ] 4.9 Update `showSettingsButton` to include `enableCaptions`

## 5. SwiftUI Integration

- [ ] 5.1 Create SwiftUI subtitle view in `Source/Views/SwiftUI/` with a `Text` view and observe `player.observedCurrentTime` for cue lookup
- [ ] 5.2 Integrate subtitle view into `TPStreamPlayerView` ZStack
- [ ] 5.3 Add "Captions" option to `PlayerSettingsButton` action sheet with language selection and "Off"
- [ ] 5.4 Implement auto-selection for SwiftUI path

## 6. Verification

- [ ] 6.1 Build — `xcodebuild build -project iOSPlayerSDK.xcodeproj -scheme TPStreamsSDK`