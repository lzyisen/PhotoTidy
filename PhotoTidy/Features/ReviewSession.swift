import Foundation
import Photos
import SwiftUI
import UIKit

@MainActor
final class ReviewSession: ObservableObject {
    enum Phase: Equatable {
        case loading
        case permissionRequired
        case reviewing
        case sessionComplete
        case noPhotosRemaining
    }

    @Published private(set) var phase: Phase = .loading
    @Published private(set) var state = PersistedReviewState.empty
    @Published private(set) var currentAsset: PHAsset?
    @Published private(set) var nextAsset: PHAsset?
    @Published private(set) var queuedAssets: [PHAsset] = []
    @Published private(set) var isDeleting = false
    @Published var isDeletionQueuePresented = false
    @Published var errorMessage: String?

    private let photoLibrary = PhotoLibraryService.shared
    private let stateStore = ReviewStateStore()
    private var hasBootstrapped = false
    private var persistenceRevision = 0

    var isLimitedAccess: Bool {
        photoLibrary.authorizationStatus == .limited
    }

    var sessionTargetCount: Int {
        state.activeSession?.assetIdentifiers.count ?? 0
    }

    var sessionReviewedCount: Int {
        state.activeSession?.reviewedCount ?? 0
    }

    var sessionKeptCount: Int {
        state.activeSession?.keptCount ?? 0
    }

    var sessionDeletionCount: Int {
        state.activeSession?.queuedForDeletionCount ?? 0
    }

    var pendingDeletionCount: Int {
        state.pendingDeletionIdentifiers.count
    }

    var canUndo: Bool {
        !(state.activeSession?.history.isEmpty ?? true)
    }

    var sessionLabel: String {
        "Session \(state.completedSessionCount + 1)"
    }

    func bootstrap() async {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true
        phase = .loading
        state = await stateStore.load()
        await continueAfterAuthorizationCheck()
    }

    func requestPhotoAccess() async {
        phase = .loading
        _ = await photoLibrary.requestAuthorization()
        await continueAfterAuthorizationCheck()
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func decide(_ decision: SwipeDecision) {
        guard var activeSession = state.activeSession,
              let record = activeSession.recordCurrent(decision) else {
            return
        }

        state.activeSession = activeSession
        state.apply(record)
        persist()
        refreshVisibleAssets()
    }

    func undo() {
        guard var activeSession = state.activeSession,
              let record = activeSession.undoLastDecision() else {
            return
        }

        state.activeSession = activeSession
        state.reverse(record)
        persist()
        refreshVisibleAssets()
    }

    func startNextSession() async {
        if state.activeSession?.isComplete == true {
            state.completedSessionCount += 1
        }

        state.activeSession = nil
        persist()
        await startNewSession()
    }

    func showDeletionQueue() {
        queuedAssets = photoLibrary.assets(identifiers: state.pendingDeletionIdentifiers)
        isDeletionQueuePresented = true
    }

    func keepQueuedAsset(identifier: String) {
        state.removeFromDeletionQueue(identifier: identifier)
        queuedAssets.removeAll { $0.localIdentifier == identifier }
        persist()
    }

    func deleteQueuedAssets() async {
        let assetsToDelete = photoLibrary.assets(identifiers: state.pendingDeletionIdentifiers)
        guard !assetsToDelete.isEmpty else {
            state.pendingDeletionIdentifiers = []
            queuedAssets = []
            persist()
            return
        }

        isDeleting = true
        defer { isDeleting = false }

        do {
            try await photoLibrary.delete(assetsToDelete)
            let deletedIdentifiers = Set(assetsToDelete.map(\.localIdentifier))
            state.pendingDeletionIdentifiers.removeAll { deletedIdentifiers.contains($0) }
            queuedAssets.removeAll { deletedIdentifiers.contains($0.localIdentifier) }
            persist()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func continueAfterAuthorizationCheck() async {
        switch photoLibrary.authorizationStatus {
        case .authorized, .limited:
            if state.activeSession == nil {
                await startNewSession()
            } else {
                refreshVisibleAssets()
            }
        case .notDetermined:
            phase = .permissionRequired
        case .denied, .restricted:
            phase = .permissionRequired
        @unknown default:
            phase = .permissionRequired
        }
    }

    private func startNewSession() async {
        phase = .loading
        let candidates = photoLibrary.imageAssetIdentifiers(
            excluding: state.reviewedAssetIdentifiers
        )
        let selectedIdentifiers = Array(candidates.shuffled().prefix(50))

        guard !selectedIdentifiers.isEmpty else {
            currentAsset = nil
            nextAsset = nil
            phase = .noPhotosRemaining
            return
        }

        state.activeSession = ActiveReviewSession(assetIdentifiers: selectedIdentifiers)
        persist()
        refreshVisibleAssets()
    }

    private func refreshVisibleAssets() {
        guard var activeSession = state.activeSession else {
            currentAsset = nil
            nextAsset = nil
            phase = .noPhotosRemaining
            return
        }

        while let identifier = activeSession.currentAssetIdentifier,
              photoLibrary.asset(identifier: identifier) == nil {
            activeSession.assetIdentifiers.remove(at: activeSession.cursor)
        }

        state.activeSession = activeSession

        guard let currentIdentifier = activeSession.currentAssetIdentifier,
              let asset = photoLibrary.asset(identifier: currentIdentifier) else {
            currentAsset = nil
            nextAsset = nil
            phase = .sessionComplete
            persist()
            return
        }

        currentAsset = asset
        nextAsset = activeSession.nextAssetIdentifier.flatMap { photoLibrary.asset(identifier: $0) }
        phase = .reviewing
    }

    private func persist() {
        persistenceRevision += 1
        let snapshot = state
        let revision = persistenceRevision

        Task { [stateStore] in
            await stateStore.save(snapshot, revision: revision)
        }
    }
}
