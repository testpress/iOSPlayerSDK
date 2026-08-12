## Purpose

Lets applications display one or more text watermarks over video playback with percentage-based positioning, configurable appearance, an optional pingPong animation, and API parity with the existing Android and Flutter SDKs. The API shape, defaults, and animation behavior are pinned by the Flutter Pigeon contract (`pigeons/native_player_api.dart`) as implemented by the Android SDK.

## ADDED Requirements

### Requirement: Configure watermarks in the player configuration
The system SHALL allow applications to configure one or more text watermarks through the player configuration (`TPStreamPlayerConfiguration.watermarks`, builder `setWatermarks(_:)`), and SHALL remove all watermarks when an empty list is configured. Setting a new list MUST replace all currently displayed watermarks without interrupting playback. On the UIKit path, updating `config.watermarks` at runtime MUST re-apply the overlay (the `config` property already re-applies via `didSet`). Empty-text configurations MUST still be accepted and rendered (matching Android/Flutter; an empty label may occupy negligible space).

#### Scenario: Configure watermarks
- **WHEN** an application configures watermarks in the player configuration
- **THEN** the player displays all configured watermarks over the video content

#### Scenario: Replace existing watermarks
- **WHEN** an application sets a new watermark list while watermarks are already displayed
- **THEN** the currently displayed watermarks are replaced by the new list without player recreation or playback restart

#### Scenario: Runtime config update on the UIKit path
- **WHEN** an application updates `config.watermarks` on `TPStreamPlayerViewController` during playback
- **THEN** the overlay re-applies the new list without player recreation or playback restart

#### Scenario: Clear all watermarks
- **WHEN** an application configures an empty watermark list
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
The system SHALL support static watermarks (no animation) and a pingPong animation. The pingPong animation SHALL move the watermark horizontally across the full available span — from the left edge to the right edge and back — taking the configured duration for each leg, while keeping the y position constant. The x coordinate of an animated watermark MUST be ignored in favor of the animation's position. Static and animated watermarks MUST be able to coexist. The animation MUST pause when playback is not active (not ready, paused, buffering, ended) and resume when playback resumes, while the watermark itself remains visible.

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
- **WHEN** playback is not ready, pauses, buffers, or ends while a pingPong watermark is displayed, and then resumes
- **THEN** the watermark remains visible, its animation pauses while playback is not active, and resumes from the paused position when playback resumes

### Requirement: Watermark lifecycle
The system SHALL keep watermarks visible throughout playback events including play, pause, seek, buffering, fullscreen transitions, and orientation changes, rendering them above the video content and below both subtitles and player controls. Watermarks SHALL be positioned to stay above the subtitle reserved bottom band when subtitles are active, preventing visual overlap between watermarks and subtitle text. The system SHALL remove all watermarks and stop all animations when the player view is released or deinitialized.

#### Scenario: Watermarks persist through playback events
- **WHEN** the player pauses, seeks, buffers, enters or exits fullscreen, or the device rotates during playback
- **THEN** watermarks remain visible and correctly positioned

#### Scenario: Layer ordering
- **WHEN** watermarks, subtitles, and player controls are displayed during playback
- **THEN** watermarks render above the video content and below both subtitles and player controls

#### Scenario: Watermarks respect the subtitle reserved band
- **WHEN** subtitles are active and a watermark is positioned near the bottom of the view
- **THEN** the watermark is constrained to stay above the area reserved by the subtitle view, without overlapping subtitle text

#### Scenario: Player view release cleanup
- **WHEN** the player view is released or deinitialized
- **THEN** all watermarks are removed and all animation resources are cleaned up

### Requirement: Watermark configuration normalization
The system SHALL apply documented normalization defaults to watermark configuration values when the configuration is applied to the overlay, without crashing on invalid input and without interrupting video playback. The watermark models are plain data and carry no validation, matching the codebase convention.

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

#### Scenario: Out-of-range configuration values
- **WHEN** a watermark configuration contains out-of-range coordinates or opacity, or an animation duration below the minimum
- **THEN** the system clamps the out-of-range values to the documented bounds and renders the watermark

#### Scenario: Mixed in-range and out-of-range entries
- **WHEN** a watermark list contains both in-range and out-of-range configurations
- **THEN** all entries render, with out-of-range values clamped, without interrupting playback

### Requirement: Cross-platform API consistency
The system SHALL expose watermark functionality through the SDK public API with model names, field names, types, and defaults matching the Flutter Pigeon contract. On iOS the surface is the player configuration (`TPStreamPlayerConfiguration.watermarks`) rather than the imperative Pigeon methods: the Flutter bridge maps `setWatermarks`/`clearWatermarks` onto `TPStreamPlayerViewController.config.watermarks`. Behavior SHALL be consistent with the Android Player SDK for equivalent watermark configurations.

#### Scenario: Flutter SDK parity
- **WHEN** the Flutter SDK applies a watermark configuration to the iOS player (via `TPStreamPlayerViewController.config.watermarks`)
- **THEN** the watermark renders with behavior matching the Android SDK for the same configuration
