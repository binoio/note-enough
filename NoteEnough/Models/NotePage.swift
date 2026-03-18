import Foundation
import SwiftData
import PencilKit

@Model
final class NotePage {
    var id: UUID
    var drawingData: Data
    var pageNumber: Int
    var createdAt: Date
    var stack: NoteStack?

    init(pageNumber: Int, stack: NoteStack? = nil) {
        self.id = UUID()
        self.drawingData = PKDrawing().dataRepresentation()
        self.pageNumber = pageNumber
        self.createdAt = Date()
        self.stack = stack
    }

    var drawing: PKDrawing {
        get {
            (try? PKDrawing(data: drawingData)) ?? PKDrawing()
        }
        set {
            drawingData = newValue.dataRepresentation()
        }
    }
}
