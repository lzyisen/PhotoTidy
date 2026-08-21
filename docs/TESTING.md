# Testing Guide

## Automated checks

Run the repeatable compilation checks from the repository root:

```zsh
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" scripts/verify.sh
```

The script performs three checks:

1. Builds the app for a generic iOS Simulator target.
2. Compiles the unit-test bundle with `build-for-testing`.
3. Builds an unsigned arm64 app for a generic iPhone target.

The unit tests cover the deterministic model behavior: progression, Keep/Delete counts, Undo, and deletion-queue state. A Simulator runtime or physical device is required to execute them.

## Physical-device checklist

Use a small disposable set of photos for the deletion part of this test.

1. Install through Xcode using the Personal Team configuration.
2. Grant full Photos access and confirm the first screen begins a 50-photo random session.
3. Swipe right five times and left five times. Confirm the counters read 5 kept and 5 queued.
4. Force-quit the app and reopen it. Confirm it continues at photo 11 of the same session.
5. Tap Undo once, confirm the tenth decision and counter revert, then make the decision again.
6. Open the deletion queue. Confirm all queued thumbnails are visible; change one queued photo back to Keep.
7. Tap Delete. Confirm iOS, not the app, owns the final confirmation prompt.
8. Cancel once and verify the queue is preserved. Then repeat, accept the prompt, and confirm the deleted items leave the queue.
9. Complete a 50-photo session. Confirm the summary provides Review Queue, Start Another 50, and the ability to stop safely.
10. In Settings, switch to limited Photos access; reopen the app and confirm it accurately labels the restricted scope and only reviews selected assets.

## Results record

Record the date, iPhone model, iOS version, Xcode version, and pass/fail observations in `PROJECT_LOG.md` after each physical test session.
