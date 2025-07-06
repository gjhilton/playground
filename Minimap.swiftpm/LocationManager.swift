import Foundation
import CoreLocation
import Combine

// MARK: - Location Manager Service

final class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: LocationError?
    
    enum LocationError: LocalizedError {
        case denied
        case restricted
        case unavailable
        case unknown(Error)
        
        var errorDescription: String? {
            switch self {
            case .denied:
                return "Location access denied. Please enable in Settings."
            case .restricted:
                return "Location access is restricted."
            case .unavailable:
                return "Location services are unavailable."
            case .unknown(let error):
                return "Location error: \(error.localizedDescription)"
            }
        }
    }
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // Update every 10 meters
    }
    
    func requestLocationPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            error = .denied
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        @unknown default:
            error = .unknown(NSError(domain: "LocationManager", code: -1))
        }
    }
    
    func startUpdatingLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            error = .unavailable
            return
        }
        
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out old locations
        let timeInterval = Date().timeIntervalSince(location.timestamp)
        guard timeInterval < 15.0 else { return }
        
        DispatchQueue.main.async {
            self.location = location
            self.error = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.error = .unknown(error)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.startUpdatingLocation()
            case .denied, .restricted:
                self.error = .denied
            case .notDetermined:
                break
            @unknown default:
                self.error = .unknown(NSError(domain: "LocationManager", code: -1))
            }
        }
    }
} 