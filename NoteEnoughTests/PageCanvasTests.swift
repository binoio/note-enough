import XCTest
import PencilKit
@testable import NoteEnough

@MainActor
final class PageCanvasTests: XCTestCase {

    func testEmptyDrawingRoundtrip() throws {
        let page = NotePage(pageNumber: 1)
        let drawing = page.drawing
        XCTAssertTrue(drawing.strokes.isEmpty)

        // Verify the data can be deserialized back
        let restored = try PKDrawing(data: page.drawingData)
        XCTAssertTrue(restored.strokes.isEmpty)
    }

    func testDrawingDataPersistence() throws {
        let page = NotePage(pageNumber: 1)

        // Create a drawing with a stroke
        var drawing = PKDrawing()
        let ink = PKInk(.pen, color: .black)
        let points = [
            PKStrokePoint(location: CGPoint(x: 10, y: 10), timeOffset: 0,
                          size: CGSize(width: 4, height: 4), opacity: 1,
                          force: 1, azimuth: 0, altitude: .pi / 2),
            PKStrokePoint(location: CGPoint(x: 100, y: 100), timeOffset: 0.1,
                          size: CGSize(width: 4, height: 4), opacity: 1,
                          force: 1, azimuth: 0, altitude: .pi / 2),
            PKStrokePoint(location: CGPoint(x: 200, y: 50), timeOffset: 0.2,
                          size: CGSize(width: 4, height: 4), opacity: 1,
                          force: 1, azimuth: 0, altitude: .pi / 2)
        ]
        let path = PKStrokePath(controlPoints: points, creationDate: Date())
        let stroke = PKStroke(ink: ink, path: path)
        drawing.strokes = [stroke]

        // Set drawing on page
        page.drawing = drawing

        // Verify data is not empty
        XCTAssertFalse(page.drawingData.isEmpty)

        // Restore and verify
        let restored = page.drawing
        XCTAssertEqual(restored.strokes.count, 1)
    }

    func testDrawingDataSize() {
        let page = NotePage(pageNumber: 1)

        // Empty drawing should have some data (PKDrawing header)
        let emptySize = page.drawingData.count
        XCTAssertGreaterThan(emptySize, 0)

        // Drawing with stroke should be larger
        var drawing = PKDrawing()
        let ink = PKInk(.pen, color: .black)
        let points = [
            PKStrokePoint(location: CGPoint(x: 0, y: 0), timeOffset: 0,
                          size: CGSize(width: 4, height: 4), opacity: 1,
                          force: 1, azimuth: 0, altitude: .pi / 2),
            PKStrokePoint(location: CGPoint(x: 100, y: 100), timeOffset: 0.1,
                          size: CGSize(width: 4, height: 4), opacity: 1,
                          force: 1, azimuth: 0, altitude: .pi / 2)
        ]
        let path = PKStrokePath(controlPoints: points, creationDate: Date())
        drawing.strokes = [PKStroke(ink: ink, path: path)]
        page.drawing = drawing

        XCTAssertGreaterThan(page.drawingData.count, emptySize)
    }

    func testDrawingCoordinatesMatchPaper() {
        // Paper coordinates ARE canvas coordinates — no translation needed
        var drawing = PKDrawing()
        let ink = PKInk(.pen, color: .black)
        let loc1 = CGPoint(x: 50, y: 50)
        let loc2 = CGPoint(x: 150, y: 150)
        let points = [
            PKStrokePoint(location: loc1, timeOffset: 0,
                          size: CGSize(width: 4, height: 4), opacity: 1,
                          force: 1, azimuth: 0, altitude: .pi / 2),
            PKStrokePoint(location: loc2, timeOffset: 0.1,
                          size: CGSize(width: 4, height: 4), opacity: 1,
                          force: 1, azimuth: 0, altitude: .pi / 2)
        ]
        let path = PKStrokePath(controlPoints: points, creationDate: Date())
        drawing.strokes = [PKStroke(ink: ink, path: path)]

        // Save to page and reload — coordinates should be preserved exactly
        let page = NotePage(pageNumber: 1)
        page.drawing = drawing

        let restored = page.drawing
        let originalBounds = drawing.bounds
        let restoredBounds = restored.bounds
        XCTAssertEqual(originalBounds.origin.x, restoredBounds.origin.x, accuracy: 1)
        XCTAssertEqual(originalBounds.origin.y, restoredBounds.origin.y, accuracy: 1)
        XCTAssertEqual(originalBounds.size.width, restoredBounds.size.width, accuracy: 1)
        XCTAssertEqual(originalBounds.size.height, restoredBounds.size.height, accuracy: 1)
    }

    // MARK: - Drawing Restriction Regression Tests

    func testStrokeClippingRemovesOutOfBoundsStrokes() {
        // Regression: strokes entirely outside paper bounds must be removed
        let page = NotePage(pageNumber: 1)
        let coordinator = PageCanvasView.Coordinator(page: page)
        coordinator.paperRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        coordinator.isSettingUp = false

        let canvasView = PKCanvasView()
        let ink = PKInk(.pen, color: .black)

        // Stroke inside paper bounds
        let insidePoints = [
            PKStrokePoint(location: CGPoint(x: 100, y: 100), timeOffset: 0,
                          size: CGSize(width: 4, height: 4), opacity: 1,
                          force: 1, azimuth: 0, altitude: .pi / 2),
            PKStrokePoint(location: CGPoint(x: 200, y: 200), timeOffset: 0.1,
                          size: CGSize(width: 4, height: 4), opacity: 1,
                          force: 1, azimuth: 0, altitude: .pi / 2)
        ]
        let insidePath = PKStrokePath(controlPoints: insidePoints, creationDate: Date())
        let insideStroke = PKStroke(ink: ink, path: insidePath)

        // Stroke completely outside paper bounds
        let outsidePoints = [
            PKStrokePoint(location: CGPoint(x: 1000, y: 1000), timeOffset: 0,
                          size: CGSize(width: 4, height: 4), opacity: 1,
                          force: 1, azimuth: 0, altitude: .pi / 2),
            PKStrokePoint(location: CGPoint(x: 1100, y: 1100), timeOffset: 0.1,
                          size: CGSize(width: 4, height: 4), opacity: 1,
                          force: 1, azimuth: 0, altitude: .pi / 2)
        ]
        let outsidePath = PKStrokePath(controlPoints: outsidePoints, creationDate: Date())
        let outsideStroke = PKStroke(ink: ink, path: outsidePath)

        var drawing = PKDrawing()
        drawing.strokes = [insideStroke, outsideStroke]
        canvasView.drawing = drawing

        coordinator.canvasViewDrawingDidChange(canvasView)

        XCTAssertEqual(canvasView.drawing.strokes.count, 1,
                       "Only strokes inside paper bounds should remain")
        XCTAssertEqual(page.drawing.strokes.count, 1,
                       "Persisted drawing should only contain valid strokes")
    }

    func testAllInsideStrokesPreserved() {
        // Regression: strokes inside paper bounds must NOT be removed
        let page = NotePage(pageNumber: 1)
        let coordinator = PageCanvasView.Coordinator(page: page)
        coordinator.paperRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        coordinator.isSettingUp = false

        let canvasView = PKCanvasView()
        let ink = PKInk(.pen, color: .black)
        var drawing = PKDrawing()

        for i in 0..<3 {
            let points = [
                PKStrokePoint(location: CGPoint(x: CGFloat(50 + i * 100), y: 50), timeOffset: 0,
                              size: CGSize(width: 4, height: 4), opacity: 1,
                              force: 1, azimuth: 0, altitude: .pi / 2),
                PKStrokePoint(location: CGPoint(x: CGFloat(100 + i * 100), y: 200), timeOffset: 0.1,
                              size: CGSize(width: 4, height: 4), opacity: 1,
                              force: 1, azimuth: 0, altitude: .pi / 2)
            ]
            let path = PKStrokePath(controlPoints: points, creationDate: Date())
            drawing.strokes.append(PKStroke(ink: ink, path: path))
        }

        canvasView.drawing = drawing
        coordinator.canvasViewDrawingDidChange(canvasView)

        XCTAssertEqual(canvasView.drawing.strokes.count, 3,
                       "All strokes inside paper bounds should be preserved")
        XCTAssertEqual(page.drawing.strokes.count, 3)
    }

    // MARK: - Paper Centering Regression Tests

    func testPaperContentAtOrigin() {
        // Regression: drawing coordinates must start at (0,0) — paper origin,
        // not offset by any canvas margin. Previously a 3x content area shifted
        // coordinates by (paperWidth, paperHeight).
        let page = NotePage(pageNumber: 1)
        let ink = PKInk(.pen, color: .black)

        // Draw near the center of US Letter (612 × 792)
        let center = CGPoint(x: 306, y: 396)
        let points = [
            PKStrokePoint(location: center, timeOffset: 0,
                          size: CGSize(width: 4, height: 4), opacity: 1,
                          force: 1, azimuth: 0, altitude: .pi / 2),
            PKStrokePoint(location: CGPoint(x: 307, y: 397), timeOffset: 0.1,
                          size: CGSize(width: 4, height: 4), opacity: 1,
                          force: 1, azimuth: 0, altitude: .pi / 2)
        ]
        var drawing = PKDrawing()
        let path = PKStrokePath(controlPoints: points, creationDate: Date())
        drawing.strokes = [PKStroke(ink: ink, path: path)]
        page.drawing = drawing

        let restored = page.drawing
        let paperRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        XCTAssertTrue(paperRect.contains(restored.bounds),
                      "Stroke bounds \(restored.bounds) must be within paper rect \(paperRect)")
        XCTAssertEqual(restored.bounds.midX, drawing.bounds.midX, accuracy: 2,
                       "Stroke X coordinate must be preserved without offset")
        XCTAssertEqual(restored.bounds.midY, drawing.bounds.midY, accuracy: 2,
                       "Stroke Y coordinate must be preserved without offset")
    }

    // MARK: - Pinch-to-Zoom Regression Tests

    func testViewForZoomingReturnsZoomTarget() {
        // Regression: viewForZooming(in:) must return the cached zoom target,
        // not nil. Returning nil disables UIScrollView zoom entirely.
        let page = NotePage(pageNumber: 1)
        let coordinator = PageCanvasView.Coordinator(page: page)
        let dummyTarget = UIView()
        coordinator.zoomTargetView = dummyTarget

        let scrollView = UIScrollView()
        let result = coordinator.viewForZooming(in: scrollView)
        XCTAssertIdentical(result, dummyTarget,
                           "viewForZooming must return the cached zoom target")
    }

    func testViewForZoomingReturnsNilWhenNoTarget() {
        // When no zoom target is cached, viewForZooming should return nil
        // (graceful degradation, not a crash).
        let page = NotePage(pageNumber: 1)
        let coordinator = PageCanvasView.Coordinator(page: page)

        let scrollView = UIScrollView()
        XCTAssertNil(coordinator.viewForZooming(in: scrollView))
    }

    func testScrollViewDidZoomUpdatesPaperView() {
        // Regression: during zoom the paper background must track the zoom
        // target's visual frame so it stays aligned with the drawing.
        let page = NotePage(pageNumber: 1)
        let coordinator = PageCanvasView.Coordinator(page: page)
        coordinator.paperRect = CGRect(x: 0, y: 0, width: 612, height: 792)

        let scrollView = PKCanvasView()
        scrollView.frame = CGRect(x: 0, y: 0, width: 1024, height: 768)

        // Paper background view
        let paperView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 612, height: 792)))
        paperView.tag = 1002
        scrollView.addSubview(paperView)

        // Simulated zoom target at 2× scale
        let zoomTarget = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 612, height: 792)))
        zoomTarget.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        scrollView.addSubview(zoomTarget)
        coordinator.zoomTargetView = zoomTarget

        coordinator.scrollViewDidZoom(scrollView)

        // Paper view should now match the zoom target's visual frame
        XCTAssertEqual(paperView.frame.width, zoomTarget.frame.width, accuracy: 1,
                       "Paper width must match zoom target after zoom")
        XCTAssertEqual(paperView.frame.height, zoomTarget.frame.height, accuracy: 1,
                       "Paper height must match zoom target after zoom")
        XCTAssertEqual(paperView.center.x, zoomTarget.center.x, accuracy: 1,
                       "Paper center X must match zoom target after zoom")
        XCTAssertEqual(paperView.center.y, zoomTarget.center.y, accuracy: 1,
                       "Paper center Y must match zoom target after zoom")
    }

    func testScrollViewDidZoomTracksAtMultipleScales() {
        // Verify paper tracking works at various zoom levels, not just 2×.
        let page = NotePage(pageNumber: 1)
        let coordinator = PageCanvasView.Coordinator(page: page)
        coordinator.paperRect = CGRect(x: 0, y: 0, width: 612, height: 792)

        let scrollView = PKCanvasView()
        scrollView.frame = CGRect(x: 0, y: 0, width: 1024, height: 768)

        let paperView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 612, height: 792)))
        paperView.tag = 1002
        scrollView.addSubview(paperView)

        let zoomTarget = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 612, height: 792)))
        scrollView.addSubview(zoomTarget)
        coordinator.zoomTargetView = zoomTarget

        for scale in [0.25, 0.5, 1.0, 2.0, 4.0] {
            zoomTarget.transform = CGAffineTransform(scaleX: scale, y: scale)
            coordinator.scrollViewDidZoom(scrollView)

            XCTAssertEqual(paperView.frame.width, zoomTarget.frame.width, accuracy: 1,
                           "Paper width must match zoom target at scale \(scale)")
            XCTAssertEqual(paperView.frame.height, zoomTarget.frame.height, accuracy: 1,
                           "Paper height must match zoom target at scale \(scale)")
            XCTAssertEqual(paperView.center.x, zoomTarget.center.x, accuracy: 1,
                           "Paper center X must match zoom target at scale \(scale)")
            XCTAssertEqual(paperView.center.y, zoomTarget.center.y, accuracy: 1,
                           "Paper center Y must match zoom target at scale \(scale)")
        }
    }

    // MARK: - ZoomStateCache Tests

    func testZoomStateCacheSaveAndRetrieve() {
        let cache = ZoomStateCache.shared
        let pageID = UUID()
        cache.save(pageID: pageID, zoomScale: 2.5, contentOffset: CGPoint(x: 100, y: 200))

        let state = cache.state(for: pageID)
        XCTAssertNotNil(state)
        XCTAssertEqual(state?.zoomScale, 2.5)
        XCTAssertEqual(state?.contentOffset.x, 100)
        XCTAssertEqual(state?.contentOffset.y, 200)
    }

    func testZoomStateCacheMissReturnsNil() {
        let cache = ZoomStateCache.shared
        let unknownID = UUID()
        XCTAssertNil(cache.state(for: unknownID))
    }

    func testZoomStateCacheOverwrite() {
        let cache = ZoomStateCache.shared
        let pageID = UUID()
        cache.save(pageID: pageID, zoomScale: 1.0, contentOffset: .zero)
        cache.save(pageID: pageID, zoomScale: 3.0, contentOffset: CGPoint(x: 50, y: 75))

        let state = cache.state(for: pageID)
        XCTAssertEqual(state?.zoomScale, 3.0)
        XCTAssertEqual(state?.contentOffset.x, 50)
        XCTAssertEqual(state?.contentOffset.y, 75)
    }

    func testMultipleDrawingUpdates() {
        let page = NotePage(pageNumber: 1)

        // Update drawing multiple times
        for i in 0..<5 {
            var drawing = PKDrawing()
            let ink = PKInk(.pen, color: .black)
            let points = [
                PKStrokePoint(location: CGPoint(x: CGFloat(i * 10), y: 0), timeOffset: 0,
                              size: CGSize(width: 4, height: 4), opacity: 1,
                              force: 1, azimuth: 0, altitude: .pi / 2),
                PKStrokePoint(location: CGPoint(x: CGFloat(i * 10 + 50), y: 50), timeOffset: 0.1,
                              size: CGSize(width: 4, height: 4), opacity: 1,
                              force: 1, azimuth: 0, altitude: .pi / 2)
            ]
            let path = PKStrokePath(controlPoints: points, creationDate: Date())
            drawing.strokes = [PKStroke(ink: ink, path: path)]
            page.drawing = drawing
        }

        // Final state should have exactly 1 stroke (last update)
        let finalDrawing = page.drawing
        XCTAssertEqual(finalDrawing.strokes.count, 1)
    }
}
