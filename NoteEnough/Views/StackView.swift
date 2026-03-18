import SwiftUI
import SwiftData
import PencilKit

struct StackView: View {
    @Bindable var stack: NoteStack
    @Environment(\.modelContext) private var modelContext
    @AppStorage("navigationDirection") private var navigationDirection: String = NavigationDirection.leftRight.rawValue
    @State private var currentPageIndex: Int = 0
    @State private var showingShareSheet = false
    @State private var pdfURL: URL?
    @State private var showingPagePicker = false
    @State private var isEditingPages = false

    private var navDirection: NavigationDirection {
        NavigationDirection(rawValue: navigationDirection) ?? .leftRight
    }

    private var sortedPages: [NotePage] {
        stack.sortedPages
    }

    var body: some View {
        VStack(spacing: 0) {
            if sortedPages.isEmpty {
                ContentUnavailableView(
                    "No Pages",
                    systemImage: "doc",
                    description: Text("Tap + to add a page.")
                )
            } else if isEditingPages {
                List {
                    ForEach(sortedPages) { page in
                        HStack {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.secondary)
                            Text("Page \(page.pageNumber)")
                        }
                    }
                    .onMove(perform: movePages)
                }
                .environment(\.editMode, .constant(.active))
            } else {
                TabView(selection: $currentPageIndex) {
                    ForEach(Array(sortedPages.enumerated()), id: \.element.id) { index, page in
                        PageCanvasView(page: page, stack: stack)
                            .background(Color(UIColor.systemGray4))
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .rotationEffect(navDirection == .upDown ? .degrees(90) : .zero)
            }
        }
        .navigationTitle(stack.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if isEditingPages {
                        // Clamp currentPageIndex when leaving edit mode
                        currentPageIndex = min(currentPageIndex, sortedPages.count - 1)
                    }
                    isEditingPages.toggle()
                } label: {
                    Text(isEditingPages ? "Done" : "Edit")
                }
                .disabled(sortedPages.isEmpty)
                .accessibilityIdentifier("editPagesButton")
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button {
                        exportAndShare()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("shareButton")

                    Button {
                        showingPagePicker = true
                    } label: {
                        Text("Page \(min(currentPageIndex + 1, sortedPages.count))/\(sortedPages.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier("pagePickerButton")
                    .popover(isPresented: $showingPagePicker) {
                        List {
                            ForEach(Array(sortedPages.enumerated()), id: \.element.id) { index, page in
                                Button {
                                    currentPageIndex = index
                                    showingPagePicker = false
                                } label: {
                                    HStack {
                                        Text("Page \(page.pageNumber)")
                                        Spacer()
                                        if index == currentPageIndex {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                                .accessibilityIdentifier("pageItem_\(index)")
                            }
                        }
                        .frame(minWidth: 200, minHeight: min(CGFloat(sortedPages.count) * 44, 9 * 44))
                        .presentationCompactAdaptation(.popover)
                    }

                    Button {
                        addPage()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("addPageButton")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfURL {
                ActivityViewController(activityItems: [pdfURL])
            }
        }
        .onAppear {
            currentPageIndex = min(stack.lastViewedPage, max(sortedPages.count - 1, 0))
        }
        .onDisappear {
            stack.lastViewedPage = currentPageIndex
        }
        .onChange(of: currentPageIndex) { _, newValue in
            stack.lastViewedPage = newValue
        }
    }

    private func movePages(from source: IndexSet, to destination: Int) {
        var pages = sortedPages
        pages.move(fromOffsets: source, toOffset: destination)
        for (index, page) in pages.enumerated() {
            page.pageNumber = index + 1
        }
    }

    private func addPage() {
        let page = NotePage(pageNumber: stack.nextPageNumber, stack: stack)
        stack.pages.append(page)
        currentPageIndex = sortedPages.count - 1
    }

    private func exportAndShare() {
        // Extract model data on main actor
        let name = stack.name
        let drawings = sortedPages.map(\.drawing)
        let paperType = stack.paperType
        let paperSize = stack.paperSize
        let orientation = stack.orientation

        Task.detached {
            let url = try PDFExporter.export(
                name: name,
                drawings: drawings,
                paperType: paperType,
                paperSize: paperSize,
                orientation: orientation
            )
            await MainActor.run {
                pdfURL = url
                showingShareSheet = true
            }
        }
    }
}
