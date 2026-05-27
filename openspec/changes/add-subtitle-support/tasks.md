## 1. API Parsing

- [ ] 1.1 Update `StreamsAPIParser.parseVideo(from:)` to extract tracks from the `video.tracks` response dict
- [ ] 1.2 Update `TestpressAPIParser.parseVideo(from:)` to extract tracks from the `video.tracks` response dict

## 2. SubtitleView (UIKit)

- [ ] 2.1 Add `dagronf/SwiftSubtitles` SPM dependency to `Package.swift`
- [ ] 2.2 Add `SwiftSubtitles` pod dependency to `TPStreamsSDK.podspec`
- [ ] 2.3 Create `SubtitleView` as a UIView subclass with a `UILabel` for rendering subtitle text
- [ ] 2.4 Add `setTrack(_ track: SubtitleTrack?)` method that stores the track, downloads WebVTT via `URLSession`, parses with `Subtitles(content:expectedExtension: "vtt")`, and caches the cues
- [ ] 2.5 Add `updateSubtitle(at time: TimeInterval)` method that looks up active cue (startTimeInSeconds <= time < endTimeInSeconds) and updates the label text
- [ ] 2.6 Show empty state while WebVTT is downloading
- [ ] 2.7 Handle download failures gracefully (hide subtitle view)

## 3. UIKit Integration

- [ ] 3.1 Add `autoSelectFirstSubtitle: Bool` to `TPStreamPlayerConfiguration` and builder method
- [ ] 3.2 Verify `enableCaptions` builder method exists (already in struct)
- [ ] 3.3 Add `SubtitleView` as lazy var in `TPStreamPlayerViewController` and add as subview of `containerView`
- [ ] 3.4 Size `SubtitleView` in `viewDidLayoutSubviews`
- [ ] 3.5 Add "Captions" option to `PlayerControlsUIView.showOptionsMenu()`, only when `enableCaptions == true` and tracks exist
- [ ] 3.6 Build captions submenu showing available languages with checkmark on active, plus "Off" option
- [ ] 3.7 On language selection, pass the track to `SubtitleView.setTrack()`; on "Off", pass `nil`
- [ ] 3.8 Implement auto-selection on player "ready": if `autoSelectFirstSubtitle == true`, auto-set the first available subtitle track
- [ ] 3.9 Set up KVO on `TPStreamPlayer.currentTime` in VC to push time updates to `SubtitleView.updateSubtitle(at:)`
- [ ] 3.10 Update `showSettingsButton` to include `enableCaptions`


## 4. SwiftUI Integration

- [ ] 4.1 Create SwiftUI subtitle view in `Source/Views/SwiftUI/` with a `Text` view that reads `player.observedCurrentTime` (@Published) for cue lookup and rendering
- [ ] 4.2 Integrate subtitle view into `TPStreamPlayerView` ZStack
- [ ] 4.3 Add "Captions" option to `PlayerSettingsButton` action sheet with language selection and "Off"
- [ ] 4.4 Implement auto-selection for SwiftUI path

## 5. Verification

- [ ] 5.1 Build — `xcodebuild build -project iOSPlayerSDK.xcodeproj -scheme TPStreamsSDK`
