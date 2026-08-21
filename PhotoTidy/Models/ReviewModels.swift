import Foundation

enum SwipeDecision: String, Codable, CaseIterable {
    case keep
    case delete
}

struct DecisionRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let assetIdentifier: String
    let decision: SwipeDecision
    let decidedAt: Date
}

struct ActiveReviewSession: Codable, Equatable {
    let id: UUID
    var assetIdentifiers: [String]
    var cursor: Int
    var history: [DecisionRecord]

    init(assetIdentifiers: [String]) {
        self.id = UUID()
        self.assetIdentifiers = assetIdentifiers
        self.cursor = 0
        self.history = []
    }

    var currentAssetIdentifier: String? {
        guard cursor < assetIdentifiers.count else { return nil }
        return assetIdentifiers[cursor]
    }

    var nextAssetIdentifier: String? {
        let nextIndex = cursor + 1
        guard nextIndex < assetIdentifiers.count else { return nil }
        return assetIdentifiers[nextIndex]
    }

    var isComplete: Bool {
        cursor >= assetIdentifiers.count
    }

    var reviewedCount: Int {
        history.count
    }

    var keptCount: Int {
        history.filter { $0.decision == .keep }.count
    }

    var queuedForDeletionCount: Int {
        history.filter { $0.decision == .delete }.count
    }

    @discardableResult
    mutating func recordCurrent(_ decision: SwipeDecision) -> DecisionRecord? {
        guard let identifier = currentAssetIdentifier else { return nil }

        let record = DecisionRecord(
            id: UUID(),
            assetIdentifier: identifier,
            decision: decision,
            decidedAt: Date()
        )
        history.append(record)
        cursor += 1
        return record
    }

    @discardableResult
    mutating func undoLastDecision() -> DecisionRecord? {
        guard let record = history.popLast() else { return nil }
        cursor = max(0, cursor - 1)
        return record
    }
}

struct PersistedReviewState: Codable, Equatable {
    var schemaVersion: Int = 1
    var activeSession: ActiveReviewSession?
    var reviewedAssetIdentifiers: Set<String> = []
    var pendingDeletionIdentifiers: [String] = []
    var completedSessionCount: Int = 0

    static let empty = PersistedReviewState()

    mutating func apply(_ record: DecisionRecord) {
        reviewedAssetIdentifiers.insert(record.assetIdentifier)

        if record.decision == .delete,
           !pendingDeletionIdentifiers.contains(record.assetIdentifier) {
            pendingDeletionIdentifiers.append(record.assetIdentifier)
        }
    }

    mutating func reverse(_ record: DecisionRecord) {
        reviewedAssetIdentifiers.remove(record.assetIdentifier)

        if record.decision == .delete {
            pendingDeletionIdentifiers.removeAll { $0 == record.assetIdentifier }
        }
    }

    mutating func removeFromDeletionQueue(identifier: String) {
        pendingDeletionIdentifiers.removeAll { $0 == identifier }
    }
}
