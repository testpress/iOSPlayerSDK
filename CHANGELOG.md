
## 1.2.40 - 2026-08-20



### Bug Fixes

- Anchor watermark to the video content rect instead of the full player view (#171)
- Enable live video playback while transcoding is in progress (#172)



## 1.2.39 - 2026-08-12



### Features

- Add text watermark support, letting apps display one or more configurable watermarks over the video with percentage-based positioning, color, size, and opacity (#159, #160)
- Add animated pingPong watermark support that sweeps watermarks horizontally and pauses/resumes with playback state (#165)
- Increase subtitle font size in fullscreen and reserve layout space for two-line subtitles (#162, #163)



### Bug Fixes

- Prevent a simulator crash during player initialization (#166)



## 1.2.38 - 2026-08-07



### Bug Fixes

- Prevent a crash when saving the playback position while the player item is not ready yet, by skipping the save until a valid playback position is available



## 1.2.37 - 2026-08-06



### Features

- Add resume playback support, restoring the last watched position when playback starts, periodically saving progress during playback, and clearing the saved position after the video is completed (#157)



## 1.2.36 - 2026-08-04



### Bug Fixes

- Use a per-player AVContentKeySession for offline DRM, ensuring expired licenses are validated on every playback instead of being bypassed by cached content keys from a shared session (#153)



### Maintenance

- Migrate RealmSwift from 10.54.2 to 20.0.4 (#154)



### Refactoring

- Make offline asset deletion thread-safe by carrying only plain asset and content ids across threads, and running encryption-key cleanup on the content key delegate queue (#155)



## 1.2.35 - 2026-07-27



### Features

- Add offline license duration parameter to download API, allowing custom expiration periods for different download scenarios (#152)



### Bug Fixes

- Skip live stream notice for Testpress when the recorded video is already available and playable (#151)



## 1.2.34 - 2026-06-30



### Bug Fixes

- Apply CocoaPods compilation flag to all build configurations, not just `Debug` and `Release`, so custom configurations load resources correctly (#149)

- Ensure `setupCompletion` fires only after video qualities have finished loading, preventing premature initialization (#147)

- Report initialization failure when playback URL is invalid instead of falsely reporting success (#148)



## 1.2.33 - 2026-06-26



### Maintenance

- Pin SwiftSubtitles dependency to version 1.8.1 across SPM, CocoaPods, and Xcode project to align all distribution channels



## 1.2.32 - 2026-06-26



### Features

- Added support for displaying subtitles during video playback.
- Introduced subtitle track selection and automatic subtitle track detection.



## 1.2.31 - 2026-06-15



### Bug Fixes

- Ensure encryption key requests are recognized as iOS app traffic (#143)



### Features

- Parse subtitle tracks from video API responses (#141)



## 1.2.30 - 2026-05-14



### Bug Fixes

- Relax Sentry dependency constraint (#138)



## 1.2.29 - 2026-04-02



### Features

- Add support for DRM-protected live streams on iOS (#137)



## 1.2.28 - 2026-03-19



### Features

- Expose public APIs for programmatically controlling fullscreen (#136)



## 1.2.27 - 2026-03-17



### Refactoring

- Remove download quality message from action sheets (#135)



## 1.2.26 - 2026-03-17



### Refactoring

- Isolate SDK Realm configuration from host application (#134)



## 1.2.25 - 2026-03-13



### Features

- Improve video quality labels in player UI (#133)



## 1.2.24 - 2026-03-10



### Features

- Add support for AES-encrypted video offline playback (#127)



## 1.2.23 - 2026-03-05



### Features

- Remove internal toasts and related dependencies (#129)

- Add onFailed delegate event for download failures (#130)

- Add public startDownload API and decouple from player (#128)

- Add resolution fallback support to download API (#131)

- Add error details in onFailed delegate callback (#132)



## 1.2.22 - 2026-02-18



### Bug Fixes

- Prevent playback speed reset on rate changes during playback transitions (#126)



### Features

- Expose dedicated replay button event listener (#125)



## 1.2.21 - 2026-02-11



### Bug Fixes

- Offline videos not playing in Testpress iOS app (#124)



## 1.2.20 - 2026-02-03



### Bug Fixes

- Resolve asset loading issues in CocoaPods modular apps (#123)



## 1.2.19 - 2026-02-03



### Features

- Add support for customizing player control visibility (#122)



## 1.2.18 - 2026-01-19



### Bug Fixes

- Resolve playback issue with mobile-only access for Testpress provider (#121)



## 1.2.17 - 2026-01-09



### Bug Fixes

- Offline DRM playback after download (#119)

- Preserve DRM license duration during token retry (#120)



### Features

- Add support for launching player in fullscreen mode (#118)



### Maintenance

- Fix build errors and update dependency versions



## 1.2.16 - 2025-12-09



### Bug Fixes

- Build error M3U8Parser package not found



### Maintenance

- Update organization code and sample asset credentials



### Refactoring

- Replace M3U8Parser with M3U8Kit



## 1.2.15 - 2025-12-05



### Bug Fixes

- Sync UI speed menu when playback rate changes programmatically (#115)

- Resolve iOS 13.0+ availability errors using polymorphism



## 1.2.14 - 2025-12-01



### Bug Fixes

- Download cancellation after app force-close (#113)

- Unable to resume the downloads after app relaunch (#114)



## 1.2.11 - 2025-10-07



### Bug Fixes

- Add support for download state notifications (#108)

- Remove leftover DRM keys when deleting offline assets (#109)



### Features

- Add license expiry date field for offline DRM license tracking (#111)

- Add DRM license expiry support for offline content (#110)

- Add auto-renewal support for DRM licenses of offline content (#112)



## 1.2.10 - 2025-09-23



### Bug Fixes

- Unable to resume the downloads after app relaunch



## 1.2.9 - 2025-09-22



### Bug Fixes

- Add support for nested dictionaries in offlineAsset metaData (#107)



## 1.2.8 - 2025-09-01



### Bug Fixes

- Handle one-time access token expiry during download (#106)



## 1.2.7 - 2025-08-28



### Bug Fixes

- Remove duplicate xcassets to resolve build conflicts



### Features

- Add thumbnail URL support for offline assets (#104)

- Add metadata support for offline assets (#105)



## 1.2.6 - 2025-07-11



### Bug Fixes

- Playback failure while playing Testpress AES-encrypted video (#103)



## 1.2.5 - 2025-05-13



### Bug Fixes

- Upgrade Sentry Cocoa dependency to 8.50.0



## 1.2.4 - 2025-04-24



### Bug Fixes

- App freezes when fetching video qualities from master playlist (#101)



## 1.2.3 - 2025-03-13



### Bug Fixes

- Update Sentry DSN URL



## 1.2.2 - 2025-03-06



### Bug Fixes

- Videos not playing if duration unavailable in API response



## 1.2.1 - 2025-01-31



### Bug Fixes

- App crash while running in Simulator (#99)

- Update Realm Swift to version 10.54.2 (#100)

- Add optional Sentry logging for specific error cases

- Prevent app crash while playing DRM content on simulator



### Refactoring

- Refactor TPAVPlayer initialization logic



## 1.2.0 - 2025-01-06



### Bug Fixes

- Build failure while publishing package in Cocoapods



## 1.1.9 - 2024-11-26



### Bug Fixes

- Remove Partially Deleted Video (#78)

- Update Realm Database Configuration Path in TPStreamsSDK (#87)

- Introduce Method to Verify Video Download Status (#90)

- Add drmContentId field in Video Model (#91)

- Show error when player fails before assignment

- Add Validation for Auth Token Based on Provider (#94)

- Improve Access Token and Auth Token Validation in TPAVPlayer (#95)

- Include UUID in Sentry events for better traceability (#93)

- Make accessToken an Optional Field (#96)

- Raise error if access token not provided during initialization (#98)



### Features

- Add Realm Database and OfflineAsset model (#72)

- Add Non-DRM video download support (#73)

- Add download list (#74)

- Add `TPStreamsDownloadDelegate` (#75)

- Add support play downloaded non drm video (#76)

- Add support to delete the downloaded video (#77)

- Add JWT Authorization Support for API Requests (#79)

- Add download button in player view (#81)

- Add DRM video download support (#88)



### Refactoring

- Update Storyboard Exam App UI (#82)

- Remove Placeholder StartDownload Method (#89)

- Move `drmContentId` from Video to Asset Model (#92)

- Move SetupCompletion type alias out of TPAVPlayer class

- Remove unused `accessToken` parameter (#97)



### enhancement

- Add cancel download functionality for Offline download (#80)

- Add Download List View in Storyboard Example App (#83)

- Implement Player View Configuration for SwiftUI (#84)

- Add download option to player configuration (#85)

- Differentiate Offline and Online Player Settings (#86)



## 1.1.7 - 2024-06-21



### Bug Fixes

- Fix build error while running app in xcode

- Store Live Stream details from API in Asset data class (#66)

- Extract Video, LiveStream data classes into separate files

- Display user-friendly error messages on SwiftUI player (#69)

- Add player status observation for AVPlayer readiness tracking



### Features

- Add support to play live stream (#67)

- Show notice when API response includes a notice message

- Add live stream indicator label to players (#70)



### Refactoring

- Extract Video data class out of Asset

- Follow camel-case for attributes naming

- Extract parsing-related code from Network class (#68)

- Support to show notice message in player

- Extract PlaybackSpeed into constants folder

- Rename videoDuration attribute to playableDuration

- Rename TPStreamPlayer playback listener method



## 1.1.6 - 2024-06-06



### Bug Fixes

- Invalid manifest error while using package via SPM (#65)



## 1.1.5 - 2024-05-17



### Bug Fixes

- Update dependencies

- Add privacy manifest file

- Update minimum deployment version to 12



## 1.1.3 - 2024-04-02



### Bug Fixes

- Build error while using package via SPM



## 1.1.2 - 2024-02-21



### Bug Fixes

- Use valid Sentry DSN URL

- Capture player errors in sentry (#64)

- Use 'self' to capture semantics



## 1.1.1 - 2024-01-24



### Bug Fixes

- Fix simulator Crash for Non-DRM Video Playback

- Prevent capturing network error in sentry

- Error view persistence on network reconnect (#58)

- Ensure proper self-referencing in fetchAsset closure



### Refactoring

- Change branch name to main (#49)

- Re-indent files



### Testing

- Add basic test case and github actions (#48)



### enhancement

- Store asset in TPAVPlayer attribute(#53)

- Add `duration` field asset model (#55)



## 1.1.0 - 2023-12-20



### Bug Fixes

- Support to disable auto fullscreen on rotate



## 1.0.9 - 2023-12-14



### Bug Fixes

- Fix app crash on clicking seek without internet



### Refactoring

- Return if player seek value is `NaN` (#47)



## 1.0.8 - 2023-12-13



### Features

- Display user-friendly error messages on player errors (#45)



## 1.0.7 - 2023-12-01



### Bug Fixes

- Support to limit player available video qualities



### Features

- Create github action to publish package on Cocoapods (#40)



## 1.0.6 - 2023-11-30



### Bug Fixes

- Disable forward button on video end

- Reduce player forward buffer duration

- Allow users to pass completion to TPAVPlayer intializer (#43)



### Features

- Allow users to configure forward and rewind duration (#41)

- Support to configure progress bar (#42)



## 1.0.5 - 2023-11-27



### Bug Fixes

- App crash in iPad while clicking settings button

- Correct minimum value in percentage calculation

- Watched progress length differs between orientation change (#38)



### Features

- Introduce TPPlayerViewControllerDelegate for fullscreen events (#39)



### Maintenance

- Remove unwanted contraints



## 1.0.4 - 2023-11-21



### Bug Fixes

- Render dragable thumb properly on progress bar (#37)

- Prevent dragging thumb outside ProgressBar



## 1.0.3 - 2023-11-20



### Bug Fixes

- Disable sentry debug mode

- Incorrect size set on container view on fullscreen

- Player orientation not changed on fullscreen below iOS 16 (#34)

- Modify player controls UI (#36)



### Features

- Support to reload video in player on end (#35)



## 1.0.2 - 2023-10-26



### Features

- Add support to play AES-Encrypted videos (#33)



## 1.0.1 - 2023-10-13



### Bug Fixes

- Error while using package via cocoapods (#32)



## 1.0.0 - 2023-10-13



### Bug Fixes

- Enable UI fullscreen in Example app

- Maximize button failing to switch orientation to landscape in iOS 16 (#14)

- Playback speed options not showing while video playing (#15)

- Decrement Minimum Deployment Version to 11.4 (#17)

- Create sample app with storyboard to test our SDK (#18)

- Extract TPStreamsPlayer obserable attributes to separate class (#20)

- Show loading indicator while player buffering

- Video options not showing in fullscreen mode

- Add schemas for sample apps

- Fix XIB Module Assignment Issue (#30)

- Allow users to change resolution using TPAVPlayer



### Documentation

- Create TPStreamsSDK Walkthrough doc (#16)



### Features

- Add support to play testpress videos (#2)

- Add controls to play/pause video (#3)

- Add controls to rewind/forward 10 seconds (#4)

- Add support to change playback speed (#5)

- Display player current time & video duration in player (#7)

- Add fullscreen support to player view (#8)

- Show loading indicator while player buffering (#10)

- Add progress bar with seek-through support (#9)

- Add support to change resolution (#12)

- Create player with a storyboard (#19)

- Add support to play or pause the video (#21)

- Add support to rewind or forward 10 seconds (#22)

- Add support to change playback speed (#26)

- Add support to change video resolution (#27)

- Show video duration and current time in player (#24)

- Add support to toggle fullscreen (#28)

- Add progress bar with seek through support (#29)

- Release Package in cocoapods (#31)



### Refactoring

- Refactor TPAVPlayer (#1)

- Rename TPVideoPlayer to AVPlayerBridge

- Convert TPStreamsPlayer attributes to observable primitive data types (#23)

- Add space between functions

- Extract util method from view (#25)

- Remove player prefix from attributes

- Reduce verbose

- Move bundle constant to shared file



### doc

- Update documentation


