## ADDED Requirements

### Requirement: Subtitle display on track selection
When a user selects a subtitle language from the settings menu, the corresponding subtitles SHALL appear on the video at the correct playback time. When the user selects "Off", all subtitles SHALL be hidden.

#### Scenario: User selects a subtitle language
- **WHEN** the user selects a subtitle language from the Captions menu
- **THEN** subtitles SHALL appear and synchronize with the video playback

#### Scenario: User turns off subtitles
- **WHEN** the user selects "Off" from the Captions menu
- **THEN** no subtitles SHALL be displayed

### Requirement: Subtitles track playback time
While a subtitle track is active, the subtitle text SHALL update as the video plays to match the current playback position.

#### Scenario: Subtitles update during playback
- **WHEN** the user is watching the video with a subtitle track active
- **THEN** the displayed subtitle text SHALL change to match the current playback time

#### Scenario: No subtitle shown when outside cue range
- **WHEN** the user is watching the video and the playback position is not within any subtitle cue
- **THEN** no subtitle text SHALL be displayed

### Requirement: Captions menu
The "Captions" option SHALL appear in the player settings menu when subtitle tracks are available. The menu SHALL list all available subtitle languages and indicate which one (if any) is currently active.

#### Scenario: Captions menu appears when tracks available
- **WHEN** the video has subtitle tracks
- **THEN** a "Captions" option SHALL appear in the settings menu

#### Scenario: Captions menu hidden when no tracks
- **WHEN** the video has no subtitle tracks
- **THEN** no "Captions" option SHALL appear in the settings menu

#### Scenario: Active track shown with checkmark
- **WHEN** the user opens the Captions menu and a subtitle track is currently active
- **THEN** the active track SHALL show a checkmark indicator

#### Scenario: Off option available in Captions menu
- **WHEN** the user opens the Captions menu
- **THEN** an "Off" option SHALL be available to disable subtitles

### Requirement: Auto-caption on first play
The player SHALL automatically select the first available subtitle track on first playback when enabled.

#### Scenario: Auto-select first track
- **WHEN** the user starts playing the video for the first time
- **AND** `startWithCaption` is `true` and the video has subtitle tracks
- **THEN** the first subtitle track SHALL be automatically selected
- **THEN** subtitles SHALL begin displaying from the first cue

#### Scenario: No auto-select when disabled
- **WHEN** `startWithCaption` is `false`
- **THEN** no subtitle track SHALL be auto-selected

### Requirement: Subtitles remain visible in fullscreen
Subtitles SHALL remain visible and correctly positioned when the player enters fullscreen mode, and SHALL NOT disappear when the controls auto-hide.

#### Scenario: Subtitles visible during fullscreen
- **WHEN** the user enters fullscreen mode
- **THEN** any active subtitles SHALL remain visible

#### Scenario: Subtitles visible when controls auto-hide
- **WHEN** the player controls auto-hide after 10 seconds
- **THEN** subtitles SHALL remain visible

### Requirement: Identical behavior across UIKit and SwiftUI
Captions functionality SHALL behave identically in both the UIKit and SwiftUI player implementations.

#### Scenario: Subtitles work the same way in both player types
- **WHEN** the user plays a video with subtitles in either UIKit or SwiftUI player
- **THEN** the captions menu, subtitle display, and auto-select behavior SHALL be identical in both players