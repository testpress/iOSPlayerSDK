## Purpose

Lets applications display one or more text watermarks over video playback with percentage-based positioning, configurable appearance, an optional pingPong animation, and API parity with the existing Android and Flutter SDKs. The API shape, defaults, and animation behavior are pinned by the Flutter Pigeon contract (`pigeons/native_player_api.dart`) as implemented by the Android SDK.

## ADDED Requirements

### Requirement: Configure watermarks on a player
The system SHALL allow applications to set one or more text watermarks on a player instance by providing a list of watermark configurations, and SHALL provide a way to remove all watermarks. Setting a new list MUST replace all currently displayed watermarks. Setting an empty list, or calling the clear API, MUST remove all watermarks without interrupting playback. Empty-text configurations MUST still be accepted and rendered (matching Android/Flutter; an empty label may occupy negligible space).

#### Scenario: Set watermarks on a player
- **WHEN** an application calls the watermark API with a list of watermark configurations
- **THEN** the player displays all valid configured watermarks over the video content

#### Scenario: Replace existing watermarks
- **WHEN** an application sets a new watermark list while watermarks are already displayed
- **THEN** the currently displayed watermarks are replaced by the new list without player recreation or playback restart

#### Scenario: Clear all watermarks
- **WHEN** an application sets an empty watermark list or calls the clear-watermarks API
- **THEN** all displayed watermarks are removed and playback continues unaffected

### Requirement: Render multiple watermarks simultaneously
The system SHALL render each watermark independently based on its own configuration, and SHALL render all provided configurations with no hard limit (the documented test floor is 10). Watermarks MUST be rendered in the order provided in the configuration list, with earlier entries rendered on top of later ones (matching Android's current stacking for visual parity when watermarks overlap).

#### Scenario: Multiple watermarks with independent configuration
- **WHEN** an application configures multiple watermarks with different text, position, or appearance
- **THEN** each watermark renders according to its own configuration at the same time

#### Scenario: Large number of watermarks
- **WHEN** an application configures 10 or more watermarks simultaneously
- **THEN** all of them render correctly

#### Scenario: Overlapping watermarks
- **WHEN** two configured watermarks occupy overlapping positions
- **THEN** the watermark earlier in the configuration list renders on top

### Requirement: Watermark positioning
The system SHALL position each watermark using percentage-based x and y coordinates in the range 0-100 relative to the player view bounds, where (0, 0) is the top-left corner and (100, 100) is the bottom-right corner. Each watermark MUST remain fully visible within the view bounds, offset by a small fixed inset at the edges. Positions MUST be recalculated whenever the view bounds change due to layout changes.

#### Scenario: Position watermark by percentage
- **WHEN** an application sets a watermark with x and y coordinates of 50
- **THEN** the watermark renders centered on the player view

#### Scenario: Edge-aligned watermarks stay fully visible
- **WHEN** an application sets a watermark with x or y coordinate of 0 or 100
- **THEN** the watermark renders fully inside the view bounds, its edge offset from the view edge by the fixed inset

#### Scenario: Layout change repositioning
- **WHEN** the view bounds change due to rotation, fullscreen transition, or view resize
- **THEN** watermarks are repositioned to the configured percentage coordinates within the same layout pass

### Requirement: Watermark appearance configuration
The system SHALL allow each watermark to define its display text, opacity, text size, and color. Opacity MUST be in the range 0.0-1.0, text size in points, and color as an ARGB value.

#### Scenario: Custom appearance
- **WHEN** an application configures a watermark with a specific text, opacity, text size, and color
- **THEN** the watermark renders with the configured appearance

### Requirement: Watermark animation
The system SHALL support static watermarks (no animation) and a pingPong animation. The pingPong animation SHALL move the watermark horizontally across the full available span — from the left edge to the right edge and back — taking the configured duration for each leg, while keeping the y position constant. The x coordinate of an animated watermark MUST be ignored in favor of the animation's position. Static and animated watermarks MUST be able to coexist. The animation MUST pause when playback is not active (paused, buffering, ended) and resume when playback resumes, while the watermark itself remains visible.

#### Scenario: Static watermark
- **WHEN** an application configures a watermark without an animation
- **THEN** the watermark renders statically at its configured position

#### Scenario: PingPong animated watermark
- **WHEN** an application configures a watermark with animation type pingPong and a duration
- **THEN** the watermark moves horizontally from the left edge to the right edge and back, completing one leg in the configured duration, with its y position constant

#### Scenario: Static and animated watermarks coexist
- **WHEN** an application configures both static and animated watermarks
- **THEN** both render simultaneously without interfering with each other

#### Scenario: Animation pauses and resumes with playback
- **WHEN** playback pauses, buffers, or ends while a pingPong watermark is displayed, and then resumes
- **THEN** the watermark remains visible, its animation pauses while playback is not active, and resumes from the paused position when playback resumes

### Requirement: Watermark lifecycle
The system SHALL keep watermarks visible throughout playback events including play, pause, seek, buffering, fullscreen transitions, and orientation changes, rendering them above the video content (and subtitles) and below player controls. The system SHALL remove all watermarks and stop all animations when the player is released or deinitialized.

#### Scenario: Watermarks persist through playback events
- **WHEN** the player pauses, seeks, buffers, enters or exits fullscreen, or the device rotates during playback
- **THEN** watermarks remain visible and correctly positioned

#### Scenario: Layer ordering
- **WHEN** watermarks, subtitles, and player controls are displayed during playback
- **THEN** watermarks render above the video content and subtitles, and below player controls

#### Scenario: Player release cleanup
- **WHEN** the player is released or deinitialized
- **THEN** all watermarks are removed and all animation resources are cleaned up

### Requirement: Watermark configuration validation
The system SHALL validate watermark configuration values before rendering and SHALL apply documented defaults, without crashing on invalid input and without interrupting video playback.

The following defaults SHALL apply:
- x or y outside `0-100`: clamp to the nearest bound
- opacity outside `0.0-1.0`: clamp to the nearest bound
- animation duration less than `100`: use `100` milliseconds
- empty text: pass through and render (do not drop)
- text size and color: pass through unchanged

The following defaults SHALL apply to omitted optional values (matching the Flutter/Android contract):
- x: `0`, y: `0`
- color: `0xFFFFFFFF` (white)
- text size: `14`
- opacity: `0.3`
- animation: static (none)
- animation duration: `10000` milliseconds

#### Scenario: Invalid configuration values
- **WHEN** a watermark configuration contains out-of-range coordinates or opacity, or an animation duration below the minimum
- **THEN** the system clamps the invalid values to the documented bounds and renders the watermark

#### Scenario: Mixed in-range and out-of-range entries
- **WHEN** a watermark list contains both in-range and out-of-range configurations
- **THEN** all entries render, with out-of-range values clamped, without interrupting playback

### Requirement: Cross-platform API consistency
The system SHALL expose watermark functionality through the SDK public API matching the Flutter Pigeon contract (model names, field names, types, and defaults), such that the existing Flutter SDK bridge can consume it without platform-specific changes, and SHALL behave consistently with the Android Player SDK for equivalent watermark configurations.

#### Scenario: Flutter SDK parity
- **WHEN** the Flutter SDK applies a watermark configuration to the iOS player through the Pigeon `NativePlayerApi`
- **THEN** the watermark renders with behavior matching the Android SDK for the same configuration, without requiring platform-specific API changes
