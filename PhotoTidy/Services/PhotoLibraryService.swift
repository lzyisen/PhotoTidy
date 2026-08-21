import Foundation
import Photos
import UIKit

final class PhotoLibraryService {
    static let shared = PhotoLibraryService()

    private let imageManager = PHCachingImageManager()

    private init() {}

    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
    }

    func imageAssetIdentifiers(excluding reviewedIdentifiers: Set<String>) -> [String] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let assets = PHAsset.fetchAssets(with: .image, options: options)
        var identifiers: [String] = []
        identifiers.reserveCapacity(assets.count)

        assets.enumerateObjects { asset, _, _ in
            guard !reviewedIdentifiers.contains(asset.localIdentifier) else { return }
            identifiers.append(asset.localIdentifier)
        }

        return identifiers
    }

    func asset(identifier: String) -> PHAsset? {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        return assets.firstObject
    }

    func assets(identifiers: [String]) -> [PHAsset] {
        guard !identifiers.isEmpty else { return [] }

        let result = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var assetsByIdentifier: [String: PHAsset] = [:]
        result.enumerateObjects { asset, _, _ in
            assetsByIdentifier[asset.localIdentifier] = asset
        }

        return identifiers.compactMap { assetsByIdentifier[$0] }
    }

    func image(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let lock = NSLock()
            var isFinished = false

            func finish(with image: UIImage?) {
                lock.lock()
                defer { lock.unlock() }

                guard !isFinished else { return }
                isFinished = true
                continuation.resume(returning: image)
            }

            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                if (info?[PHImageCancelledKey] as? Bool) == true {
                    finish(with: nil)
                    return
                }

                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    finish(with: image)
                }
            }
        }
    }

    func delete(_ assets: [PHAsset]) async throws {
        guard !assets.isEmpty else { return }

        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            } completionHandler: { success, error in
                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(
                        throwing: error ?? PhotoLibraryError.deletionWasNotCompleted
                    )
                }
            }
        }
    }
}

enum PhotoLibraryError: LocalizedError {
    case deletionWasNotCompleted

    var errorDescription: String? {
        switch self {
        case .deletionWasNotCompleted:
            return "The photos were not deleted. Your deletion queue is still intact."
        }
    }
}
