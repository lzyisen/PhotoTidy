# Architecture

## Overview

```text
SwiftUI views
    │
    ▼
ReviewSession (@MainActor)
    ├── PhotoLibraryService → Apple PhotoKit
    └── ReviewStateStore → Application Support/review-state.json
```

`ReviewSession` owns the user-visible state. It chooses the session, applies swipes, supports Undo, exposes the deletion queue, and persists a snapshot after each decision.

## Session model

An active session stores at most 50 PhotoKit local identifiers in a fixed random order. It also stores a cursor and a decision history.

- The first session is created from all accessible, unreviewed image identifiers.
- A new session shuffles candidates and selects at most 50.
- The session’s IDs and cursor are saved immediately after every decision.
- On relaunch, the same list and cursor restore the exact next photo.
- Photos deleted outside the app are safely skipped when encountered.

## Deletion safety

```text
Swipe left → local queue → review grid → user taps Delete → PhotoKit batch request → iOS confirmation
```

No swipe directly writes to the library. The batch request is submitted only from the review grid. If iOS declines, cancels, or errors, the local queue remains intact.

## Memory policy

The app stores identifiers and lightweight Codable state, not the library’s photo bytes. `PHCachingImageManager` requests the current view’s screen-sized image. The review view keeps only the current and next cards visible, avoiding a growing decoded-image cache as the user reviews hundreds or thousands of photos.

## Privacy boundary

The project links only Apple platform frameworks. There is no network client, SDK package, analytics pipeline, account system, remote database, or image upload path. When iCloud Photos needs to retrieve an optimized asset, that transfer is handled by Apple’s own Photos system, not an app-operated backend.
