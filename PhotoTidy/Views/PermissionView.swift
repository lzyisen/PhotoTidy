import SwiftUI

struct PermissionView: View {
    @EnvironmentObject private var session: ReviewSession

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.stack")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            VStack(spacing: 10) {
                Text("Tidy your photos, 50 at a time")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("Swipe right to keep a photo and left to queue it for deletion. Nothing is deleted until you review the queue and approve Apple’s system prompt.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                Label("No account or cloud service", systemImage: "lock")
                Label("Your decisions are stored only on this iPhone", systemImage: "internaldrive")
                Label("You can pause at any point and continue later", systemImage: "pause.circle")
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))

            Button {
                Task { await session.requestPhotoAccess() }
            } label: {
                Text("Allow Photos Access")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button("Open Settings") {
                session.openSystemSettings()
            }
            .buttonStyle(.bordered)

            Text("For the full experience, allow access to all photos. Limited access still works for the photos you choose to share.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
    }
}
