import CoreLocation
import Foundation

enum LocationError: Error {
    case denied
    case failed
}

/// One-shot location, asked only from the Nearby screen and only while in use.
/// A fix younger than 2 min is reused; a request gives up after 10 s. The position never leaves the watch.
@MainActor
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    static let shared = LocationProvider()

    private let manager = CLLocationManager()
    private var lastFix: CLLocation?
    private var authWaiters: [CheckedContinuation<Void, Never>] = []
    private var fixWaiters: [CheckedContinuation<CLLocation?, Never>] = []
    private var request = 0

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var isDenied: Bool {
        let s = manager.authorizationStatus
        return s == .denied || s == .restricted
    }

    func currentLocation() async throws -> CLLocation {
        if let f = lastFix, -f.timestamp.timeIntervalSinceNow < 120 { return f }

        if manager.authorizationStatus == .notDetermined {
            await withCheckedContinuation { c in
                authWaiters.append(c)
                manager.requestWhenInUseAuthorization()
            }
        }
        guard !isDenied else { throw LocationError.denied }

        let fix: CLLocation? = await withCheckedContinuation { c in
            fixWaiters.append(c)
            guard fixWaiters.count == 1 else { return }
            request += 1
            let id = request
            manager.requestLocation()
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                guard let self, self.request == id else { return }
                self.finish(nil)
            }
        }
        guard let fix else { throw isDenied ? LocationError.denied : LocationError.failed }
        lastFix = fix
        return fix
    }

    private func finish(_ fix: CLLocation?) {
        let waiters = fixWaiters
        fixWaiters = []
        request += 1
        if fix == nil && !waiters.isEmpty { manager.stopUpdatingLocation() }
        waiters.forEach { $0.resume(returning: fix) }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard status != .notDetermined else { return }
            let w = self.authWaiters
            self.authWaiters = []
            w.forEach { $0.resume() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let fix = locations.last
        Task { @MainActor in self.finish(fix) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finish(nil) }
    }
}
