import Photos
import SwiftUI
import UIKit

struct PhotoAssetView: View {
    let asset: PHAsset
    var contentMode: ContentMode = .fit

    @State private var image: UIImage?
    @State private var failedToLoad = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.secondary.opacity(0.12)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if failedToLoad {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView()
                }
            }
            .task(id: asset.localIdentifier) {
                image = nil
                failedToLoad = false

                let scale = UIScreen.main.scale
                let requestedSize = CGSize(
                    width: max(proxy.size.width * scale, 200),
                    height: max(proxy.size.height * scale, 200)
                )
                let loadedImage = await PhotoLibraryService.shared.image(
                    for: asset,
                    targetSize: requestedSize
                )

                guard !Task.isCancelled else { return }
                image = loadedImage
                failedToLoad = loadedImage == nil
            }
        }
    }
}
