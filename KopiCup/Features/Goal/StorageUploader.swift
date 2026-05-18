import Foundation
import UIKit

enum UploaderError: Error {
    case encodingFailed
}

struct StorageUploader {
    static func uploadGoalImage(_ image: UIImage) async throws -> String {
        var maxSide: CGFloat = 700
        var quality: CGFloat = 0.72

        for _ in 0..<8 {
            if let data = image.normalizedForUpload(maxSide: maxSide).jpegData(compressionQuality: quality),
               data.count <= 850_000 {
                return "data:image/jpeg;base64,\(data.base64EncodedString())"
            }

            if quality > 0.45 {
                quality -= 0.09
            } else {
                maxSide *= 0.82
                quality = 0.72
            }
        }

        throw UploaderError.encodingFailed
    }
}

extension String {
    var goalImage: UIImage? {
        let marker = "base64,"
        guard let markerRange = range(of: marker) else { return nil }

        let base64 = String(self[markerRange.upperBound...])
        guard let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }
}

extension UIImage {
    func normalizedForUpload(maxSide: CGFloat = 700) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxSide else { return fixedOrientation() }

        let scale = maxSide / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            fixedOrientation().draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
