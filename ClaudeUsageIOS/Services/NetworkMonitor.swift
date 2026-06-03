import Foundation
import Network

final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.claudeusage.ios.networkmonitor")

    private(set) var isConnected: Bool = false

    var onNetworkAvailable: (() -> Void)?

    private init() {
        monitor = NWPathMonitor()
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let wasConnected = self.isConnected
            let nowConnected = path.status == .satisfied
            self.isConnected = nowConnected
            if nowConnected && !wasConnected {
                DispatchQueue.main.async { self.onNetworkAvailable?() }
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }
}
