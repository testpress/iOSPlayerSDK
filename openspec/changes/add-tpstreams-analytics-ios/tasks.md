## 1. Analytics Architecture

- [x] 1.1 Add internal TPStreams analytics identity, user-agent, tracker, and uploader components.
- [x] 1.2 Gate analytics creation and API operations to online TPStreams playback only.
- [x] 1.3 Keep analytics implementation details internal and preserve the existing provider abstraction.

## 2. API and Parsing Integration

- [x] 2.1 Add the TPStreams analytics presigned endpoint to `StreamsAPI`.
- [x] 2.2 Add presigned URL and upload transport methods to `BaseAPI`.
- [x] 2.3 Parse the presigned upload response through `StreamsAPIParser`.

## 3. Playback Tracking

- [x] 3.1 Connect player ready, playing, paused, buffering, seek, ended, failed, and release events to the tracker.
- [x] 3.2 Accumulate playback duration and send heartbeat updates at the configured interval.
- [x] 3.3 Deduplicate uploads using the highest successfully uploaded duration.
- [x] 3.4 Queue the final release duration without blocking player teardown.

## 4. Upload Reliability

- [x] 4.1 Coalesce presigned URL requests and serialize analytics uploads.
- [x] 4.2 Retry an upload once after refreshing a presigned URL on HTTP 403.
- [x] 4.3 Keep the uploader alive through queued and in-flight final uploads.
- [x] 4.4 Keep analytics failures isolated so playback continues normally.

## 5. Verification

- [x] 5.1 Verify offline and TestPress playback do not invoke TPStreams analytics.
- [x] 5.2 Build the iOS SDK for the iOS Simulator without code signing.
- [x] 5.3 Review the final upload, timer teardown, identity fallback, and duplicate-upload paths.
