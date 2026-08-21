import XCTest
@testable import PhotoTidy

final class ReviewModelsTests: XCTestCase {
    func testRecordingDecisionAdvancesSessionAndTracksCounts() {
        var session = ActiveReviewSession(assetIdentifiers: ["one", "two"])

        let first = session.recordCurrent(.keep)
        let second = session.recordCurrent(.delete)

        XCTAssertEqual(first?.assetIdentifier, "one")
        XCTAssertEqual(second?.assetIdentifier, "two")
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.reviewedCount, 2)
        XCTAssertEqual(session.keptCount, 1)
        XCTAssertEqual(session.queuedForDeletionCount, 1)
    }

    func testUndoRestoresTheCurrentPhoto() {
        var session = ActiveReviewSession(assetIdentifiers: ["one", "two"])
        _ = session.recordCurrent(.delete)

        let undone = session.undoLastDecision()

        XCTAssertEqual(undone?.assetIdentifier, "one")
        XCTAssertEqual(undone?.decision, .delete)
        XCTAssertEqual(session.currentAssetIdentifier, "one")
        XCTAssertEqual(session.reviewedCount, 0)
    }

    func testDeletingDecisionIsQueuedAndUndoRemovesIt() {
        var state = PersistedReviewState.empty
        let decision = DecisionRecord(
            id: UUID(),
            assetIdentifier: "photo-id",
            decision: .delete,
            decidedAt: Date()
        )

        state.apply(decision)

        XCTAssertEqual(state.pendingDeletionIdentifiers, ["photo-id"])
        XCTAssertTrue(state.reviewedAssetIdentifiers.contains("photo-id"))

        state.reverse(decision)

        XCTAssertTrue(state.pendingDeletionIdentifiers.isEmpty)
        XCTAssertFalse(state.reviewedAssetIdentifiers.contains("photo-id"))
    }
}
