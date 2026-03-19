import Foundation
import AppKit

let size = NSSize(width: 1024, height: 1024)
let rect = NSRect(origin: .zero, size: size)

guard let bitmap = NSBitmapImageRep(
    pixelsWide: 1024,
    pixelsHigh: 1024,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .sRGB,
    bitmapFormat: [],
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
let pencilColor = NSColor(red: 1.0, green: 0.75, blue: 0.1, alpha: 1.0) // Slightly more vibrant
let eraserColor = NSColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0)
let graphiteColor = NSColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
let woodColor = NSColor(red: 0.95, green: 0.85, blue: 0.7, alpha: 1.0)

// 1. Background
backgroundColor.set()
rect.fill()

// 2. Notepad
let notepadRect = NSRect(x: 128, y: 128, width: 768, height: 768)
let notepadPath = NSBezierPath(roundedRect: notepadRect, xRadius: 40, yRadius: 40)
notepadColor.set()
notepadPath.fill()
NSColor.lightGray.withAlphaComponent(0.5).set()
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

// 3. Broken Pencil (BIGGER)
let pencilWidth: CGFloat = 110  // Increased from 80
let partLength: CGFloat = 420  // Increased from 350
let context = NSGraphicsContext.current?.cgContext

// Lower part (Eraser side)
context?.saveGState()
context?.translateBy(x: 480, y: 480) // Adjusted center
context?.rotate(by: -CGFloat.pi / 4)
let lowerPartRect = NSRect(x: -300, y: -pencilWidth/2, width: partLength, height: pencilWidth)
pencilColor.set()
lowerPartRect.fill()

// Eraser
let eraserRect = NSRect(x: -300, y: -pencilWidth/2, width: 80, height: pencilWidth)
eraserColor.set()
eraserRect.fill()

// Jagged break line
let breakPathLower = NSBezierPath()
let breakX = -300 + partLength
breakPathLower.move(to: CGPoint(x: breakX, y: -pencilWidth/2))
breakPathLower.line(to: CGPoint(x: breakX + 30, y: -pencilWidth/4))
breakPathLower.line(to: CGPoint(x: breakX - 10, y: 0))
breakPathLower.line(to: CGPoint(x: breakX + 30, y: pencilWidth/4))
breakPathLower.line(to: CGPoint(x: breakX, y: pencilWidth/2))
backgroundColor.set()
breakPathLower.fill()
context?.restoreGState()

// Upper part (Pointy side)
context?.saveGState()
context?.translateBy(x: 580, y: 620) // Adjusted overlap
context?.rotate(by: CGFloat.pi / 6)
pencilColor.set()
NSRect(x: 0, y: -pencilWidth/2, width: partLength, height: pencilWidth).fill()

// Pencil tip (wood)
let tipPath = NSBezierPath()
tipPath.move(to: CGPoint(x: partLength, y: -pencilWidth/2))
tipPath.line(to: CGPoint(x: partLength + 130, y: 0))
tipPath.line(to: CGPoint(x: partLength, y: pencilWidth/2))
woodColor.set()
tipPath.fill()

// Pencil lead
let leadPath = NSBezierPath()
leadPath.move(to: CGPoint(x: partLength + 80, y: -25))
leadPath.line(to: CGPoint(x: partLength + 130, y: 0))
leadPath.line(to: CGPoint(x: partLength + 80, y: 25))
graphiteColor.set()
leadPath.fill()

// Jagged break line for upper part
let breakPathUpper = NSBezierPath()
breakPathUpper.move(to: CGPoint(x: 0, y: -pencilWidth/2))
breakPathUpper.line(to: CGPoint(x: 30, y: -pencilWidth/4))
breakPathUpper.line(to: CGPoint(x: -10, y: 0))
breakPathUpper.line(to: CGPoint(x: 30, y: pencilWidth/4))
breakPathUpper.line(to: CGPoint(x: 0, y: pencilWidth/2))
backgroundColor.set()
breakPathUpper.fill()
context?.restoreGState()

NSGraphicsContext.restoreGraphicsState()

if let pngData = bitmap.representation(using: .png, properties: [:]) {
    try? pngData.write(to: URL(fileURLWithPath: "NoteEnough/Assets.xcassets/AppIcon.appiconset/AppIcon.png"))
    print("New bold icon generated (1024x1024)!")
}
