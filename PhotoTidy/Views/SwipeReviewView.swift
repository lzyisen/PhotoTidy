import Photos
import SwiftUI

struct SwipeReviewView: View {
    @EnvironmentObject private var session: ReviewSession
    @State private var dragOffset: CGSize = .zero
    @State private var isResolvingSwipe = false

    private let swipeThreshold: CGFloat = 110

    var body: some View {
        VStack(spacing: 16) {
            header

            GeometryReader { proxy in
                ZStack {
                    if let nextAsset = session.nextAsset {
                        PhotoCard(asset: nextAsset)
                            .scaleEffect(0.96)
                            .offset(y: 12)
                            .opacity(0.65)
                    }

                    if let currentAsset = session.currentAsset {
                        PhotoCard(asset: currentAsset)
                            .overlay(alignment: .topLeading) {
                                decisionLabel("DELETE", color: .red, opacity: deleteOpacity)
                                    .padding(24)
                            }
                            .overlay(alignment: .topTrailing) {
                                decisionLabel("KEEP", color: .green, opacity: keepOpacity)
                                    .padding(24)
                            }
                            .offset(dragOffset)
                            .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                            .gesture(dragGesture)
                            .accessibilityLabel("Current photo")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)

            controls
        }
        .padding(.horizontal)
        .padding(.bottom)
        .navigationTitle(session.sessionLabel)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("\(session.sessionReviewedCount) / \(session.sessionTargetCount)")
                .font(.headline.monospacedDigit())

            HStack(spacing: 16) {
                Label("\(session.sessionKeptCount) kept", systemImage: "heart.fill")
                    .foregroundStyle(.green)
                Label("\(session.sessionDeletionCount) queued", systemImage: "trash.fill")
                    .foregroundStyle(.red)
            }
            .font(.subheadline)

            if session.isLimitedAccess {
                Label("Limited Photos access", systemImage: "lock")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.top, 4)
    }

    private var controls: some View {
        HStack(spacing: 18) {
            Button {
                session.undo()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
                    .frame(minWidth: 78)
            }
            .buttonStyle(.bordered)
            .disabled(!session.canUndo || isResolvingSwipe)

            Button {
                submit(.delete)
            } label: {
                Image(systemName: "xmark")
                    .font(.title2.bold())
                    .frame(width: 58, height: 58)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .accessibilityLabel("Queue for deletion")
            .disabled(isResolvingSwipe)

            Button {
                submit(.keep)
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title2.bold())
                    .frame(width: 58, height: 58)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .accessibilityLabel("Keep photo")
            .disabled(isResolvingSwipe)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isResolvingSwipe else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard !isResolvingSwipe else { return }

                if value.translation.width > swipeThreshold {
                    submit(.keep, flingDirection: 1)
                } else if value.translation.width < -swipeThreshold {
                    submit(.delete, flingDirection: -1)
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    private var keepOpacity: Double {
        min(max(Double(dragOffset.width / swipeThreshold), 0), 1)
    }

    private var deleteOpacity: Double {
        min(max(Double(-dragOffset.width / swipeThreshold), 0), 1)
    }

    private func decisionLabel(_ text: String, color: Color, opacity: Double) -> some View {
        Text(text)
            .font(.headline.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 3)
            }
            .opacity(opacity)
    }

    private func submit(_ decision: SwipeDecision, flingDirection: CGFloat? = nil) {
        guard !isResolvingSwipe else { return }
        isResolvingSwipe = true

        if let flingDirection {
            withAnimation(.easeOut(duration: 0.18)) {
                dragOffset = CGSize(width: flingDirection * 650, height: dragOffset.height)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            session.decide(decision)
            dragOffset = .zero
            isResolvingSwipe = false
        }
    }
}

private struct PhotoCard: View {
    let asset: PHAsset

    var body: some View {
        VStack(spacing: 0) {
            PhotoAssetView(asset: asset)
                .clipShape(RoundedRectangle(cornerRadius: 24))

            if let date = asset.creationDate {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.16), radius: 14, y: 7)
    }
}
