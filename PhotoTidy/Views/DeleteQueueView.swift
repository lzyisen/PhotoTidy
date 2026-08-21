import Photos
import SwiftUI

struct DeleteQueueView: View {
    @EnvironmentObject private var session: ReviewSession
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 3)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if session.queuedAssets.isEmpty {
                    ContentUnavailableView {
                        Label("Deletion queue is empty", systemImage: "trash.slash")
                    } description: {
                        Text("Photos you queue with a left swipe will appear here for a final review.")
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 3) {
                            ForEach(session.queuedAssets, id: \.localIdentifier) { asset in
                                QueueThumbnail(asset: asset) {
                                    session.keepQueuedAsset(identifier: asset.localIdentifier)
                                }
                            }
                        }
                        .padding(3)
                    }
                }
            }
            .navigationTitle("Delete \(session.queuedAssets.count) Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !session.queuedAssets.isEmpty {
                    VStack(spacing: 8) {
                        Button(role: .destructive) {
                            Task { await session.deleteQueuedAssets() }
                        } label: {
                            if session.isDeleting {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Label(
                                    "Delete \(session.queuedAssets.count) Photos",
                                    systemImage: "trash"
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(session.isDeleting)

                        Text("Apple will show its own confirmation before anything is deleted.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                }
            }
        }
    }
}

private struct QueueThumbnail: View {
    let asset: PHAsset
    let keep: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PhotoAssetView(asset: asset, contentMode: .fill)
                .frame(height: 118)
                .clipped()

            Button(action: keep) {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.5))
                    .padding(6)
            }
            .accessibilityLabel("Keep this photo instead")
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
