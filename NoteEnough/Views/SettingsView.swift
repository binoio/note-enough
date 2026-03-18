import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("defaultPaperType") private var defaultPaperType: String = PaperType.plain.rawValue
    @AppStorage("defaultPaperSize") private var defaultPaperSize: String = PaperSize.usLetter.rawValue
    @AppStorage("defaultOrientation") private var defaultOrientation: String = PageOrientation.portrait.rawValue
    @AppStorage("navigationDirection") private var navigationDirection: String = NavigationDirection.leftRight.rawValue
    @AppStorage("confirmDeletion") private var confirmDeletion = true

    private var paperType: Binding<PaperType> {
        Binding(
            get: { PaperType(rawValue: defaultPaperType) ?? .plain },
            set: { defaultPaperType = $0.rawValue }
        )
    }

    private var paperSize: Binding<PaperSize> {
        Binding(
            get: { PaperSize(rawValue: defaultPaperSize) ?? .usLetter },
            set: { defaultPaperSize = $0.rawValue }
        )
    }

    private var orientation: Binding<PageOrientation> {
        Binding(
            get: { PageOrientation(rawValue: defaultOrientation) ?? .portrait },
            set: { defaultOrientation = $0.rawValue }
        )
    }

    private var navDirection: Binding<NavigationDirection> {
        Binding(
            get: { NavigationDirection(rawValue: navigationDirection) ?? .leftRight },
            set: { navigationDirection = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Default Paper Type") {
                    Picker("Type", selection: paperType) {
                        ForEach(PaperType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Default Paper Size") {
                    Picker("Size", selection: paperSize) {
                        ForEach(PaperSize.allCases) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Default Orientation") {
                    Picker("Orientation", selection: orientation) {
                        ForEach(PageOrientation.allCases) { orient in
                            Text(orient.displayName).tag(orient)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Page Navigation") {
                    Picker("Direction", selection: navDirection) {
                        ForEach(NavigationDirection.allCases) { dir in
                            Text(dir.displayName).tag(dir)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Behavior") {
                    Toggle("Confirm Before Deleting", isOn: $confirmDeletion)
                        .accessibilityIdentifier("confirmDeletionToggle")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("settingsDoneButton")
                }
            }
        }
    }
}
