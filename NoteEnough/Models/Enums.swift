import Foundation

enum PaperType: String, Codable, CaseIterable, Identifiable {
    case plain
    case textured
    case graph

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .plain: "Plain"
        case .textured: "Textured"
        case .graph: "Graph"
        }
    }
}

enum PaperSize: String, Codable, CaseIterable, Identifiable {
    case usLetter
    case a4

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .usLetter: "US Letter"
        case .a4: "A4"
        }
    }

    /// Returns size in points (72 points per inch)
    var pointSize: CGSize {
        switch self {
        case .usLetter: CGSize(width: 612, height: 792)   // 8.5 × 11 in
        case .a4: CGSize(width: 595, height: 842)          // 210 × 297 mm
        }
    }
}

enum PageOrientation: String, Codable, CaseIterable, Identifiable {
    case portrait
    case landscape

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .portrait: "Portrait"
        case .landscape: "Landscape"
        }
    }
}

enum NavigationDirection: String, Codable, CaseIterable, Identifiable {
    case leftRight
    case upDown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .leftRight: "Left / Right"
        case .upDown: "Up / Down"
        }
    }
}
