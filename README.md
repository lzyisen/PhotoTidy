# Photo Tidy

Photo Tidy is an open-source, local-first iPhone app for making photo cleanup manageable: it presents a random 50-photo session, saves every decision immediately, and delays deletion until a final review.

Current version: **0.1.0**

The project is available under the [MIT License](LICENSE). It is a personal-use MVP and is not currently distributed through the App Store.

## What it does

- Creates a stable, random session of up to 50 previously unreviewed photos.
- Swipes right to keep and left to queue for deletion; buttons provide the same actions.
- Preserves the exact position, decisions, Undo history, and deletion queue across app launches.
- Shows a thumbnail review grid before submitting one PhotoKit batch-deletion request.
- Requests only screen-sized images at runtime; it does not copy the library into app storage.

## Privacy and dependencies

All product code is custom Swift and uses only Apple frameworks: SwiftUI, PhotoKit, UIKit, and Foundation. There are no third-party packages, accounts, analytics SDKs, servers, or app-owned network calls. Apple’s Photos system can retrieve an iCloud-backed image when necessary; Photo Tidy does not upload photos itself.

Deletion is intentionally staged: a swipe only queues a PhotoKit local identifier, the user reviews the queue, and PhotoKit presents Apple’s confirmation before the library change. Do not test the destructive path with irreplaceable photos.

## Repository guide

- [CHANGELOG.md](CHANGELOG.md) — user-facing version history.
- [PROJECT_LOG.md](PROJECT_LOG.md) — chronological decisions, changes, and verification results.
- [Architecture](docs/ARCHITECTURE.md) — data flow and privacy boundary.
- [Testing guide](docs/TESTING.md) — automated and physical-device checks.
- [Release checklist](docs/RELEASE_CHECKLIST.md) — packaging and signing process.
- [Contributing](CONTRIBUTING.md) — development, testing, and safety expectations.
- [Security and privacy](SECURITY.md) — reporting guidance and data boundaries.

## Requirements

- Full Xcode with an iOS SDK. The project targets iOS 17+.
- An Apple Account signed into Xcode as a Personal Team for free on-device testing.
- An iPhone connected to the Mac.

Command Line Tools alone cannot build or install this iOS app; use a full Xcode installation.

## Build and verification

From the repository root, run:

```zsh
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" scripts/verify.sh
```

Replace the example `DEVELOPER_DIR` with the full Xcode installation on your Mac. This performs an unsigned simulator compilation, compiles the unit-test bundle, and compiles an arm64 iPhone build. A simulator runtime or physical iPhone is required to execute the unit tests.

## Run on an iPhone

1. Open `PhotoTidy.xcodeproj` with the full Xcode app.
2. Select the `PhotoTidy` target, then **Signing & Capabilities**.
3. Choose your Personal Team. If Xcode reports that the bundle identifier is unavailable, change it to a unique value such as `com.yourname.PhotoTidy`.
4. Connect and unlock the iPhone, then select it as the run destination.
5. Press Run and grant Photos access. Full access enables the whole library; limited access works for the user-selected subset.
6. Follow the [physical-device checklist](docs/TESTING.md#physical-device-checklist).

For a free Personal Team, Apple requires re-provisioning after seven days. Re-run the same project from Xcode; do not delete the app if you want to retain its saved local progress.

## Packaging

Create a reproducible source package from a clean Git commit:

```zsh
scripts/package-source.sh
```

The ZIP and its SHA-256 checksum appear in `dist/` and are intentionally not committed. A signed iPhone archive requires the Personal Team configured in Xcode; use `scripts/archive-for-device.sh` only after that setup is complete.

The package script archives the matching `v<version>` Git tag rather than the current checkout, and refuses to overwrite an existing versioned artifact.
