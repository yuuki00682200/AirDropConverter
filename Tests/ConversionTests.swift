import Foundation
import ImageIO
import UniformTypeIdentifiers

@main
struct ConversionTests {
    static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let context = CGContext(data: nil, width: 32, height: 16, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 32, height: 16))
        let source = directory.appendingPathComponent("photo.heic")
        let encoder = CGImageDestinationCreateWithURL(source as CFURL, UTType.heic.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(encoder, context.makeImage()!, [kCGImagePropertyOrientation: 6] as CFDictionary)
        precondition(CGImageDestinationFinalize(encoder))

        for format in OutputFormat.supported {
            let first = try ImageConverter.convert(source: source, format: format)
            let bytes = try Data(contentsOf: first)
            let second = try ImageConverter.convert(source: source, format: format)
            precondition(first != second)
            let preserved = try Data(contentsOf: first)
            precondition(preserved == bytes, "Existing output must not change")
            let decoded = CGImageSourceCreateWithURL(first as CFURL, nil)!
            precondition(CGImageSourceGetType(decoded) as String? == format.utType.identifier)
            let image = CGImageSourceCreateImageAtIndex(decoded, 0, nil)!
            precondition(image.width == 16 && image.height == 32, "Orientation must be baked into pixels")
            precondition(FileManager.default.fileExists(atPath: source.path))
        }
        let corrupt = directory.appendingPathComponent("broken.heic")
        try Data("not an image".utf8).write(to: corrupt)
        do {
            _ = try ImageConverter.convert(source: corrupt, format: .png)
            fatalError("Corrupt input should fail")
        } catch {}
        precondition(!FileManager.default.fileExists(atPath: directory.appendingPathComponent("broken.png").path))
        let remaining = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        precondition(remaining.allSatisfy { !$0.hasPrefix(".AirDropConverter-") })
        if !OutputFormat.supported.contains(.webp) {
            do {
                _ = try ImageConverter.convert(source: source, format: .webp)
                fatalError("Unsupported output should fail")
            } catch {}
        }
        precondition(!AirDropMetadata.isAirDropFile(at: source))
        for (attribute, expected) in [
            ("0081;1234;sharingd;UUID", true),
            ("0081;;sharingd;", true),
            ("0081;1234;Safari;UUID", false),
            ("sharingd", false),
            ("0081;sharingd;;UUID", false)
        ] {
            let result = attribute.withCString {
                setxattr(source.path, "com.apple.quarantine", $0, attribute.utf8.count, 0, 0)
            }
            precondition(result == 0)
            precondition(AirDropMetadata.isAirDropFile(at: source) == expected)
        }
        print("PASS: AirDrop quarantine classification")
        let url = directory.appendingPathComponent("arrival.heic")
        let stamp = FileStamp(size: 10, modified: Date(timeIntervalSince1970: 1), identifier: "a")
        let changed = FileStamp(size: 20, modified: Date(timeIntervalSince1970: 2), identifier: "a")
        var tracker = FileArrivalTracker()
        tracker.reset(to: [source: stamp])
        precondition(tracker.update([source: stamp]).isEmpty, "Startup files must not trigger")
        precondition(tracker.update([source: stamp, url: stamp]).isEmpty)
        precondition(tracker.update([source: stamp, url: stamp]).isEmpty)
        precondition(tracker.update([source: stamp, url: changed]).isEmpty, "Growing files must wait")
        precondition(tracker.update([source: stamp, url: changed]).isEmpty)
        precondition(tracker.update([source: stamp, url: changed]) == [url])
        precondition(tracker.update([source: stamp, url: changed]) == [url], "Busy UI must not lose arrivals")
        tracker.handled(url)
        precondition(tracker.update([source: stamp, url: changed]).isEmpty, "Skip must not prompt again")
        _ = tracker.update([source: stamp])
        _ = tracker.update([source: stamp, url: changed])
        _ = tracker.update([source: stamp, url: changed])
        precondition(tracker.update([source: stamp, url: changed]) == [url], "Reused names must trigger")
        print("PASS: arrival stability, startup baseline, busy UI retention, skip, reused filename")
        print("PASS: format, orientation, collision, original preservation, corrupt input, cleanup, unsupported format")
    }
}
