#!/usr/bin/env swift
import Cocoa

let size: CGFloat = 1024

let image = NSImage(size: NSSize(width: size, height: size), flipped: true) { rect in
    guard let context = NSGraphicsContext.current?.cgContext else { return false }

    // Clip to rounded rect (macOS icon shape)
    let bgPath = NSBezierPath(roundedRect: rect, xRadius: 228, yRadius: 228)
    bgPath.addClip()

    // Background gradient (AirDrop blue)
    let gradient = NSGradient(
        colors: [
            NSColor(red: 0.16, green: 0.71, blue: 0.96, alpha: 1.0),  // #29B6F6
            NSColor(red: 0.08, green: 0.40, blue: 0.75, alpha: 1.0),  // #1565C0
        ],
        atLocations: [0.0, 1.0],
        colorSpace: .deviceRGB
    )!
    gradient.draw(from: NSPoint(x: 0, y: 0), to: NSPoint(x: size, y: size), options: [])

    // Subtle inner glow
    let innerGlow = NSBezierPath(roundedRect: rect.insetBy(dx: 4, dy: 4), xRadius: 224, yRadius: 224)
    NSColor(white: 1.0, alpha: 0.08).setStroke()
    innerGlow.lineWidth = 4
    innerGlow.stroke()

    // === Down Arrow (AirDrop symbol) ===

    // Arrow shaft
    let shaftRect = NSRect(x: 452, y: 130, width: 120, height: 300)
    let shaftPath = NSBezierPath(roundedRect: shaftRect, xRadius: 60, yRadius: 60)
    NSColor.white.setFill()
    shaftPath.fill()

    // Arrow head (filled triangle)
    let arrowHead = NSBezierPath()
    arrowHead.move(to: NSPoint(x: 512, y: 660))   // bottom tip
    arrowHead.line(to: NSPoint(x: 280, y: 430))    // top-left
    arrowHead.line(to: NSPoint(x: 744, y: 430))    // top-right
    arrowHead.close()
    NSColor.white.setFill()
    arrowHead.fill()

    // === Photo frame at bottom ===

    let frameRect = NSRect(x: 210, y: 690, width: 604, height: 220)
    let framePath = NSBezierPath(roundedRect: frameRect, xRadius: 36, yRadius: 36)

    // Frame background
    NSColor(white: 1.0, alpha: 0.20).setFill()
    framePath.fill()

    // Frame border
    NSColor(white: 1.0, alpha: 0.35).setStroke()
    framePath.lineWidth = 3
    framePath.stroke()

    // Clip to frame for landscape
    context.saveGState()
    framePath.addClip()

    // Mountain landscape
    let mountain = NSBezierPath()
    mountain.move(to: NSPoint(x: 210, y: 910))    // bottom-left
    mountain.line(to: NSPoint(x: 380, y: 760))     // peak 1
    mountain.line(to: NSPoint(x: 460, y: 810))     // valley
    mountain.line(to: NSPoint(x: 600, y: 710))     // peak 2 (tallest)
    mountain.line(to: NSPoint(x: 814, y: 910))     // bottom-right
    mountain.close()
    NSColor(white: 1.0, alpha: 0.40).setFill()
    mountain.fill()

    // Sun
    let sunRect = NSRect(x: 640, y: 720, width: 56, height: 56)
    let sunPath = NSBezierPath(ovalIn: sunRect)
    NSColor(white: 1.0, alpha: 0.55).setFill()
    sunPath.fill()

    context.restoreGState()

    return true
}

// Save as PNG
guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to create PNG")
    exit(1)
}

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let basePath = outputDir + "/AppIcon_1024.png"
try! pngData.write(to: URL(fileURLWithPath: basePath))
print("Generated: \(basePath)")
