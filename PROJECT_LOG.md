# Project Log

This is the chronological engineering record for Photo Tidy. Each completed implementation, verification, packaging, or release step receives a dated entry.

## Project boundaries

- **Product:** a personal iPhone photo-review app that uses random sessions of up to 50 photos.
- **Privacy:** local-only app logic; PhotoKit is the sole route to the Photos library; no third-party code or services.
- **Distribution for now:** Xcode Personal Team installation onto the owner’s iPhone.
- **Source of truth:** Git repository, tagged releases, this log, and `CHANGELOG.md`.

## 2026-08-17 — Foundation and MVP

### 01. Product decisions locked

- Defined a 50-photo maximum session to keep cleanup low-pressure.
- The selected random ordering is persisted, so a partial session resumes at the next unseen photo rather than reshuffling completed work.
- A left swipe only queues deletion. The app sends one batch change request only after the user opens the review grid and explicitly chooses deletion.
- Photo content is not duplicated; only identifiers and decisions are persisted.

### 02. Initial app implementation

- Created the `PhotoTidy` SwiftUI app target for iOS 17+.
- Added PhotoKit access, random selection of unreviewed image identifiers, session persistence, swipe actions, Undo, and the deletion-review grid.
- Added a minimal unit-test target covering decision flow, Undo, and deletion-queue persistence semantics.
- Set the initial product version to `0.1.0` and build number to `1`.

### 03. Build verification

- Used a full Xcode 27 beta installation; the active `xcode-select` path was Command Line Tools and could not build iOS apps alone.
- Confirmed Xcode recognizes the `PhotoTidy` app and `PhotoTidyTests` targets.
- Compiled the app for an iOS Simulator target successfully.
- Compiled the unit-test bundle successfully.
- Compiled an unsigned arm64 iPhone build successfully.
- Verified the generated Info.plist has the display name, bundle identifier, and Photos usage description.
- Observed unsigned debug app bundle size: `1.3 MB`.

### 04. Verification limits

- No iOS Simulator runtime is installed, so the tests compiled but were not executed.
- No physical iPhone is currently connected, so signing, installation, permission behavior, persistence behavior, and actual PhotoKit deletion flow remain pending device verification.

### 05. Workspace hygiene

- Moved the `313 MB` temporary compiler cache generated during local verification to recoverable Trash.
- Added ignore rules for local build output, release packages, user Xcode data, and macOS metadata.

## 2026-08-17 — Project workflow and release preparation

### 06. Complete-project workflow added

- Added semantic version source `VERSION` (`0.1.0`) and aligned the Xcode Marketing Version to it.
- Added `CHANGELOG.md`, this project log, architecture notes, a testing guide, and a release checklist.
- Added a repeatable verification script, a clean-commit source-package script, and a signed-device archive script.
- The source package script intentionally refuses a dirty Git worktree, making every generated ZIP reproducible from a commit.

### 07. Repeatable verification exercised

- Ran `scripts/verify.sh` with full Xcode 27 beta supplied through `DEVELOPER_DIR`.
- Simulator compilation, unit-test bundle compilation, and unsigned iPhone arm64 compilation all passed.
- The generated build output is ignored and will not enter version control or release ZIPs.

### 08. Version-control baseline

- Configured local-only Git author metadata: `Yisen Wang <yisenwang@localhost>`; no remote was added or contacted.
- Created the initial commit: `cf8151b feat: release Photo Tidy MVP 0.1.0`.
- Created the annotated release tag `v0.1.0` from that exact clean commit.

### 09. Source packaging

- Generated `dist/PhotoTidy-v0.1.0-source.zip` directly from the `v0.1.0` source commit.
- Generated and verified `dist/PhotoTidy-v0.1.0-source.zip.sha256`.
- SHA-256: `69b31e2858a5c77fbdef400cd090a54031fc74b4639ea5b6008a3935b7bff9b7`.
- Moved the subsequent `505 MB` verification output and `452 KB` raw build log to recoverable Trash.

### 10. Release-package guardrail

- Updated `scripts/package-source.sh` so a package is always generated from its matching `v<version>` tag instead of from whichever commit is currently checked out.
- The script now refuses to overwrite an existing versioned ZIP or checksum. This prevents a later maintenance commit from silently replacing the `v0.1.0` source artifact.
- Verified the existing-artifact guard exits with status `1` and leaves the package untouched; the stored `v0.1.0` checksum still passes verification.

## 2026-08-17 — Pre-device deletion safety audit

### 11. Static deletion-path review

- Inspected every photo-library write path. `PHAssetChangeRequest.deleteAssets` occurs in one service method only; the sole UI caller is the red Delete button in the deletion-review grid.
- Verified that a swipe, a Keep action, Undo, app launch, session completion, and state restoration only change local app state. None can call PhotoKit deletion.
- Verified that the deletion request is built from exact persisted PhotoKit local identifiers, not from a broad library query, and only successful PhotoKit transactions clear items from the local queue. A cancellation or error leaves the queue intact.
- Confirmed against Apple PhotoKit documentation that each `performChanges` request presents an iOS-managed permission alert before the library is changed. Physical-device testing must still confirm that prompt and its cancellation behavior on the connected iPhone.

### 12. Safety hardening queued

- The current implementation is protected by the review grid plus Apple's system confirmation. Before calling the MVP complete, add an app-owned count confirmation and validate a fixed review-grid snapshot immediately before the PhotoKit request. These are defense-in-depth measures, not evidence of an automatic-deletion path.
- Xcode's Personal Team signing change in `PhotoTidy.xcodeproj` is user-owned, currently uncommitted, and was deliberately left untouched during this audit.

## 2026-08-17 — First physical-device run

### 13. Personal Team smoke test passed

- Confirmed a connected physical iPhone 17 Pro was visible to Xcode's device tools and launched the app through the owner's Personal Team configuration.
- The owner reported that the app worked perfectly during the first on-device run, with no functional feedback or defects observed.
- This records a successful exploratory smoke test. The more deliberate cancellation/acceptance deletion scenarios and the queued defense-in-depth hardening remain the final verification items before calling the MVP fully complete.

## 2026-08-17 — App icon design and implementation

### 14. Original application icon added

- Designed an original Photo Tidy icon using the built-in image-generation workflow: a layered photo stack, warm landscape, and clear checkmark on an indigo background. It avoids a trash-can metaphor so the app feels calm and intentional rather than destructive.
- Created an opaque 1024px master and all required iPhone icon renditions in `PhotoTidy/Assets.xcassets/AppIcon.appiconset`. The production files are local project assets; no remote image URL or third-party SDK is used by the app.
- Added the asset catalog to the app target and configured `AppIcon` as the compiler-managed application icon.
- Verified the catalog and an unsigned arm64 iPhone build with Xcode 27 beta. Xcode compiled `Assets.car` and the required application icon without asset warnings.

## 2026-08-17 — Local workspace cleanup

### 15. Disposable build output removed

- Permanently removed `930.9 MB` of confirmed disposable data: the temporary icon-build derived data, its intermediate image-conversion folder, the superseded generated source image, and the two prior verification caches that were already in Trash.
- Preserved all version-controlled project files, the committed app-icon assets, the `v0.1.0` source release ZIP and checksum, and the active uncommitted Personal Team signing configuration.

## 2026-08-20 — Open-source publication preparation

### 16. Public repository readiness

- Created a dedicated `codex/open-source-release` branch so the default branch is not changed implicitly during publication.
- Added the MIT license, contributor guidance, security/privacy reporting guidance, and a pull-request template.
- Replaced developer-machine paths in public documentation with portable Xcode examples.
- Confirmed the local Personal Team development identifier remains an uncommitted machine-specific change and is excluded from the public release.

## Next step

## 2026-08-20 — Public GitHub repository created

### 17. Publication target

- Created the public repository [`lzyisen/PhotoTidy`](https://github.com/lzyisen/PhotoTidy) with `main` as its default branch.
- The publication snapshot will contain only committed source and project documentation; the local Personal Team signing change remains excluded.
- Uploaded the complete clean source tree, including the Xcode project, SwiftUI/PhotoKit code, tests, icon assets, docs, scripts, license, and contribution/security guidance.
- Verified the public project file and documentation contain neither the local Personal Team identifier nor developer-machine paths.
- Published the `v0.1.0` GitHub release from public commit `c2df1cdc7b244d813b778bc64f9b38c222c68bbf`.
