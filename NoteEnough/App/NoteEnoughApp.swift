import SwiftUI
import SwiftData

@main
struct NoteEnoughApp: App {
    var body: some Scene {
        WindowGroup {
            HeapView()
        }
        .modelContainer(for: [NoteStack.self, NotePage.self])
    }
}
