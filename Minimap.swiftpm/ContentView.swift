import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var geocoder = AddressGeocoder()
    
    var body: some View {
        ZStack {
            if let userLocation = locationManager.location {
                CleanMapView(centerCoordinate: userLocation.coordinate,
                             pinCoordinate: geocoder.pinCoordinate)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    // Geocode the new address when view appears
                    geocoder.geocode(address: "24-30 Pier Road, Whitby, England YO21 3PU, GB")
                }
            } else {
                VStack {
                    ProgressView()
                    Text("Fetching location…")
                }
            }
        }
    }
}

// MARK: - MapView with Pin

struct CleanMapView: UIViewRepresentable {
    let centerCoordinate: CLLocationCoordinate2D
    let pinCoordinate: CLLocationCoordinate2D?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Use MKStandardMapConfiguration to hide landmarks
        let config = MKStandardMapConfiguration(elevationStyle: .flat)
        config.pointOfInterestFilter = .excludingAll
        mapView.preferredConfiguration = config
        
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        
        // Center map on user location at 200m radius
        let region = MKCoordinateRegion(center: centerCoordinate,
                                        latitudinalMeters: 200,
                                        longitudinalMeters: 200)
        mapView.setRegion(region, animated: false)
        
        // Add pin annotation if available
        if let pinCoord = pinCoordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = pinCoord
            annotation.title = "24-30 Pier Road"
            mapView.addAnnotation(annotation)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update the region to follow user location if needed
        let region = MKCoordinateRegion(center: centerCoordinate,
                                        latitudinalMeters: 200,
                                        longitudinalMeters: 200)
        mapView.setRegion(region, animated: true)
        
        // Remove old annotations except user location
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        if let pinCoord = pinCoordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = pinCoord
            annotation.title = "24-30 Pier Road"
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {}
}

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            DispatchQueue.main.async {
                self.location = loc
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error)")
    }
}

// MARK: - Geocoder

class AddressGeocoder: NSObject, ObservableObject {
    @Published var pinCoordinate: CLLocationCoordinate2D?
    
    func geocode(address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                print("Geocode failed: \(error.localizedDescription)")
                return
            }
            if let location = placemarks?.first?.location {
                DispatchQueue.main.async {
                    self.pinCoordinate = location.coordinate
                }
            }
        }
    }
}
