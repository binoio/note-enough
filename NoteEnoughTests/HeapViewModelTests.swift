import XCTest
import SwiftData
@testable import NoteEnough

final class HeapViewModelTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var viewModel: HeapViewModel!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: NoteStack.self, NotePage.self, configurations: config)
        context = ModelContext(container)
        viewModel = HeapViewModel()
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
        viewModel = nil
    }

    func testInitialState() {
        XCTAssertFalse(viewModel.isSelecting)
        XCTAssertTrue(viewModel.selectedStacks.isEmpty)
        XCTAssertFalse(viewModel.showingAddSheet)
        XCTAssertFalse(viewModel.showingSettings)
    }

    func testEnterSelectionMode() {
        viewModel.enterSelectionMode()
        XCTAssertTrue(viewModel.isSelecting)
        XCTAssertTrue(viewModel.selectedStacks.isEmpty)
    }

    func testExitSelectionMode() {
        let stack = NoteStack(name: "Test")
        viewModel.enterSelectionMode()
        viewModel.toggleSelection(for: stack)
        XCTAssertFalse(viewModel.selectedStacks.isEmpty)

        viewModel.exitSelectionMode()
        XCTAssertFalse(viewModel.isSelecting)
        XCTAssertTrue(viewModel.selectedStacks.isEmpty)
    }

    func testToggleSelection() {
        let stack = NoteStack(name: "Test")

        viewModel.toggleSelection(for: stack)
        XCTAssertTrue(viewModel.isSelected(stack))

        viewModel.toggleSelection(for: stack)
        XCTAssertFalse(viewModel.isSelected(stack))
    }

    func testAddStack() throws {
        viewModel.addStack(
            name: "New Stack",
            paperType: .graph,
            paperSize: .a4,
            orientation: .landscape,
            context: context
        )

        try context.save()

        let descriptor = FetchDescriptor<NoteStack>()
        let stacks = try context.fetch(descriptor)
        XCTAssertEqual(stacks.count, 1)
        XCTAssertEqual(stacks.first?.name, "New Stack")
        XCTAssertEqual(stacks.first?.paperType, .graph)
        XCTAssertEqual(stacks.first?.paperSize, .a4)
        XCTAssertEqual(stacks.first?.orientation, .landscape)
        XCTAssertEqual(stacks.first?.pages.count, 1, "Should auto-create first page")
    }

    func testDeleteSelected() throws {
        let stack1 = NoteStack(name: "Keep")
        let stack2 = NoteStack(name: "Delete")
        context.insert(stack1)
        context.insert(stack2)
        try context.save()

        viewModel.enterSelectionMode()
        viewModel.toggleSelection(for: stack2)

        let allStacks = [stack1, stack2]
        viewModel.deleteSelected(from: allStacks, context: context)
        try context.save()

        let descriptor = FetchDescriptor<NoteStack>()
        let remaining = try context.fetch(descriptor)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.name, "Keep")
        XCTAssertFalse(viewModel.isSelecting)
        XCTAssertTrue(viewModel.selectedStacks.isEmpty)
    }

    func testAddStackAssignsSequentialSortOrder() throws {
        viewModel.addStack(name: "First", paperType: .plain, paperSize: .usLetter, orientation: .portrait, context: context)
        viewModel.addStack(name: "Second", paperType: .plain, paperSize: .usLetter, orientation: .portrait, context: context)
        viewModel.addStack(name: "Third", paperType: .plain, paperSize: .usLetter, orientation: .portrait, context: context)
        try context.save()

        let descriptor = FetchDescriptor<NoteStack>(sortBy: [SortDescriptor(\NoteStack.sortOrder)])
        let stacks = try context.fetch(descriptor)
        XCTAssertEqual(stacks.count, 3)
        XCTAssertEqual(stacks[0].sortOrder, 0)
        XCTAssertEqual(stacks[1].sortOrder, 1)
        XCTAssertEqual(stacks[2].sortOrder, 2)
        XCTAssertEqual(stacks[0].name, "First")
        XCTAssertEqual(stacks[1].name, "Second")
        XCTAssertEqual(stacks[2].name, "Third")
    }

    func testMultipleSelection() {
        let stack1 = NoteStack(name: "Stack 1")
        let stack2 = NoteStack(name: "Stack 2")
        let stack3 = NoteStack(name: "Stack 3")

        viewModel.enterSelectionMode()
        viewModel.toggleSelection(for: stack1)
        viewModel.toggleSelection(for: stack3)

        XCTAssertTrue(viewModel.isSelected(stack1))
        XCTAssertFalse(viewModel.isSelected(stack2))
        XCTAssertTrue(viewModel.isSelected(stack3))
        XCTAssertEqual(viewModel.selectedStacks.count, 2)
    }

    func testDuplicateStack() throws {
        let stack = NoteStack(name: "Original", paperType: .graph, paperSize: .a4, orientation: .landscape)
        context.insert(stack)

        let page1 = NotePage(pageNumber: 1, stack: stack)
        page1.drawingData = Data([0x01, 0x02, 0x03])
        stack.pages.append(page1)

        let page2 = NotePage(pageNumber: 2, stack: stack)
        page2.drawingData = Data([0x04, 0x05, 0x06])
        stack.pages.append(page2)

        try context.save()

        viewModel.duplicateStack(stack, context: context)
        try context.save()

        let descriptor = FetchDescriptor<NoteStack>(sortBy: [SortDescriptor(\NoteStack.sortOrder)])
        let stacks = try context.fetch(descriptor)
        XCTAssertEqual(stacks.count, 2)

        let copy = stacks.first { $0.name == "Original Copy" }
        XCTAssertNotNil(copy)
        XCTAssertEqual(copy?.paperType, .graph)
        XCTAssertEqual(copy?.paperSize, .a4)
        XCTAssertEqual(copy?.orientation, .landscape)
        XCTAssertEqual(copy?.pages.count, 2)

        let copiedPages = copy!.sortedPages
        XCTAssertEqual(copiedPages[0].drawingData, Data([0x01, 0x02, 0x03]))
        XCTAssertEqual(copiedPages[1].drawingData, Data([0x04, 0x05, 0x06]))
    }

    func testDeleteSingleStack() throws {
        let stack = NoteStack(name: "ToDelete")
        context.insert(stack)
        try context.save()

        let before = try context.fetch(FetchDescriptor<NoteStack>())
        XCTAssertEqual(before.count, 1)

        viewModel.deleteSingleStack(stack, context: context)
        try context.save()

        let after = try context.fetch(FetchDescriptor<NoteStack>())
        XCTAssertEqual(after.count, 0)
    }

    func testLastViewedPageDefaultsToZero() {
        let stack = NoteStack(name: "Test")
        XCTAssertEqual(stack.lastViewedPage, 0)
    }

    func testRenameState() {
        XCTAssertNil(viewModel.renamingStack)
        XCTAssertEqual(viewModel.renameText, "")
        XCTAssertFalse(viewModel.showingRenameAlert)

        let stack = NoteStack(name: "Test")
        viewModel.renamingStack = stack
        viewModel.renameText = "Renamed"
        viewModel.showingRenameAlert = true

        XCTAssertNotNil(viewModel.renamingStack)
        XCTAssertEqual(viewModel.renameText, "Renamed")
        XCTAssertTrue(viewModel.showingRenameAlert)
    }
}
