import Foundation
import CoreLocation
import MapKit
import Combine

// MARK: - Map View Model

@MainActor
final class MapViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var region: MKCoordinateRegion?
    @Published var pinCoordinate: CLLocationCoordinate2D?
    @Published var pinPoint: CGPoint?
    @Published var userPoint: CGPoint?
    @Published var hasSetInitialRegion = false
    @Published var isLoading = false
    
    // MARK: - Services
    
    private let locationManager: LocationManager
    private let geocodingService: GeocodingService
    
    // MARK: - Configuration
    
    private let targetAddress: String
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        targetAddress: String = "30 Pier Road, Whitby, England YO21 3PU, GB",
        locationManager: LocationManager = LocationManager(),
        geocodingService: GeocodingService = GeocodingService()
    ) {
        self.targetAddress = targetAddress
        self.locationManager = locationManager
        self.geocodingService = geocodingService
        
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Monitor location changes
        locationManager.$location
            .compactMap { $0?.coordinate }
            .sink { [weak self] _ in
                self?.updateRegionIfNeeded()
            }
            .store(in: &cancellables)
        
        // Monitor pin coordinate changes
        $pinCoordinate
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.updateRegionIfNeeded()
            }
            .store(in: &cancellables)
        
        // Monitor geocoding errors
        geocodingService.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                print("Geocoding error: \(error.localizedDescription)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func initialize() async {
        isLoading = true
        defer { isLoading = false }
        
        // Request location permission and start geocoding
        locationManager.requestLocationPermission()
        await geocodeTargetAddress()
    }
    
    func recenterMap() {
        updateRegion()
    }
    
    func updateOverlayPoints(pinPoint: CGPoint?, userPoint: CGPoint?) {
        self.pinPoint = pinPoint
        self.userPoint = userPoint
    }
    
    // MARK: - Private Methods
    
    private func geocodeTargetAddress() async {
        pinCoordinate = await geocodingService.geocodeAddress(targetAddress)
    }
    
    private func updateRegionIfNeeded() {
        guard
            let userLocation = locationManager.location?.coordinate,
            let pinCoord = pinCoordinate,
            !hasSetInitialRegion
        else { return }
        
        region = MKCoordinateRegion.regionCovering(coordinates: [userLocation, pinCoord])
        hasSetInitialRegion = true
    }
    
    private func updateRegion() {
        guard 
            let userLocation = locationManager.location?.coordinate,
            let pinCoord = pinCoordinate 
        else { return }
        
        region = MKCoordinateRegion.regionCovering(coordinates: [userLocation, pinCoord])
    }
}

// MARK: - Computed Properties

extension MapViewModel {
    var isReady: Bool {
        locationManager.location != nil && pinCoordinate != nil && region != nil
    }
    
    var userCoordinate: CLLocationCoordinate2D? {
        locationManager.location?.coordinate
    }
    
    var locationError: LocationManager.LocationError? {
        locationManager.error
    }
    
    var geocodingError: GeocodingService.GeocodingError? {
        geocodingService.error
    }
} 