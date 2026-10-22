## Context

The native iOS player already exposes lifecycle and playback state transitions, while TPStreams analytics expects a presigned upload URL followed by duration payload uploads. The implementation must fit the existing provider-specific API, parser, and player lifecycle architecture without introducing analytics behavior for TestPress or offline playback.

## Goals / Non-Goals

**Goals:**

- Track online TPStreams playback with stable visitor and per-session identities.
- Send duration updates on a five-minute heartbeat and meaningful lifecycle events.
- Preserve the final duration when teardown occurs during another upload.
- Keep analytics asynchronous, serialized, and isolated from playback errors.
- Reuse the existing `BaseAPI`, `StreamsAPI`, and `StreamsAPIParser` responsibilities.

**Non-Goals:**

- Add analytics to TestPress, offline playback, or other providers.
- Expose analytics classes or configuration as public SDK API.
- Block, fail, or alter media playback when analytics requests fail.

## Decisions

### Provider-gated tracker

Create the tracker only for online TPStreams playback. Provider checks remain at the tracker and API boundaries so other providers do not invoke TPStreams analytics endpoints.

### Existing network architecture

Keep endpoint construction in `StreamsAPI`, request and upload execution in `BaseAPI`, and response decoding in `StreamsAPIParser`. This preserves the SDK's current separation between endpoint definitions, transport, and parsing instead of placing network logic in the tracker.

### Serialized uploader state

Protect presigned URL state, presign request coalescing, pending uploads, and upload ordering with a private serial queue. A single active upload is allowed at a time; later heartbeat, pause, seek, or release values are queued and sent in order.

### Lifecycle-safe final upload

On release, accumulate the active playback segment and enqueue the final duration directly with the uploader. The uploader retains itself through queued and in-flight work, so the final upload does not depend on the player or tracker remaining alive. A single presigned URL refresh and retry is allowed after a `403` response.

### Monotonic duration reporting

The tracker records the highest successfully uploaded duration and does not send duplicate or regressing values. The uploader's serialization avoids relying on server-side ordering for concurrent duration writes.

### Identity and timer handling

Persist the visitor ID in Keychain with a process-stable fallback if persistence is unavailable. Generate a new session ID for each tracker. Heartbeat timer invalidation is marshalled to the main thread because the timer is attached to the main run loop.

## Risks / Trade-offs

- [Analytics endpoint or presigned upload fails] → Drop the analytics update and leave playback running normally.
- [Player is released during an active upload] → Queue the final duration in the uploader, which serializes it after the active request.
- [Presigned URL expires] → Clear it, fetch one replacement URL, and retry the affected duration once.
- [Keychain is unavailable] → Use one generated visitor ID for the process rather than generating a different ID on every request.
- [Heartbeat timers are delayed by application scheduling] → Lifecycle events and release still trigger duration uploads when possible.

## Migration Plan

No migration is required. The behavior is internal to the SDK and automatically applies only to new online TPStreams sessions. Existing consumers do not need to change their integration.

## Open Questions

None for this implementation.
