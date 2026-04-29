import AppKit
import Foundation

enum ImageUtilities {

    static func resizeImage(_ data: Data, maxDimension: CGFloat = 1024) -> Data? {
        guard let nsImage = NSImage(data: data),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        guard width > 0, height > 0 else { return nil }

        // If already within bounds, return as PNG
        if width <= maxDimension && height <= maxDimension {
            return pngData(from: cgImage, width: Int(width), height: Int(height))
        }

        // Calculate scale factor
        let scale = min(maxDimension / width, maxDimension / height)
        let newWidth = Int(width * scale)
        let newHeight = Int(height * scale)

        // Use CGContext for thread-safe resizing
        guard let colorSpace = cgImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: newWidth,
                  height: newHeight,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        guard let resizedCGImage = context.makeImage() else { return nil }
        return pngData(from: resizedCGImage, width: newWidth, height: newHeight)
    }

    static func loadImage(from url: URL) -> Data? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return resizeImage(data)
    }

    static func imageFromPasteboard() -> Data? {
        guard let nsImage = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage,
              let data = nsImage.tiffRepresentation else {
            return nil
        }
        return resizeImage(data)
    }

    private static func pngData(from cgImage: CGImage, width: Int, height: Int) -> Data? {
        let rep = NSBitmapImageRep(cgImage: cgImage)
        rep.size = NSSize(width: width, height: height)
        return rep.representation(using: .png, properties: [:])
    }
}
