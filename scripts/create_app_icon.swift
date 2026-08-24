import AppKit

guard CommandLine.arguments.count == 3 else { exit(2) }
let logoURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard var svg = try? String(contentsOf: logoURL, encoding: .utf8) else { exit(3) }
svg = svg.replacingOccurrences(
    of: "<rect width=\"256\" height=\"256\" fill=\"white\"/>",
    with: ""
)
guard let logoData = svg.data(using: .utf8), let logo = NSImage(data: logoData) else { exit(4) }

let pixels = 1024
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixels,
    pixelsHigh: pixels,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else { exit(5) }
bitmap.size = NSSize(width: pixels, height: pixels)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: pixels, height: pixels).fill()

let tileRect = NSRect(x: 74, y: 74, width: 876, height: 876)
let tile = NSBezierPath(roundedRect: tileRect, xRadius: 205, yRadius: 205)
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
shadow.shadowBlurRadius = 34
shadow.shadowOffset = NSSize(width: 0, height: -18)
shadow.set()
NSColor(calibratedRed: 0.975, green: 0.958, blue: 0.918, alpha: 1).setFill()
tile.fill()

NSGraphicsContext.current?.saveGraphicsState()
NSShadow().set()
let logoRect = NSRect(x: 155, y: 151, width: 714, height: 714)
logo.draw(in: logoRect, from: .zero, operation: .sourceOver, fraction: 1)
NSGraphicsContext.current?.restoreGraphicsState()

let rim = NSBezierPath(roundedRect: tileRect.insetBy(dx: 1.5, dy: 1.5), xRadius: 204, yRadius: 204)
rim.lineWidth = 3
NSColor.black.withAlphaComponent(0.08).setStroke()
rim.stroke()
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else { exit(6) }
try png.write(to: outputURL)
