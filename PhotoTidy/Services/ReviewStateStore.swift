import Foundation

actor ReviewStateStore {
    private let fileURL: URL
    private var latestRevision = 0

    init(fileManager: FileManager = .default) {
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory

        fileURL = applicationSupport
            .appendingPathComponent("PhotoTidy", isDirectory: true)
            .appendingPathComponent("review-state.json", isDirectory: false)
    }

    func load() -> PersistedReviewState {
        guard let data = try? Data(contentsOf: fileURL) else {
            return .empty
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(PersistedReviewState.self, from: data)
        } catch {
            return .empty
        }
    }

    func save(_ state: PersistedReviewState, revision: Int) {
        guard revision >= latestRevision else { return }
        latestRevision = revision

        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(state)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // The app remains usable if a transient disk error prevents persistence.
        }
    }
}
