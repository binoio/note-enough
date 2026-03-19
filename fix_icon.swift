import Foundation
import AppKit

let size = NSSize(width: 1024, height: 1024)
let rect = NSRect(origin: .zero, size: size)

// Force 1.0 scale factor for the bitmap
guard let bitmap = NSBitmapImageRep(
    pixelWidth: 1024,
    pixelHeight: 1024,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .sRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    print("Failed to create bitmap")
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

// Colors
let backgroundColor = NSColor(red: 0.95, green: 0.95, blue: 0.92, alpha: 1.0)
let notepadColor = NSColor.white
let notepadLineColor = NSColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
let pencilColor = NSColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 1.0)
let eraserColor = NSColor(red: 1.0, green: 0.6, blue: 0.6, alpha: 1.0)
let graphiteColor = NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)

// 1. Background
backgroundColor.set()
rect.fill()

// 2. Notepad
let notepadRect = NSRect(x: 128, y: 128, width: 768, height: 768)
let notepadPath = NSBezierPath(roundedRect: notepadRect, xRadius: 40, yRadius: 40)
notepadColor.set()
notepadPath.fill()
NSColor.lightGray.set()
notepadPath.lineWidth = 4
notepadPath.stroke()

// Draw notepad lines
notepadLineColor.set()
for i in 1...10 {
    let y = 128 + CGFloat(i) * 70
    let linePath = NSBezierPath()
    linePath.move(to: CGPoint(x: 128 + 40, y: y))
    linePath.line(to: CGPoint(x: 128 + 728, y: y))
    linePath.lineWidth = 2
    linePath.stroke()
}

// 3. Broken Pencil
let pencilWidth: CGFloat = 80
let partLength: CGFloat = 350
let context = NSGraphicsContext.current?.cgContext

// Lower part
context?.saveGState()
context?.translateBy(x: 512, y: 512)
context?.rotate(by: -CGFloat.pi / 4)
let lowerPartRect = NSRect(x: -250, y: -pencilWidth/2, width: partLength, height: pencilWidth)
pencilColor.set()
lowerPartRect.fill()
let eraserRect = NSRect(x: -250, y: -pencilWidth/2, width: 60, height: pencilWidth)
eraserColor.set()
eraserRect.fill()

let breakPathLower = NSBezierPath()
breakPathLower.move(to: CGPoint(x: 100, y: -pencilWidth/2))
breakPathLower.line(to: CGPoint(x: 120, y: -pencilWidth/4))
breakPathLower.line(to: CGPoint(x: 90, y: 0))
breakPathLower.line(to: CGPoint(x: 120, y: pencilWidth/4))
breakPathLower.line(to: CGPoint(x: 100, y: pencilWidth/2))
backgroundColor.set()
breakPathLower.fill()
context?.restoreGState()

// Upper part
context?.saveGState()
context?.translateBy(x: 600, y: 650)
context?.rotate(by: CGFloat.pi / 6)
pencilColor.set()
NSRect(x: 0, y: -pencilWidth/2, width: partLength, height: pencilWidth).fill()

let tipPath = NSBezierPath()
tipPath.move(to: CGPoint(x: partLength, y: -pencilWidth/2))
tipPath.line(to: CGPoint(x: partLength + 100, y: 0))
tipPath.line(to: CGPoint(x: partLength, y: pencilWidth/2))
NSColor(red: 0.95, green: 0.85, blue: 0.7, alpha: 1.0).set()
tipPath.fill()

let leadPath = NSBezierPath()
leadPath.move(to: CGPoint(x: partLength + 60, y: -20))
leadPath.line(to: CGPoint(x: partLength + 100, y: 0))
leadPath.line(to: CGPoint(x: partLength + 60, y: 20))
graphiteColor.set()
leadPath.fill()

let breakPathUpper = NSBezierPath()
breakPathUpper.move(to: CGPoint(x: 0, y: -pencilWidth/2))
breakPathUpper.line(to: CGPoint(x: 20, y: -pencilWidth/4))
breakPathUpper.line(to: CGPoint(x: -10, y: 0))
breakPathUpper.line(to: CGPoint(x: 20, y: pencilWidth/4))
breakPathUpper.line(to: CGPoint(x: 0, y: pencilWidth/2))
backgroundColor.set()
breakPathUpper.fill()
context?.restoreGState()

NSGraphicsContext.restoreGraphicsState()

if let pngData = bitmap.representation(using: .png, properties: [:]) {
    try? pngData.write(to: URL(fileURLWithPath: "NoteEnough/Assets.xcassets/AppIcon.appiconset/AppIcon.png"))
    print("Fixed icon generated (1024x1024)!")
}
