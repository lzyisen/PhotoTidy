# Contributing to Photo Tidy

Thanks for helping improve Photo Tidy. The project is a local-only SwiftUI app, so contributions should preserve the privacy boundary and the explicit deletion-review flow.

## Development setup

1. Install a full Xcode release with an iOS SDK that supports the project’s iOS 17 deployment target.
2. Open `PhotoTidy.xcodeproj`.
3. Select your own Apple Team and a unique bundle identifier for device testing. Do not commit personal signing identifiers.
4. Run the verification script from the repository root:

   ```zsh
   DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" scripts/verify.sh
   ```

   Replace the example `DEVELOPER_DIR` with the full Xcode installation on your Mac.

## Safety expectations

- Never add a direct delete path from a swipe, app launch, session completion, or persistence restore.
- Keep deletion behind the review queue and Apple’s Photos confirmation flow.
- Use a disposable photo set for destructive tests. Never test deletion against photos you cannot replace.
- Do not add photo uploads, analytics, remote storage, or third-party SDKs without documenting a deliberate privacy decision first.

## Pull requests

Keep changes focused, explain the user-visible impact, update `CHANGELOG.md` and `PROJECT_LOG.md`, and include the verification command and result. For UI changes, include the device model and iOS build used for manual testing.
