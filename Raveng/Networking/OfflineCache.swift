import Foundation

/// Persistent cache + offline queue for outbound actions.
/// Lists are mirrored to disk so they render instantly on cold start,
/// even without network.
actor OfflineCache {
    static let shared = OfflineCache()

    private let root: URL
    init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.root = base.appendingPathComponent("FirmaCDC", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    private func url(for key: String) -> URL {
        root.appendingPathComponent(key + ".json")
    }

    func save<T: Encodable>(_ value: T, key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url(for: key), options: .atomic)
        } catch { /* ignore */ }
    }

    func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        let u = url(for: key)
        guard FileManager.default.fileExists(atPath: u.path),
              let data = try? Data(contentsOf: u) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func clear(_ key: String) {
        try? FileManager.default.removeItem(at: url(for: key))
    }

    // MARK: - Outbound queue (actions to retry when online)
    struct QueuedAction: Codable {
        let id: UUID
        let path: String
        let method: String
        let bodyJSON: String?
        let createdAt: Date
    }

    private var queueKey = "outbound_queue_v1"

    func enqueue(_ action: QueuedAction) async {
        var q: [QueuedAction] = load([QueuedAction].self, key: queueKey) ?? []
        q.append(action)
        save(q, key: queueKey)
    }

    func pendingActions() -> [QueuedAction] {
        load([QueuedAction].self, key: queueKey) ?? []
    }

    func remove(_ id: UUID) {
        var q: [QueuedAction] = load([QueuedAction].self, key: queueKey) ?? []
        q.removeAll { $0.id == id }
        save(q, key: queueKey)
    }
}

// MARK: - Network reachability (NWPathMonitor)
import Network
import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 12, weight: .bold))
            Text("Offline · dati in cache")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(BrandColor.warning, in: Capsule())
        .shadow(color: BrandColor.warning.opacity(0.4), radius: 10, x: 0, y: 5)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

@MainActor
final class Reachability: ObservableObject {
    static let shared = Reachability()

    @Published var isOnline: Bool = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "firmacdc.network")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
