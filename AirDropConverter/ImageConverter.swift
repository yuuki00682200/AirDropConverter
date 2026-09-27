import Foundation
import ImageIO
import UniformTypeIdentifiers

enum OutputFormat: String, CaseIterable, Sendable {
    case png = "PNG"
    case jpeg = "JPEG"
    case webp = "WebP"

    var utType: UTType {
        switch self {
        case .png: .png
        case .jpeg: .jpeg
        case .webp: .webP
        }
    }

    var fileExtension: String {
        switch self {
        case .png: "png"
        case .jpeg: "jpg"
        case .webp: "webp"
        }
    }

    static var supported: [Self] {
        let types = CGImageDestinationCopyTypeIdentifiers() as! [String]
        return allCases.filter { types.contains($0.utType.identifier) }
    }
}

enum ImageConverter {
    /// Publishes a complete file without overwriting an existing output.
    static func convert(source: URL, format: OutputFormat) throws -> URL {
        let originalStamp = try FileStamp.read(source)
        guard OutputFormat.supported.contains(format) else {
            throw failure("This output format is not supported by this Mac.")
        }
        guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil),
              CGImageSourceGetStatus(imageSource) == .statusComplete,
              let original = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw failure("The image is incomplete or could not be read.")
        }
        // Bake EXIF orientation into pixels so every PNG/JPEG viewer displays it correctly.
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(original.width, original.height)
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            throw failure("The image is incomplete or could not be read.")
        }
        let directory = source.deletingLastPathComponent()
        let temporary = directory.appendingPathComponent(".AirDropConverter-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: temporary) }
        guard let destination = CGImageDestinationCreateWithURL(
            temporary as CFURL, format.utType.identifier as CFString, 1, nil
        ) else { throw failure("Could not create the converted image.") }

        var metadata = (CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]) ?? [:]
        metadata[kCGImagePropertyOrientation] = 1
        metadata[kCGImagePropertyPixelWidth] = image.width
        metadata[kCGImagePropertyPixelHeight] = image.height
        if var tiff = metadata[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
            tiff[kCGImagePropertyTIFFOrientation] = 1
            metadata[kCGImagePropertyTIFFDictionary] = tiff
        }
        if format != .png { metadata[kCGImageDestinationLossyCompressionQuality] = 0.9 }
        CGImageDestinationAddImage(destination, image, metadata as CFDictionary)
        guard CGImageDestinationFinalize(destination),
              let check = CGImageSourceCreateWithURL(temporary as CFURL, nil),
              CGImageSourceCreateImageAtIndex(check, 0, nil) != nil else {
            throw failure("Could not finish writing the converted image.")
        }
        guard try FileStamp.read(source) == originalStamp else {
            throw failure("The original changed during conversion and was kept.")
        }
        let base = source.deletingPathExtension().lastPathComponent
        for index in 1...10000 {
            let suffix = index == 1 ? "" : " \(index)"
            let output = directory.appendingPathComponent("\(base)\(suffix).\(format.fileExtension)")
            // link() atomically refuses existing destinations, including concurrent writers.
            if link(temporary.path, output.path) == 0 { return output }
            if errno != EEXIST { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
        }
        throw failure("Too many files have the same name.")
    }

    private static func failure(_ message: String) -> NSError {
        NSError(domain: "AirDropConverter", code: 1,
                userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(message, comment: "")])
    }
}
