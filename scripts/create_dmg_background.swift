import AppKit

guard CommandLine.arguments.count == 2 else { exit(2) }
let output = URL(fileURLWithPath: CommandLine.arguments[1])
let size = NSSize(width: 720, height: 440)
let image = NSImage(size: size)

image.lockFocus()
let rect = NSRect(origin: .zero, size: size)
NSColor(calibratedRed: 0.095, green: 0.102, blue: 0.094, alpha: 1).setFill()
rect.fill()

let glow = NSGradient(colors: [
    NSColor(calibratedRed: 0.78, green: 0.57, blue: 0.34, alpha: 0.18),
    NSColor(calibratedRed: 0.78, green: 0.57, blue: 0.34, alpha: 0)
])!
glow.draw(in: NSBezierPath(ovalIn: NSRect(x: 85, y: 105, width: 550, height: 420)), angle: 0)

let titleStyle: [NSAttributedString.Key: Any] = [
    .font: NSFont(name: "NewYork-Semibold", size: 42) ?? NSFont.systemFont(ofSize: 42, weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.95, alpha: 1),
    .kern: -1.2
]
NSAttributedString(string: "MDore", attributes: titleStyle).draw(at: NSPoint(x: 46, y: 355))

let subtitleStyle: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14, weight: .medium),
    .foregroundColor: NSColor(calibratedWhite: 0.72, alpha: 1)
]
NSAttributedString(string: "Drag MDore to Applications", attributes: subtitleStyle).draw(at: NSPoint(x: 48, y: 329))

let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 275, y: 215))
arrow.curve(to: NSPoint(x: 445, y: 215), controlPoint1: NSPoint(x: 325, y: 242), controlPoint2: NSPoint(x: 395, y: 242))
arrow.move(to: NSPoint(x: 445, y: 215))
arrow.line(to: NSPoint(x: 425, y: 230))
arrow.move(to: NSPoint(x: 445, y: 215))
arrow.line(to: NSPoint(x: 425, y: 200))
arrow.lineWidth = 2
arrow.lineCapStyle = .round
NSColor(calibratedRed: 0.82, green: 0.63, blue: 0.42, alpha: 0.86).setStroke()
arrow.stroke()

let noteStyle: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 11.5),
    .foregroundColor: NSColor(calibratedWhite: 0.55, alpha: 1)
]
NSAttributedString(string: "Installation help is included below", attributes: noteStyle).draw(at: NSPoint(x: 256, y: 48))
image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: output)
