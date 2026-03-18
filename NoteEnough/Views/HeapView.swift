import SwiftUI
import SwiftData
import PencilKit
import UniformTypeIdentifiers

struct HeapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NoteStack.sortOrder) private var stacks: [NoteStack]
    @State private var viewModel = HeapViewModel()
    @State private var draggedStack: NoteStack?
    @State private var navigationPath = NavigationPath()
    @AppStorage("confirmDeletion") private var confirmDeletion = true

    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 20)
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if stacks.isEmpty {
                    ContentUnavailableView(
                        "No Stacks Yet",
                        systemImage: "square.stack.3d.up",
                        description: Text("Tap + to create your first stack.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(stacks) { stack in
                                stackCell(stack)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Note Stacks")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityIdentifier("settingsButton")
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    if viewModel.isSelecting {
                        Button {
                            viewModel.deleteSelected(from: stacks, context: modelContext)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .disabled(viewModel.selectedStacks.isEmpty)
                        .accessibilityIdentifier("deleteButton")

                        Button("Done") {
                            viewModel.exitSelectionMode()
                        }
                        .accessibilityIdentifier("doneButton")
                    } else {
                        Button("Select") {
                            viewModel.enterSelectionMode()
                        }
                        .disabled(stacks.isEmpty)
                        .accessibilityIdentifier("selectButton")

                        Button {
                            viewModel.showingAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .disabled(stacks.count >= 9)
                        .accessibilityIdentifier("addStackButton")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                AddStackSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                SettingsView()
            }
            .alert("Rename Stack", isPresented: $viewModel.showingRenameAlert) {
                TextField("Stack Name", text: $viewModel.renameText)
                Button("Cancel", role: .cancel) { }
                Button("Rename") {
                    if let stack = viewModel.renamingStack {
                        stack.name = viewModel.renameText
                    }
                    viewModel.renamingStack = nil
                }
            }
            .confirmationDialog(
                "Delete Stack?",
                isPresented: $viewModel.showingDeleteConfirmation,
                presenting: viewModel.stackToDelete
            ) { stack in
                Button("Delete", role: .destructive) {
                    viewModel.deleteSingleStack(stack, context: modelContext)
                    viewModel.stackToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    viewModel.stackToDelete = nil
                }
            } message: { stack in
                Text("Are you sure you want to delete \"\(stack.name)\"? This cannot be undone.")
            }
            .navigationDestination(for: NoteStack.self) { stack in
                StackView(stack: stack)
            }
        }
    }

    @ViewBuilder
    private func stackCell(_ stack: NoteStack) -> some View {
        if viewModel.isSelecting {
            Button {
                viewModel.toggleSelection(for: stack)
            } label: {
                stackCardContent(stack)
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: viewModel.isSelected(stack) ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(viewModel.isSelected(stack) ? .blue : .secondary)
                            .padding(8)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("stack_\(stack.name)")
        } else {
            stackCardContent(stack)
                .overlay(alignment: .bottomTrailing) {
                    Menu {
                        Button {
                            viewModel.renameText = stack.name
                            viewModel.renamingStack = stack
                            viewModel.showingRenameAlert = true
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }

                        Button {
                            viewModel.duplicateStack(stack, context: modelContext)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }

                        Button(role: .destructive) {
                            if confirmDeletion {
                                viewModel.stackToDelete = stack
                                viewModel.showingDeleteConfirmation = true
                            } else {
                                viewModel.deleteSingleStack(stack, context: modelContext)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .padding(8)
                    }
                    .accessibilityIdentifier("stackMenuButton_\(stack.name)")
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    navigationPath.append(stack)
                }
                .onDrag {
                    draggedStack = stack
                    return NSItemProvider(object: stack.id.uuidString as NSString)
                }
                .onDrop(of: [.plainText], delegate: StackDropDelegate(stack: stack, draggedStack: $draggedStack))
                .accessibilityIdentifier("stack_\(stack.name)")
        }
    }

    private func stackCardContent(_ stack: NoteStack) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottom) {
                if let image = thumbnailImage(for: stack) {
                    paperColor(for: stack)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Color.secondary.opacity(0.15)
                    Image(systemName: "doc.text")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }

                Text("\(stack.pages.count) page\(stack.pages.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(6)
            }
            .aspectRatio(stack.orientation == .portrait ? 0.77 : 1.29, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(stack.name)
                .font(.headline)
                .lineLimit(1)

            Text(stack.paperType.displayName + " · " + stack.paperSize.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        )
    }

    // MARK: - Helpers

    private func thumbnailImage(for stack: NoteStack) -> UIImage? {
        guard let firstPage = stack.sortedPages.first else { return nil }
        let drawing = firstPage.drawing
        guard !drawing.strokes.isEmpty else { return nil }
        let size = effectiveSize(for: stack)
        let rect = CGRect(origin: .zero, size: size)
        return drawing.image(from: rect, scale: 1.0)
    }

    private func effectiveSize(for stack: NoteStack) -> CGSize {
        let base = stack.paperSize.pointSize
        if stack.orientation == .landscape {
            return CGSize(width: base.height, height: base.width)
        }
        return base
    }

    private func paperColor(for stack: NoteStack) -> Color {
        switch stack.paperType {
        case .plain, .graph:
            return Color(.systemBackground)
        case .textured:
            return Color(red: 0.98, green: 0.96, blue: 0.90)
        }
    }
}

// MARK: - Drag & Drop

private struct StackDropDelegate: DropDelegate {
    let stack: NoteStack
    @Binding var draggedStack: NoteStack?

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedStack, dragged.id != stack.id else { return }
        let fromOrder = dragged.sortOrder
        let toOrder = stack.sortOrder
        dragged.sortOrder = toOrder
        stack.sortOrder = fromOrder
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedStack = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
