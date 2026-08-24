import AppKit

guard CommandLine.arguments.count == 3 else { exit(2) }
let output = URL(fileURLWithPath: CommandLine.arguments[1])
let textureURL = URL(fileURLWithPath: CommandLine.arguments[2])
let size = NSSize(width: 720, height: 440)
let image = NSImage(size: size)

image.lockFocus()
let rect = NSRect(origin: .zero, size: size)
guard let texture = NSImage(contentsOf: textureURL) else { exit(3) }
texture.draw(in: rect, from: .zero, operation: .copy, fraction: 1)

let topShade = NSGradient(colors: [
    NSColor(calibratedWhite: 0.02, alpha: 0.48),
    NSColor(calibratedWhite: 0.02, alpha: 0)
])!
topShade.draw(in: NSRect(x: 0, y: 330, width: 720, height: 110), angle: -90)

let titleStyle: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 39, weight: .bold),
    .foregroundColor: NSColor(calibratedWhite: 0.95, alpha: 1),
    .kern: -1.5
]
NSAttributedString(string: "MDore", attributes: titleStyle).draw(at: NSPoint(x: 44, y: 362))

let subtitleStyle: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 13.5, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.78, alpha: 1)
]
NSAttributedString(string: "Drag MDore to Applications", attributes: subtitleStyle).draw(at: NSPoint(x: 46, y: 338))

let noteStyle: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 10.5, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.76, alpha: 1),
    .kern: 0.35
]
let note = NSAttributedString(string: "INSTALLATION GUIDE  ·  RU / EN / ES", attributes: noteStyle)
let noteSize = note.size()
note.draw(at: NSPoint(x: (720 - noteSize.width) / 2, y: 182))
image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: output)
