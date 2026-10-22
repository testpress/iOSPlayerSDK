## Why

The native iOS player was not reporting TPStreams playback analytics, while the TPStreams embedded player already provided this visibility. The SDK needs equivalent online playback tracking without affecting playback, and must keep TestPress and offline playback outside the TPStreams analytics flow.

## What Changes

- Add TPStreams-only playback analytics tracking for online native iOS playback.
- Track visitor and session identity, playback duration, heartbeat progress, pause, seek, end, and release events.
- Fetch analytics presigned upload URLs through the existing API and parser architecture.
- Serialize analytics uploads, prevent duplicate or regressing durations, and preserve the final release upload.
- Keep analytics failures isolated from player playback and exclude TestPress and offline playback.

## Capabilities

### New Capabilities

- `tpstreams-analytics`: Reports native iOS TPStreams playback duration and session analytics through periodic and lifecycle-triggered uploads.

### Modified Capabilities

None.

## Impact

- Affects the native player lifecycle and playback event hooks.
- Adds internal analytics identity, tracking, upload, and user-agent components.
- Extends the existing `BaseAPI`, `StreamsAPI`, and `StreamsAPIParser` flow for TPStreams analytics presigned URLs and uploads.
- Adds no public SDK API or provider behavior for TestPress.
