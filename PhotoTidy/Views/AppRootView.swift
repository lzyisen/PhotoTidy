import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var session: ReviewSession

    var body: some View {
        NavigationStack {
            Group {
                switch session.phase {
                case .loading:
                    ProgressView("Loading your photo session…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .permissionRequired:
                    PermissionView()
                case .reviewing:
                    SwipeReviewView()
                case .sessionComplete:
                    SessionCompleteView()
                case .noPhotosRemaining:
                    NoPhotosRemainingView()
                }
            }
            .toolbar {
                if session.phase == .reviewing || session.phase == .sessionComplete {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            session.showDeletionQueue()
                        } label: {
                            Label(
                                "Deletion queue: \(session.pendingDeletionCount)",
                                systemImage: "trash"
                            )
                        }
                        .accessibilityLabel("Open deletion queue with \(session.pendingDeletionCount) photos")
                    }
                }
            }
        }
        .task {
            await session.bootstrap()
        }
        .sheet(isPresented: $session.isDeletionQueuePresented) {
            DeleteQueueView()
                .environmentObject(session)
        }
        .alert(
            "Photo Tidy",
            isPresented: Binding(
                get: { session.errorMessage != nil },
                set: { isPresented in
                    if !isPresented { session.errorMessage = nil }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                session.errorMessage = nil
            }
        } message: {
            Text(session.errorMessage ?? "")
        }
    }
}

private struct SessionCompleteView: View {
    @EnvironmentObject private var session: ReviewSession

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 68))
                .foregroundStyle(.green)

            Text("Session complete")
                .font(.largeTitle.bold())

            Text("You reviewed \(session.sessionReviewedCount) photos.")
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                SummaryValue(title: "Kept", value: session.sessionKeptCount, tint: .green)
                SummaryValue(title: "Queued", value: session.sessionDeletionCount, tint: .red)
            }

            if session.pendingDeletionCount > 0 {
                Button {
                    session.showDeletionQueue()
                } label: {
                    Label(
                        "Review \(session.pendingDeletionCount) queued photos",
                        systemImage: "rectangle.grid.2x2"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            Button {
                Task { await session.startNextSession() }
            } label: {
                Label("Start another 50", systemImage: "shuffle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Text("You can stop here. Your progress and deletion queue are already saved.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .navigationTitle(session.sessionLabel)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NoPhotosRemainingView: View {
    @EnvironmentObject private var session: ReviewSession

    var body: some View {
        ContentUnavailableView {
            Label("All caught up", systemImage: "sparkles")
        } description: {
            Text("There are no unreviewed photos available in your current Photos permission scope.")
        } actions: {
            if session.pendingDeletionCount > 0 {
                Button("Review deletion queue") {
                    session.showDeletionQueue()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

private struct SummaryValue: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.bold())
                .foregroundStyle(tint)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }
}
