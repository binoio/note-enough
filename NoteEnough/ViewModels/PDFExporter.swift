import UIKit
import PencilKit

enum PDFExporter {
    /// Export pages to a PDF file.
    /// Parameters are decomposed (not model objects) for Swift 6 Sendable safety.
    static func export(
        name: String,
        drawings: [PKDrawing],
        paperType: PaperType,
        paperSize: PaperSize,
        orientation: PageOrientation
    ) throws -> URL {
        let baseSize = paperSize.pointSize
        let pageRect: CGRect
        if orientation == .landscape {
            pageRect = CGRect(origin: .zero, size: CGSize(width: baseSize.height, height: baseSize.width))
        } else {
            pageRect = CGRect(origin: .zero, size: baseSize)
        }

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name).pdf")

        try renderer.writePDF(to: url) { ctx in
            for drawing in drawings {
                ctx.beginPage()

                guard let cgCtx = UIGraphicsGetCurrentContext() else { continue }

                // Background fill
                let bgColor: UIColor
                switch paperType {
                case .plain:
                    bgColor = .white
                case .textured:
                    bgColor = UIColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 1.0)
                case .graph:
                    bgColor = .white
                }
                cgCtx.setFillColor(bgColor.cgColor)
                cgCtx.fill(pageRect)

                // Grid for graph paper
                if paperType == .graph {
                    drawGrid(in: cgCtx, rect: pageRect)
                }

                // Render drawing
                let image = drawing.image(from: pageRect, scale: 2.0)
                image.draw(in: pageRect)
            }
        }

        return url
    }

    private static func drawGrid(in ctx: CGContext, rect: CGRect) {
        let gridSpacing: CGFloat = 20
        ctx.setStrokeColor(UIColor.systemGray4.withAlphaComponent(0.4).cgColor)
        ctx.setLineWidth(0.5)

        // Vertical lines
        var x = gridSpacing
        while x < rect.width {
            ctx.move(to: CGPoint(x: x, y: 0))
            ctx.addLine(to: CGPoint(x: x, y: rect.height))
            x += gridSpacing
        }

        // Horizontal lines
        var y = gridSpacing
        while y < rect.height {
            ctx.move(to: CGPoint(x: 0, y: y))
            ctx.addLine(to: CGPoint(x: rect.width, y: y))
            y += gridSpacing
        }

        ctx.strokePath()
    }
}
