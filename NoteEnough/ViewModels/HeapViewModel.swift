import Foundation
import SwiftData
import Observation

@Observable
final class HeapViewModel {
    var isSelecting = false
    var selectedStacks: Set<UUID> = []
    var showingAddSheet = false
    var showingSettings = false

    // Rename state
    var renamingStack: NoteStack?
    var renameText = ""
    var showingRenameAlert = false

    // Delete state
    var stackToDelete: NoteStack?
    var showingDeleteConfirmation = false

    func toggleSelection(for stack: NoteStack) {
        if selectedStacks.contains(stack.id) {
            selectedStacks.remove(stack.id)
        } else {
            selectedStacks.insert(stack.id)
        }
    }

    func isSelected(_ stack: NoteStack) -> Bool {
        selectedStacks.contains(stack.id)
    }

    func enterSelectionMode() {
        isSelecting = true
        selectedStacks.removeAll()
    }

    func exitSelectionMode() {
        isSelecting = false
        selectedStacks.removeAll()
    }

    func deleteSelected(from stacks: [NoteStack], context: ModelContext) {
        for stack in stacks where selectedStacks.contains(stack.id) {
            context.delete(stack)
        }
        selectedStacks.removeAll()
        isSelecting = false
    }

    func addStack(
        name: String,
        paperType: PaperType,
        paperSize: PaperSize,
        orientation: PageOrientation,
        context: ModelContext
    ) {
        // Compute next sort order
        let descriptor = FetchDescriptor<NoteStack>(
            sortBy: [SortDescriptor(\NoteStack.sortOrder, order: .reverse)]
        )
        let maxSortOrder = (try? context.fetch(descriptor).first?.sortOrder) ?? -1

        let stack = NoteStack(
            name: name,
            paperType: paperType,
            paperSize: paperSize,
            orientation: orientation
        )
        stack.sortOrder = maxSortOrder + 1
        // Create first page automatically
        let firstPage = NotePage(pageNumber: 1, stack: stack)
        stack.pages.append(firstPage)
        context.insert(stack)
    }

    func duplicateStack(_ stack: NoteStack, context: ModelContext) {
        let descriptor = FetchDescriptor<NoteStack>(
            sortBy: [SortDescriptor(\NoteStack.sortOrder, order: .reverse)]
        )
        let maxSortOrder = (try? context.fetch(descriptor).first?.sortOrder) ?? -1

        let newStack = NoteStack(
            name: "\(stack.name) Copy",
            paperType: stack.paperType,
            paperSize: stack.paperSize,
            orientation: stack.orientation
        )
        newStack.sortOrder = maxSortOrder + 1

        for page in stack.sortedPages {
            let newPage = NotePage(pageNumber: page.pageNumber, stack: newStack)
            newPage.drawingData = page.drawingData
            newStack.pages.append(newPage)
        }

        context.insert(newStack)
    }

    func deleteSingleStack(_ stack: NoteStack, context: ModelContext) {
        context.delete(stack)
    }
}
