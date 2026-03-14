import Foundation
import Combine

@Observable
final class MetricsService {
    var currentMetrics: AudioMetrics = .empty

    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 1.0 / 30.0  // 30 Hz

    func startMonitoring(perturbationService: PerturbationService) {
        perturbationService.onMetricsUpdate = { [weak self] metrics in
            self?.currentMetrics = metrics
        }
    }

    func stopMonitoring() {
        currentMetrics = .empty
    }
}
