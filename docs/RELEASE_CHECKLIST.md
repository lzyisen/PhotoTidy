# Release Checklist

## 1. Prepare

- [ ] Update `VERSION`, the target Marketing Version, `CHANGELOG.md`, and `PROJECT_LOG.md`.
- [ ] Review `git status` and ensure no accidental files are staged.
- [ ] Run `scripts/verify.sh` with a full Xcode installation.
- [ ] Complete the relevant physical-device checks in `docs/TESTING.md`.

## 2. Commit and tag

- [ ] Commit the finished changes with a focused message.
- [ ] Create an annotated tag: `git tag -a v<version> -m "Photo Tidy <version>"`.
- [ ] Confirm the tag points at the intended commit: `git show v<version> --stat`.

## 3. Package

- [ ] Create the reproducible source ZIP from the matching Git tag: `scripts/package-source.sh`.
- [ ] Verify the checksum: `shasum -a 256 -c dist/PhotoTidy-v<version>-source.zip.sha256`.
- [ ] If the app is signed, create an Xcode archive with `scripts/archive-for-device.sh`.

## 4. Handoff

- [ ] Add final verification and package paths to `PROJECT_LOG.md`.
- [ ] Keep the source ZIP, checksum, and Xcode archive in a user-selected backup location.
- [ ] Do not claim distribution readiness until the Personal Team or paid-developer signing path has been exercised on a device.
