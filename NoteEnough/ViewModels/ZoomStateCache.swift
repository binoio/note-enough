import Foundation

struct ZoomState {
    var zoomScale: CGFloat
    var contentOffset: CGPoint
}

@MainActor
final class ZoomStateCache {
    static let shared = ZoomStateCache()

    private var cache: [UUID: ZoomState] = [:]

    private init() {}

    func save(pageID: UUID, zoomScale: CGFloat, contentOffset: CGPoint) {
        cache[pageID] = ZoomState(zoomScale: zoomScale, contentOffset: contentOffset)
    }

    func state(for pageID: UUID) -> ZoomState? {
        cache[pageID]
    }
}
