import Foundation
import WatchConnectivity
import WidgetKit

/// Receives the favourites from the phone (application context, key `json`). The payload is untrusted:
/// it is validated and, on any failure, the previous favourites stay.
final class PhoneLink: NSObject, WCSessionDelegate {
    private let onChange: @Sendable (FavsPayload) -> Void
    private let store = SharedStore.shared

    init(onChange: @escaping @Sendable (FavsPayload) -> Void) {
        self.onChange = onChange
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        s.delegate = self
        s.activate()
    }

    private func handle(_ context: [String: Any]) {
        guard let json = context["json"] as? String,
              let payload = FavsPayloadValidator.validate(json) else { return }
        if store.saveFavs(payload) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        onChange(payload)
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        guard state == .activated else { return }
        handle(session.receivedApplicationContext)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handle(applicationContext)
    }
}
