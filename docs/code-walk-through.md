# A Walk Through TPStreamsSDK

The purpose of this walk is not to see every piece of code, or define every module. Instead, it's about seeing the most important parts of TPStreamsSDK.


## TPStreamsSDK

TPStreamsSDK class serves as the initializer for the SDK. Clients should initialize this class in the AppDelegate with the orgCode and provider parameters.

The orgCode and provider values are only used for selecting and constructing the API URL. 

During the initialization of TPStreamsSDK, important setup tasks are performed for Sentry and AudioSession to ensure proper functionality.



## TPAVPlayer
TPAVPlayer is a wrapper class of AVPlayer that provides built-in support for playing our videos without requiring additional effort. It also supports FairPlay streaming for DRM-protected content from client.

To initialize TPAVPlayer, the client needs to provide the asset_id and the asset's access token. Upon initialization, TPAVPlayer fetches the asset details from the server using the provided asset_id and access token.

The fetched asset details are used to play the video and set up DRM playback.

> TPAVPlayer can also be used with the native iOS player to play Streams Videos, as it acts as a wrapper class of AVPlayer.



## TPStreamPlayerView

TPStreamPlayerView is a SwiftUI view that displays a video player with player controls and supports full-screen mode.

View consists of a ZStack that overlays the video player(AVPlayerBridge) and the player controls(PlayerControlsView).

- `AVPlayerBridge` is a UIViewRepresentable struct that bridges the `AVPlayer` to the SwiftUI view hierarchy.
- `PlayerControlsView` is a SwiftUI view that represents the player controls overlay.  It uses the `TPStreamPlayer` class to manage the player's state. 



## TPStreamPlayer 

`TPStreamPlayer` is an implementation that wraps the TPAVPlayer class to enable state management for video playback. 

While TPAVPlayer is an NSObject subclass, it doesn't provide built-in state observation for UI updates. 

TPStreamPlayer solves this issue by introducing additional properties and methods to track the player's status, current time, and buffering. It also handles observers to synchronize the UI with the player's state. This allows for better integration of video playback functionality into the user interface.
