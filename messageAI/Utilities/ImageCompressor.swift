import UIKit

enum ImageCompressor {
    static func prepareImageData(_ data: Data,
                                 maxDimension: CGFloat = 1920,
                                 maxBytes: Int = 1_000_000,
                                 initialQuality: CGFloat = 0.85) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        let targetSize = scaledSize(for: image.size, maxDimension: maxDimension)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let renderedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        var quality = initialQuality
        var compressed = renderedImage.jpegData(compressionQuality: quality)

        while let size = compressed?.count,
              size > maxBytes,
              quality > 0.25 {
            quality -= 0.1
            compressed = renderedImage.jpegData(compressionQuality: quality)
        }

        return compressed ?? renderedImage.jpegData(compressionQuality: 0.25)
    }

    private static func scaledSize(for originalSize: CGSize, maxDimension: CGFloat) -> CGSize {
        guard max(originalSize.width, originalSize.height) > maxDimension else {
            return originalSize
        }
        let aspect = originalSize.width / originalSize.height
        if aspect > 1 {
            return CGSize(width: maxDimension, height: maxDimension / aspect)
        } else {
            return CGSize(width: maxDimension * aspect, height: maxDimension)
        }
    }
}
