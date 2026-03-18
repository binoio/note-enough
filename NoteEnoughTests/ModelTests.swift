import XCTest
import SwiftData
import PencilKit
@testable import NoteEnough

final class ModelTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: NoteStack.self, NotePage.self, configurations: config)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // MARK: - Enum Tests

    func testPaperTypeCases() {
        XCTAssertEqual(PaperType.allCases.count, 3)
        XCTAssertEqual(PaperType.plain.displayName, "Plain")
        XCTAssertEqual(PaperType.textured.displayName, "Textured")
        XCTAssertEqual(PaperType.graph.displayName, "Graph")
    }

    func testPaperSizeCases() {
        XCTAssertEqual(PaperSize.allCases.count, 2)
        XCTAssertEqual(PaperSize.usLetter.displayName, "US Letter")
        XCTAssertEqual(PaperSize.a4.displayName, "A4")
    }

    func testPaperSizePointSize() {
        let letter = PaperSize.usLetter.pointSize
        XCTAssertEqual(letter.width, 612)
        XCTAssertEqual(letter.height, 792)

        let a4 = PaperSize.a4.pointSize
        XCTAssertEqual(a4.width, 595)
        XCTAssertEqual(a4.height, 842)
    }

    func testPageOrientationCases() {
        XCTAssertEqual(PageOrientation.allCases.count, 2)
        XCTAssertEqual(PageOrientation.portrait.displayName, "Portrait")
        XCTAssertEqual(PageOrientation.landscape.displayName, "Landscape")
    }

    func testNavigationDirectionCases() {
        XCTAssertEqual(NavigationDirection.allCases.count, 2)
        XCTAssertEqual(NavigationDirection.leftRight.displayName, "Left / Right")
        XCTAssertEqual(NavigationDirection.upDown.displayName, "Up / Down")
    }

    func testEnumCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for paperType in PaperType.allCases {
            let data = try encoder.encode(paperType)
            let decoded = try decoder.decode(PaperType.self, from: data)
            XCTAssertEqual(decoded, paperType)
        }

        for paperSize in PaperSize.allCases {
            let data = try encoder.encode(paperSize)
            let decoded = try decoder.decode(PaperSize.self, from: data)
            XCTAssertEqual(decoded, paperSize)
        }
    }

    // MARK: - NoteStack Tests

    func testStackCreationDefaults() {
        let stack = NoteStack(name: "Test Stack")
        XCTAssertEqual(stack.name, "Test Stack")
        XCTAssertEqual(stack.paperType, .plain)
        XCTAssertEqual(stack.paperSize, .usLetter)
        XCTAssertEqual(stack.orientation, .portrait)
        XCTAssertTrue(stack.pages.isEmpty)
        XCTAssertNotNil(stack.id)
        XCTAssertNotNil(stack.createdAt)
    }

    func testStackCreationCustom() {
        let stack = NoteStack(
            name: "Graph Notes",
            paperType: .graph,
            paperSize: .a4,
            orientation: .landscape
        )
        XCTAssertEqual(stack.name, "Graph Notes")
        XCTAssertEqual(stack.paperType, .graph)
        XCTAssertEqual(stack.paperSize, .a4)
        XCTAssertEqual(stack.orientation, .landscape)
    }

    func testStackNextPageNumber() {
        let stack = NoteStack(name: "Test")
        XCTAssertEqual(stack.nextPageNumber, 1)

        let page1 = NotePage(pageNumber: 1, stack: stack)
        stack.pages.append(page1)
        XCTAssertEqual(stack.nextPageNumber, 2)

        let page2 = NotePage(pageNumber: 2, stack: stack)
        stack.pages.append(page2)
        XCTAssertEqual(stack.nextPageNumber, 3)
    }

    func testStackSortedPages() {
        let stack = NoteStack(name: "Test")
        let page3 = NotePage(pageNumber: 3, stack: stack)
        let page1 = NotePage(pageNumber: 1, stack: stack)
        let page2 = NotePage(pageNumber: 2, stack: stack)
        stack.pages = [page3, page1, page2]

        let sorted = stack.sortedPages
        XCTAssertEqual(sorted[0].pageNumber, 1)
        XCTAssertEqual(sorted[1].pageNumber, 2)
        XCTAssertEqual(sorted[2].pageNumber, 3)
    }

    // MARK: - NotePage Tests

    func testPageCreation() {
        let page = NotePage(pageNumber: 1)
        XCTAssertEqual(page.pageNumber, 1)
        XCTAssertNotNil(page.id)
        XCTAssertNotNil(page.createdAt)
        XCTAssertNil(page.stack)
        XCTAssertFalse(page.drawingData.isEmpty)
    }

    func testPageWithStack() {
        let stack = NoteStack(name: "Test")
        let page = NotePage(pageNumber: 1, stack: stack)
        XCTAssertNotNil(page.stack)
    }

    func testStackPersistence() throws {
        let stack = NoteStack(name: "Persisted Stack", paperType: .graph)
        context.insert(stack)
        try context.save()

        let descriptor = FetchDescriptor<NoteStack>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Persisted Stack")
        XCTAssertEqual(fetched.first?.paperType, .graph)
    }
}
