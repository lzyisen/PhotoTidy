# Changelog

All notable changes to Photo Tidy are documented here. This project follows a lightweight form of [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and uses semantic versioning.

## [Unreleased]

### Added

- Original Photo Tidy app icon: layered photos, a warm landscape, and a checkmark that conveys a satisfying keep decision.
- MIT license and open-source contributor, security, and pull-request guidance.

### Verified

- Initial physical iPhone smoke test passed through the owner’s Personal Team installation; no issues were reported.

### Planned

- Physical-device verification and Personal Team signing record.
- A signed development archive once a connected iPhone and Apple account are available.
- App-owned confirmation of the reviewed deletion count and a final queue-snapshot validation before the PhotoKit request.

### Changed

- Source packages are generated from an explicit version tag and cannot overwrite an existing versioned artifact.
- Removed local temporary build and generation artifacts after verification; product source and release artifacts are unchanged.

## [0.1.0] - 2026-08-17

### Added

- A native SwiftUI iPhone app targeting iOS 17 and later.
- Random, persisted review sessions of up to 50 photos.
- Keep/delete gestures, button alternatives, session counters, and Undo.
- Local PhotoKit permission handling for full and limited Photos access.
- Persisted local review state using PhotoKit identifiers only.
- A deletion-queue thumbnail grid with batch deletion through the iOS-controlled confirmation flow.
- Unit tests for session progression, Undo, and queue-state behavior.
- Build, release, testing, architecture, and privacy documentation.

### Privacy

- No third-party packages, cloud backend, analytics, account system, or app-owned image storage.
