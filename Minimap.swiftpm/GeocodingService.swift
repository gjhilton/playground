import Foundation
import CoreLocation
import Combine

// MARK: - Geocoding Service

final class GeocodingService: ObservableObject {
    private let geocoder = CLGeocoder()
    
    @Published var isGeocoding = false
    @Published var error: GeocodingError?
    
    enum GeocodingError: LocalizedError {
        case noResults
        case networkError(Error)
        case cancelled
        
        var errorDescription: String? {
            switch self {
            case .noResults:
                return "No location found for the given address."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .cancelled:
                return "Geocoding was cancelled."
            }
        }
    }
    
    func geocodeAddress(_ address: String) async -> CLLocationCoordinate2D? {
        DispatchQueue.main.async {
            self.isGeocoding = true
            self.error = nil
        }
        
        defer { 
            DispatchQueue.main.async {
                self.isGeocoding = false
            }
        }
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            
            guard let location = placemarks.first?.location else {
                DispatchQueue.main.async {
                    self.error = .noResults
                }
                return nil
            }
            
            return location.coordinate
        } catch let error as CLError {
            DispatchQueue.main.async {
                switch error.code {
                case .geocodeFoundNoResult:
                    self.error = .noResults
                case .network:
                    self.error = .networkError(error)
                case .geocodeCanceled:
                    self.error = .cancelled
                default:
                    self.error = .networkError(error)
                }
            }
            return nil
        } catch {
            DispatchQueue.main.async {
                self.error = .networkError(error)
            }
            return nil
        }
    }
    
    func cancelGeocoding() {
        geocoder.cancelGeocode()
        DispatchQueue.main.async {
            self.isGeocoding = false
            self.error = .cancelled
        }
    }
} 