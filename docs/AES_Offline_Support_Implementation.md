# AES Offline Support Implementation Guide

This document explains how AES encryption offline support was implemented in the iOS PlayerSDK. It describes the approach, flow, and key decisions so that anyone (including an AI) can understand and replicate the implementation.

---

## 1. Problem Statement

When videos are encrypted with AES encryption for HLS streaming, the encryption key must be available during playback. For offline playback (downloaded videos), we cannot fetch the key from the network since there's no internet connection. Therefore, we need to:

1. Fetch and store the encryption key before/during download
2. Store it securely on the device
3. When playing offline, redirect key requests from network to local storage

---

## 2. High-Level Approach

The implementation follows this approach:

1. **Prefetch Key Before Download**: When user starts downloading an AES-encrypted video, first fetch the encryption key from the server and store it in the device's Keychain.

2. **Secure Key Storage**: Use iOS Keychain to store encryption keys securely. Keys persist on the device and are accessible even after device restart.

3. **Modify Downloaded Manifests**: After download completes, modify the M3U8 playlist files to change key URLs from HTTPS to a custom local scheme (`tpkey://`). This tricks AVPlayer into requesting the key through our custom resource loader.

4. **Intercept Key Requests**: Create a custom AVAssetResourceLoaderDelegate that intercepts key requests. When playing offline, it reads the key from Keychain instead of making network requests.

5. **Handle Multiple Identifiers**: Different providers (TPStreams, Testpress) use different identifiers for keys. The implementation tries multiple identifiers (videoId, assetId, offlineAssetId) to find the correct key.

---

## 3. Component Responsibilities

### 3.1 Video/Asset Models
- Video model has `isAESEncrypted` flag that checks if `contentProtectionType == .aes`
- Asset model has `keyIdentifier` property that returns the correct ID based on provider (videoId for Testpress, assetId for TPStreams)

### 3.2 EncryptionKeyRepository
- Singleton class that handles all Keychain operations
- Service ID: `com.tpstreams.iOSPlayerSDK.encryption.keys`
- Keys are stored with prefix `VIDEO_ENCRYPTION_KEY_`
- Accessibility: `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (available after first device unlock, stays on device)
- Provides: save(), get(), delete(), deleteAll() methods

### 3.3 AESKeyManager
- Fetches encryption keys using two strategies:
  - **Primary**: Call dedicated API endpoint for encryption key
  - **Fallback**: Parse M3U8 playlist to find key URL, then fetch from there
- API Endpoints:
  - TPStreams: `https://app.tpstreams.com/api/v1/{org}/assets/{assetId}/aes_key/`
  - Testpress: `https://{org}.testpress.in/api/v2.5/encryption_key/{videoId}/`
- Provides `prefetchEncryptionKey()` method called before download starts

### 3.4 ResourceLoaderDelegate
- Implements `AVAssetResourceLoaderDelegate` protocol
- Intercepts AVPlayer's key requests
- Handles three scenarios:
  - **Custom scheme (tpkey://)**: Extract identifier from URL, look up in Keychain
  - **HTTPS in offline mode**: Redirect to Keychain lookup
  - **HTTPS in online mode**: Fetch from network
- Tries multiple fallback identifiers if primary lookup fails
- Returns `keyMissing` error if key not found

### 3.5 TPStreamsDownloadManager
- Orchestrates the download process
- Before download: Calls `AESKeyManager.prefetchEncryptionKey()` if video is AES-encrypted
- After download: Calls `hardenOfflineManifests()` to modify M3U8 files
- When deleting: Calls `deleteEncryptionKeys()` to clean up Keychain

### 3.6 Manifest Hardening
- Iterates through all downloaded M3U8 files
- Finds `#EXT-X-KEY` tags with encryption key URIs
- Replaces HTTPS URIs with `tpkey://{identifier}`
- Example transformation:
  - Before: `URI="https://api.example.com/aes_key/123"`
  - After: `URI="tpkey://123"`

---

## 4. Complete Flow

### 4.1 Download Flow

```
User clicks download
        │
        ▼
Check if video.isAESEncrypted == true
        │
        ▼
Call AESKeyManager.prefetchEncryptionKey()
        │
        ├──► Fetch from API endpoint
        │         │
        │         ▼
        │    Store key in Keychain
        │
        └──► If API fails, parse M3U8 playlist
                  │
                  ▼
            Extract key URL from #EXT-X-KEY tag
                  │
                  ▼
            Fetch key and store in Keychain
                  │
                  ▼
Start AVAssetDownloadURLSession download
        │
        ▼
Download completes successfully
        │
        ▼
Call hardenOfflineManifests()
        │
        ▼
For each M3U8 file:
  - Replace #EXT-X-KEY URI from HTTPS to tpkey://
  - Save modified file
        │
        ▼
Download finished - key stored, manifest modified
```

### 4.2 Offline Playback Flow

```
User opens downloaded video for offline playback
        │
        ▼
Initialize AVPlayer with offline asset
        │
        ▼
Configure ResourceLoaderDelegate with isPlaybackOffline: true
        │
        ▼
AVPlayer loads modified M3U8 manifest
        │
        ▼
AVPlayer encounters #EXT-X-KEY tag with tpkey:// scheme
        │
        ▼
AVPlayer requests key through ResourceLoaderDelegate
        │
        ▼
handleLocalKeyRequest() called
        │
        ▼
Extract identifier from tpkey:// URL
        │
        ▼
Try to get key from Keychain using identifier
        │
        ├──► Key found → Return key data to AVPlayer
        │
        └──► Key not found
                  │
                  ▼
            Try fallback identifiers (assetId, offlineAssetId)
                  │
                  ├──► Any key found → Return to AVPlayer
                  │
                  └──► None found → Return keyMissing error
        │
        ▼
AVPlayer decrypts and plays content
```

---

## 5. Key Design Decisions

### 5.1 Why Keychain?
- Secure storage provided by iOS OS
- Keys persist across app restarts
- Accessible after first device unlock
- Device-only (not backed up to iCloud)

### 5.2 Why Custom Scheme (tpkey://)?
- AVPlayer must request key through AVAssetResourceLoaderDelegate
- HTTPS requests go directly to network (bypass delegate)
- Custom scheme forces AVPlayer to go through delegate
- Delegate then handles lookup from local storage

### 5.3 Why Multiple Identifiers?
- Different providers store keys differently
- TPStreams uses assetId
- Testpress uses videoId
- During download, we might have offlineAssetId
- Trying all three ensures maximum compatibility

### 5.4 Why Prefetch Before Download?
- If network fails during download, we still have the key
- Download might take time, key might expire
- Prefetch ensures key is ready when playback starts

### 5.5 Why Two-Step Key Fetching?
- Primary: API endpoint is reliable and direct
- Fallback: Playlist parsing works even if API is down
- This redundancy ensures keys are fetched in most cases

---

## 6. Data Flow Summary

```
┌─────────────────────────────────────────────────────────────┐
│                     ONLINE SCENARIO                         │
├─────────────────────────────────────────────────────────────┤
│  AVPlayer ──► ResourceLoaderDelegate ──► Network API       │
│                         │                  │                │
│                         ▼                  ▼                │
│                    Return key          Return key           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    OFFLINE SCENARIO                        │
├─────────────────────────────────────────────────────────────┤
│  Download Time:                                            │
│  AESKeyManager ──► Network API ──► Keychain (save)         │
│                           │                                 │
│                           ▼                                 │
│                    Harden Manifests                         │
│                    (HTTPS → tpkey://)                      │
│                                                             │
│  Playback Time:                                            │
│  AVPlayer ──► ResourceLoaderDelegate ──► Keychain (read)   │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Files Involved

| File | Purpose |
|------|---------|
| `Video.swift` | Model with isAESEncrypted, keyIdentifier |
| `Asset.swift` | Model with provider-specific keyIdentifier |
| `EncryptionKeyRepository.swift` | Keychain operations (save, get, delete) |
| `AESKeyManager.swift` | Fetch keys from API or playlist |
| `ResourceLoaderDelegate.swift` | Intercept and handle key requests |
| `TPStreamsDownloadManager.swift` | Orchestrate download, prefetch, harden |
| `BaseAPI.swift` | Define AES_ENCRYPTION_KEY_API |
| `StreamsAPI.swift` | TPStreams endpoint configuration |
| `TestpressAPI.swift` | Testpress endpoint configuration |

---

## 8. Error Handling

| Error | Code | Scenario |
|-------|------|----------|
| keyMissing | 5009 | Key not found in Keychain during offline playback |

---

## 9. Testing Scenarios

1. Download AES-encrypted video → Verify key exists in Keychain
2. Play downloaded video offline → Verify it plays without network
3. Delete download → Verify key is removed from Keychain
4. Play online AES video → Verify network fetch works
5. Test with both TPStreams and Testpress providers
6. Test when API fails but playlist has key URL

---

## 10. Summary

The AES offline support implementation:

1. **Fetches** encryption key before download using API or playlist parsing
2. **Stores** key securely in iOS Keychain
3. **Modifies** downloaded M3U8 manifests to use custom `tpkey://` scheme
4. **Intercepts** key requests via ResourceLoaderDelegate
5. **Serves** keys from Keychain during offline playback

This approach ensures AES-encrypted videos can be played offline while keeping encryption keys secure on the device.
