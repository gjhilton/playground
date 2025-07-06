import Foundation
import CoreLocation
import MapKit

// MARK: - Location Models

struct MapLocation: Identifiable, Equatable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let type: LocationType
    
    enum LocationType {
        case pin
        case user
    }
}

// MARK: - Coordinate Extensions

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension CLLocationCoordinate2D {
    func isApproximatelyEqual(to other: CLLocationCoordinate2D, epsilon: Double = 0.000001) -> Bool {
        abs(latitude - other.latitude) < epsilon && abs(longitude - other.longitude) < epsilon
    }
}

extension MKCoordinateSpan {
    func isApproximatelyEqual(to other: MKCoordinateSpan, epsilon: Double = 0.000001) -> Bool {
        abs(latitudeDelta - other.latitudeDelta) < epsilon && abs(longitudeDelta - other.longitudeDelta) < epsilon
    }
}

// MARK: - Region Utilities

extension MKCoordinateRegion {
    static func regionCovering(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else { return MKCoordinateRegion() }
        
        let lats = coordinates.map { $0.latitude }
        let lons = coordinates.map { $0.longitude }
        
        let minLat = lats.min()!
        let maxLat = lats.max()!
        let minLon = lons.min()!
        let maxLon = lons.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
} 