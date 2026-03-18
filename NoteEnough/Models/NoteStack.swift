import Foundation
import SwiftData

@Model
final class NoteStack {
    var id: UUID
    var name: String
    var paperType: PaperType
    var paperSize: PaperSize
    var orientation: PageOrientation
    var createdAt: Date
    var sortOrder: Int = 0
    var lastViewedPage: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \NotePage.stack)
    var pages: [NotePage]

    init(
        name: String,
        paperType: PaperType = .plain,
        paperSize: PaperSize = .usLetter,
        orientation: PageOrientation = .portrait
    ) {
        self.id = UUID()
        self.name = name
        self.paperType = paperType
        self.paperSize = paperSize
        self.orientation = orientation
        self.createdAt = Date()
        self.pages = []
    }

    var sortedPages: [NotePage] {
        pages.sorted { $0.pageNumber < $1.pageNumber }
    }

    var nextPageNumber: Int {
        (pages.map(\.pageNumber).max() ?? 0) + 1
    }
}
