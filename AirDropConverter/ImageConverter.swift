//
//  ImageConverter.swift
//  AirDropConverter
//
//  Created by Yuki Takatsu on 2026/04/01.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

enum OutputFormat: String, CaseIterable {
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
}

enum ImageConverter {
    static func convert(source: URL, destination: URL, format: OutputFormat) -> Bool {
        guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return false
        }

        guard let imageDest = CGImageDestinationCreateWithURL(
            destination as CFURL,
            format.utType.identifier as CFString,
            1,
            nil
        ) else {
            return false
        }

        var properties: CFDictionary?
        let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)

        switch format {
        case .png:
            properties = metadata
        case .jpeg, .webp:
            var opts: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.9]
            if let metadata = metadata as? [CFString: Any] {
                opts.merge(metadata) { current, _ in current }
            }
            properties = opts as CFDictionary
        }

        CGImageDestinationAddImage(imageDest, cgImage, properties)
        return CGImageDestinationFinalize(imageDest)
    }
}
