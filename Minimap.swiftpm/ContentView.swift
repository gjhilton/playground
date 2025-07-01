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
                .saturation(0) // <-- Makes the map grayscale (black & white)
                .onAppear {
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

// MARK: - MapView with Pin and Auto Zoom/Pan

struct CleanMapView: UIViewRepresentable {
    let centerCoordinate: CLLocationCoordinate2D
    let pinCoordinate: CLLocationCoordinate2D?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        let config = MKStandardMapConfiguration(elevationStyle: .flat)
        config.pointOfInterestFilter = .excludingAll
        mapView.preferredConfiguration = config
        
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        
        // Start with user location zoomed in
        let region = MKCoordinateRegion(center: centerCoordinate,
                                        latitudinalMeters: 200,
                                        longitudinalMeters: 200)
        mapView.setRegion(region, animated: false)
        
        // Add pin if available
        if let pinCoord = pinCoordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = pinCoord
            annotation.title = "24-30 Pier Road"
            mapView.addAnnotation(annotation)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Remove all annotations except user location
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        // Add pin annotation if we have it
        if let pinCoord = pinCoordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = pinCoord
            annotation.title = "24-30 Pier Road"
            mapView.addAnnotation(annotation)
        }
        
        // If we have both user location and pin, zoom to fit both
        if let pinCoord = pinCoordinate {
            let userPoint = MKMapPoint(centerCoordinate)
            let pinPoint = MKMapPoint(pinCoord)
            
            let rect = MKMapRect(
                origin: MKMapPoint(x: min(userPoint.x, pinPoint.x), y: min(userPoint.y, pinPoint.y)),
                size: MKMapSize(width: abs(userPoint.x - pinPoint.x), height: abs(userPoint.y - pinPoint.y))
            )
            
            // Add padding (~30%)
            let paddedRect = rect.insetBy(dx: -rect.size.width * 0.3, dy: -rect.size.height * 0.3)
            
            mapView.setVisibleMapRect(paddedRect, animated: true)
        } else {
            // Only user location — zoom in around it
            let region = MKCoordinateRegion(center: centerCoordinate,
                                            latitudinalMeters: 200,
                                            longitudinalMeters: 200)
            mapView.setRegion(region, animated: true)
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
