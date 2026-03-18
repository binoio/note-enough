import SwiftUI
import SwiftData

struct AddStackSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var viewModel: HeapViewModel

    @AppStorage("defaultPaperType") private var defaultPaperType: String = PaperType.plain.rawValue
    @AppStorage("defaultPaperSize") private var defaultPaperSize: String = PaperSize.usLetter.rawValue
    @AppStorage("defaultOrientation") private var defaultOrientation: String = PageOrientation.portrait.rawValue

    @State private var name: String = ""
    @State private var paperType: PaperType = .plain
    @State private var paperSize: PaperSize = .usLetter
    @State private var orientation: PageOrientation = .portrait

    var body: some View {
        NavigationStack {
            Form {
                Section("Stack Name") {
                    TextField("My Notes", text: $name)
                        .accessibilityIdentifier("stackNameField")
                }

                Section("Paper Type") {
                    Picker("Type", selection: $paperType) {
                        ForEach(PaperType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("paperTypePicker")
                }

                Section("Paper Size") {
                    Picker("Size", selection: $paperSize) {
                        ForEach(PaperSize.allCases) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("paperSizePicker")
                }

                Section("Orientation") {
                    Picker("Orientation", selection: $orientation) {
                        ForEach(PageOrientation.allCases) { orient in
                            Text(orient.displayName).tag(orient)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("orientationPicker")
                }
            }
            .navigationTitle("New Stack")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("cancelButton")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let stackName = name.isEmpty ? "Untitled" : name
                        viewModel.addStack(
                            name: stackName,
                            paperType: paperType,
                            paperSize: paperSize,
                            orientation: orientation,
                            context: modelContext
                        )
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .accessibilityIdentifier("confirmButton")
                }
            }
            .onAppear {
                paperType = PaperType(rawValue: defaultPaperType) ?? .plain
                paperSize = PaperSize(rawValue: defaultPaperSize) ?? .usLetter
                orientation = PageOrientation(rawValue: defaultOrientation) ?? .portrait
            }
        }
    }
}
