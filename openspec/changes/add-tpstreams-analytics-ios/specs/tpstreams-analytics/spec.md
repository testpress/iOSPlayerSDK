## ADDED Requirements

### Requirement: Track eligible TPStreams playback

The SDK SHALL create and operate analytics tracking only for online playback provided by TPStreams. TestPress and offline playback MUST NOT initialize or invoke the TPStreams analytics flow.

#### Scenario: Online TPStreams playback starts
- **WHEN** an online TPStreams asset becomes ready
- **THEN** the SDK initializes one analytics session and requests its presigned upload URL

#### Scenario: TestPress playback starts
- **WHEN** a TestPress asset becomes ready
- **THEN** the SDK does not initialize a TPStreams analytics tracker or make an analytics request

#### Scenario: Offline playback starts
- **WHEN** an offline asset becomes ready
- **THEN** the SDK does not initialize a TPStreams analytics tracker or request analytics presigned data

### Requirement: Maintain analytics identity

Each analytics session SHALL use a stable visitor ID and a newly generated session ID. The visitor ID MUST remain stable for the process even when Keychain persistence is unavailable.

#### Scenario: Existing visitor ID is available
- **WHEN** a new analytics session is created
- **THEN** the SDK reuses the stored visitor ID and generates a new session ID

#### Scenario: Visitor ID persistence fails
- **WHEN** the SDK cannot read or save the visitor ID in Keychain
- **THEN** the SDK reuses one process-stable generated visitor ID for subsequent analytics requests

### Requirement: Report monotonic playback duration

The SDK SHALL report accumulated playback duration on heartbeat and relevant playback lifecycle events, including pause, seek, end, and release. It MUST NOT upload a duplicate or lower duration after a successful upload.

#### Scenario: Heartbeat occurs during playback
- **WHEN** the five-minute heartbeat fires and playback duration has increased
- **THEN** the SDK asynchronously uploads the current accumulated duration

#### Scenario: Playback is paused or seeked
- **WHEN** playback is paused or seeked after measurable playback time
- **THEN** the SDK asynchronously uploads the latest accumulated duration

#### Scenario: Player is released
- **WHEN** the player is released after measurable playback time
- **THEN** the SDK queues the latest accumulated duration for upload without blocking teardown

#### Scenario: Duplicate or regressing duration is calculated
- **WHEN** the calculated duration is equal to or lower than the highest successfully uploaded duration
- **THEN** the SDK does not issue another upload for that duration

### Requirement: Serialize and complete analytics uploads

The analytics uploader SHALL serialize uploads and preserve queued duration updates in order. If a presigned upload returns `403`, it MUST fetch one replacement presigned URL and retry the affected duration once. Analytics request failures MUST NOT interrupt or fail media playback.

#### Scenario: Upload is already in flight
- **WHEN** a heartbeat, lifecycle event, or release queues another duration
- **THEN** the new duration waits for the active upload to finish before being sent

#### Scenario: Presigned upload is forbidden
- **WHEN** an analytics upload returns HTTP 403
- **THEN** the uploader clears the URL, fetches one replacement URL, and retries that duration once

#### Scenario: Analytics request fails
- **WHEN** a presign or upload request fails or returns a non-success status
- **THEN** the SDK abandons that analytics update and leaves media playback unaffected

#### Scenario: Tracker is deallocated after release
- **WHEN** the player is deallocated immediately after release while a final upload is queued
- **THEN** the uploader retains and processes the queued final upload independently of the tracker lifecycle

### Requirement: Use the existing provider-specific network architecture

Analytics endpoint definitions SHALL remain in `StreamsAPI`, analytics request and upload transport SHALL remain in `BaseAPI`, and analytics response decoding SHALL remain in `StreamsAPIParser`. Analytics implementation details MUST remain internal to the SDK.

#### Scenario: Presigned URL is requested
- **WHEN** the TPStreams tracker initializes an analytics session
- **THEN** the request uses the existing API service and parser flow to obtain the presigned upload URL

#### Scenario: Non-TPStreams provider is active
- **WHEN** an analytics API method is reached while the active provider is not TPStreams
- **THEN** the API refuses the analytics operation without invoking a TPStreams endpoint
