import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else { exit(1) }
let output = URL(fileURLWithPath: CommandLine.arguments[1])
let size = NSSize(width: 1024, height: 1024)
guard
  let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0)
else { exit(1) }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
let background = NSBezierPath(
  roundedRect: NSRect(origin: .zero, size: size), xRadius: 220, yRadius: 220)
NSColor(calibratedRed: 0.18, green: 0.31, blue: 0.58, alpha: 1).setFill()
background.fill()

let route = NSBezierPath()
route.lineWidth = 72
route.lineCapStyle = .round
route.lineJoinStyle = .round
route.move(to: NSPoint(x: 300, y: 720))
route.line(to: NSPoint(x: 500, y: 512))
route.line(to: NSPoint(x: 724, y: 512))
route.move(to: NSPoint(x: 500, y: 512))
route.line(to: NSPoint(x: 300, y: 304))
NSColor.white.setStroke()
route.stroke()

for point in [NSPoint(x: 300, y: 720), NSPoint(x: 724, y: 512), NSPoint(x: 300, y: 304)] {
  let circle = NSBezierPath(
    ovalIn: NSRect(x: point.x - 66, y: point.y - 66, width: 132, height: 132))
  NSColor.white.setFill()
  circle.fill()
}
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: output)
