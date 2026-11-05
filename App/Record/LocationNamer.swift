import CoreLocation
import MapKit
import Observation

@MainActor @Observable
final class LocationNamer {
    private(set) var place = Demo.fixture?.place
    @ObservationIgnored private var updates: Task<Void, Never>?
    @ObservationIgnored private var geocoded: CLLocation?

    func setEnabled(_ enabled: Bool) {
        guard enabled != (updates != nil) else { return }
        updates?.cancel()
        updates = nil
        place = nil
        guard enabled else { return }
        CLLocationManager().requestWhenInUseAuthorization()
        updates = Task {
            do {
                for try await update in CLLocationUpdate.liveUpdates(.otherNavigation) {
                    guard let location = update.location else { continue }
                    if let geocoded, location.distance(from: geocoded) < 50 { continue }
                    geocoded = location
                    let item = try? await MKReverseGeocodingRequest(location: location)?.mapItems.first
                    place = (item?.address?.shortAddress ?? item?.name)?.split(separator: ",").first.map(String.init)
                }
            } catch {
                place = nil
            }
        }
    }
}
