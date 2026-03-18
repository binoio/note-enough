import SwiftUI
import PencilKit

struct PageCanvasView: UIViewRepresentable {
    @Bindable var page: NotePage
    let stack: NoteStack

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        let coordinator = context.coordinator
        coordinator.isSettingUp = true

        canvasView.delegate = coordinator
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false

        let paper = effectiveSize
        canvasView.contentSize = paper
        coordinator.paperRect = CGRect(origin: .zero, size: paper)

        // Paper background at content origin
        let paperView = UIView(frame: CGRect(origin: .zero, size: paper))
        paperView.backgroundColor = paperBackgroundColor
        paperView.layer.borderColor = UIColor.separator.cgColor
        paperView.layer.borderWidth = 1
        paperView.isUserInteractionEnabled = false
        paperView.tag = 1002
        canvasView.insertSubview(paperView, at: 0)

        if stack.paperType == .graph {
            addGridLayer(to: paperView, size: paper)
        }

        // Load drawing directly — paper coordinates ARE canvas coordinates
        canvasView.drawing = page.drawing

        // Tool picker
        let toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        coordinator.toolPicker = toolPicker

        // Pinch-to-zoom
        canvasView.minimumZoomScale = 0.25
        canvasView.maximumZoomScale = 4.0

        // Scroll margins so user can pan around the paper
        canvasView.contentInset = UIEdgeInsets(
            top: paper.height, left: paper.width,
            bottom: paper.height, right: paper.width
        )

        // Find PKCanvasView's internal drawing content view for zoom.
        // PKCanvasView is a UIScrollView; for zoom to work, viewForZooming(in:)
        // must return a subview. We find the largest internal subview (the drawing
        // surface) and cache it as the zoom target.
        for subview in canvasView.subviews where subview.tag != 1002 {
            coordinator.zoomTargetView = subview
            break
        }

        // Center paper in viewport, or restore saved zoom state
        DispatchQueue.main.async {
            canvasView.layoutIfNeeded()
            if let saved = ZoomStateCache.shared.state(for: page.id) {
                canvasView.zoomScale = saved.zoomScale
                canvasView.contentOffset = saved.contentOffset
                coordinator.scrollViewDidZoom(canvasView)
            } else {
                let offsetX = (paper.width - canvasView.bounds.width) / 2
                let offsetY = (paper.height - canvasView.bounds.height) / 2
                canvasView.contentOffset = CGPoint(x: offsetX, y: offsetY)
            }
            coordinator.isSettingUp = false
        }

        return canvasView
    }

    static func dismantleUIView(_ uiView: PKCanvasView, coordinator: Coordinator) {
        ZoomStateCache.shared.save(
            pageID: coordinator.page.id,
            zoomScale: uiView.zoomScale,
            contentOffset: uiView.contentOffset
        )
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        let coordinator = context.coordinator
        coordinator.page = page

        // Re-assert gesture delegate proxy in case PKCanvasView reclaimed it
        if canvasView.drawingGestureRecognizer.delegate !== coordinator {
            coordinator.originalGestureDelegate = canvasView.drawingGestureRecognizer.delegate
            canvasView.drawingGestureRecognizer.delegate = coordinator
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(page: page)
    }

    // MARK: - Helpers

    private var effectiveSize: CGSize {
        let base = stack.paperSize.pointSize
        if stack.orientation == .landscape {
            return CGSize(width: base.height, height: base.width)
        }
        return base
    }

    private var paperBackgroundColor: UIColor {
        switch stack.paperType {
        case .plain, .graph:
            return .systemBackground
        case .textured:
            return UIColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 1.0)
        }
    }

    private func addGridLayer(to view: UIView, size: CGSize) {
        let gridSpacing: CGFloat = 20
        let gridLayer = CAShapeLayer()
        let path = UIBezierPath()

        var x = gridSpacing
        while x < size.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            x += gridSpacing
        }

        var y = gridSpacing
        while y < size.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            y += gridSpacing
        }

        gridLayer.path = path.cgPath
        gridLayer.strokeColor = UIColor.systemGray4.withAlphaComponent(0.4).cgColor
        gridLayer.lineWidth = 0.5
        gridLayer.fillColor = nil
        view.layer.addSublayer(gridLayer)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, PKCanvasViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var page: NotePage
        var toolPicker: PKToolPicker?
        var paperRect: CGRect = .zero
        var isSettingUp: Bool = true
        weak var originalGestureDelegate: (any UIGestureRecognizerDelegate)?
        weak var zoomTargetView: UIView?

        init(page: NotePage) {
            self.page = page
        }

        // MARK: UIScrollViewDelegate — zoom support

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return zoomTargetView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let pv = scrollView.viewWithTag(1002),
                  let zoomTarget = zoomTargetView else { return }

            // Mirror the zoom target's visual frame onto the paper background
            // so the paper stays perfectly aligned with the drawing at every zoom level.
            let scaleX = zoomTarget.frame.width / paperRect.width
            let scaleY = zoomTarget.frame.height / paperRect.height
            pv.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            pv.center = zoomTarget.center
        }

        // MARK: PKCanvasViewDelegate

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !isSettingUp else { return }

            // Clip strokes entirely outside paper bounds
            let drawing = canvasView.drawing
            let validStrokes = drawing.strokes.filter { stroke in
                paperRect.intersects(stroke.renderBounds)
            }

            if validStrokes.count < drawing.strokes.count {
                isSettingUp = true
                var clipped = PKDrawing()
                clipped.strokes = validStrokes
                canvasView.drawing = clipped
                isSettingUp = false
            }

            page.drawing = canvasView.drawing
        }

        // MARK: UIGestureRecognizerDelegate — restrict drawing to paper

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let canvasView = gestureRecognizer.view as? PKCanvasView,
                  let paperView = canvasView.viewWithTag(1002) else {
                return originalGestureDelegate?.gestureRecognizer?(gestureRecognizer, shouldReceive: touch) ?? true
            }
            let locationInPaper = touch.location(in: paperView)
            guard paperView.bounds.contains(locationInPaper) else {
                return false
            }
            return originalGestureDelegate?.gestureRecognizer?(gestureRecognizer, shouldReceive: touch) ?? true
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return originalGestureDelegate?.gestureRecognizerShouldBegin?(gestureRecognizer) ?? true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            return originalGestureDelegate?.gestureRecognizer?(gestureRecognizer, shouldRecognizeSimultaneouslyWith: other) ?? false
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf other: UIGestureRecognizer) -> Bool {
            return originalGestureDelegate?.gestureRecognizer?(gestureRecognizer, shouldRequireFailureOf: other) ?? false
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool {
            return originalGestureDelegate?.gestureRecognizer?(gestureRecognizer, shouldBeRequiredToFailBy: other) ?? false
        }
    }
}
