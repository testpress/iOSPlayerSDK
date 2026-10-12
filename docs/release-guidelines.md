# Release Guidelines

This document outlines the step-by-step process, automated CI/CD workflows, and troubleshooting steps for releasing a new version of the **TPStreamsSDK**.

---

## 1. Overview of the Release Pipeline

The SDK is distributed through two channels:
1. **Swift Package Manager (SPM)**: Resolves directly via Git tags on the GitHub repository.
2. **CocoaPods**: Published to the CocoaPods Trunk (`TPStreamsSDK.podspec`).

Releases are automated via GitHub Actions:

* **[publish.yml](../.github/workflows/publish.yml)** (*Publish to CocoaPods*):
  * Triggered automatically on push to `main` when `TPStreamsSDK.podspec` or `CHANGELOG.md` is modified.
  * Reads the version from `TPStreamsSDK.podspec`.
  * Verifies if the version is already published on CocoaPods.
  * Creates and pushes the annotated Git tag (e.g. `1.2.43`).
  * Runs `pod trunk push TPStreamsSDK.podspec --allow-warnings` using `COCOAPODS_TRUNK_TOKEN`.

* **[release.yml](../.github/workflows/release.yml)** (*Create GitHub Release*):
  * Triggers automatically after *Publish to CocoaPods* finishes successfully.
  * Parses [CHANGELOG.md](../CHANGELOG.md) for the section corresponding to the target version.
  * Creates or updates the GitHub Release with the tag name and extracted notes.

---

## 2. Pre-Release Verification (Local)

Before submitting a release PR, perform the following quality checks:

### 1. Run Unit Tests
Ensure all automated tests pass:
```bash
xcodebuild test \
  -project iOSPlayerSDK.xcodeproj \
  -scheme iOSPlayerSDKTests \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### 2. Verify Sample Apps
Run and test the sample projects on a simulator:
* Scheme: `Example` (SwiftUI demo)
* Scheme: `StoryboardExample` (UIKit demo)

### 3. Lint the Podspec
Verify that CocoaPods can build and validate the podspec without errors:
```bash
pod lib lint TPStreamsSDK.podspec --allow-warnings
```

---

## 3. Step-by-Step Release Process

### Step 1: Create a Release Branch
```bash
git checkout main
git pull origin main
git checkout -b release/x.y.z
```

### Step 2: Update Version in Podspec
Update `spec.version` in [TPStreamsSDK.podspec](../TPStreamsSDK.podspec):
```ruby
Pod::Spec.new do |spec|
  spec.name         = "TPStreamsSDK"
  spec.version      = "X.Y.Z" # <-- Update version here (Semantic Versioning: MAJOR.MINOR.PATCH)
  ...
```

### Step 3: Update Changelog
Add an entry for the new version in [CHANGELOG.md](../CHANGELOG.md).

> [!IMPORTANT]
> The GitHub Actions workflow relies on a regex pattern matching `## X.Y.Z` or `## [X.Y.Z]`. Always adhere to this heading format:

```markdown
## X.Y.Z - YYYY-MM-DD

### Added
- Feature description

### Changed
- Change description

### Fixed
- Bug fix description
```

### Step 4: Open a PR and Merge to `main`
1. Commit the changes:
   ```bash
   git add TPStreamsSDK.podspec CHANGELOG.md
   git commit -m "chore: bump version to X.Y.Z"
   git push origin release/x.y.z
   ```
2. Open a Pull Request into `main`.
3. Once approved and checks pass, merge the PR into `main`.

### Step 5: Monitor Automation
1. Navigate to **Actions** on GitHub.
2. Watch the **Publish to CocoaPods** workflow. It will:
   * Verify the version.
   * Create and push the Git tag `X.Y.Z`.
   * Push the pod to CocoaPods Trunk.
3. Once completed, watch the **Create GitHub Release** workflow. It will:
   * Extract notes for `X.Y.Z` from `CHANGELOG.md`.
   * Create the GitHub Release under tag `X.Y.Z`.

---

## 4. Manual Fallback & Troubleshooting

### Triggering Workflows Manually via GitHub UI
Both workflows support manual triggers via `workflow_dispatch`:
* If CocoaPods publishing failed due to network glitch:
  * Go to **Actions** > **Publish to CocoaPods** > **Run workflow** on `main`.
* If the GitHub Release did not get created or changelog formatting was updated:
  * Go to **Actions** > **Create GitHub Release** > **Run workflow** on `main` (optionally specifying the version).

### CocoaPods Token Issues
If CocoaPods publishing fails with authentication errors:
1. Ensure the secret `COCOAPODS_TRUNK_TOKEN` is valid and configured in repository Secrets.
2. If publishing locally via CocoaPods CLI:
   ```bash
   pod trunk register <email> '<name>' --description='<machine>'
   pod trunk push TPStreamsSDK.podspec --allow-warnings
   ```

### Tag Already Exists
If a release failed midway and the Git tag was created before CocoaPods publication:
* The workflow detects existing tags and will proceed to publish to CocoaPods if the version is not yet present on CocoaPods Trunk.
* If a tag needs to be deleted remotely to re-run from scratch:
  ```bash
  git tag -d X.Y.Z
  git push --delete origin X.Y.Z
  ```
