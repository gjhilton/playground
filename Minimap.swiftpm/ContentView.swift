import SwiftUI
import MapKit
import CoreLocation

// MARK: - Main View

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var geocoder = AddressGeocoder()
    
    var body: some View {
        ZStack {
            if let userLocation = locationManager.location {
                MapWithLiveMarkersView(
                    userLocation: userLocation.coordinate,
                    pinLocation: geocoder.pinCoordinate
                )
                .edgesIgnoringSafeArea(.all)
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

// MARK: - Map View with Red Dot and SF Symbol Cross

struct MapWithLiveMarkersView: UIViewRepresentable {
    let userLocation: CLLocationCoordinate2D
    let pinLocation: CLLocationCoordinate2D?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(userLocation: userLocation, pinLocation: pinLocation)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        if #available(iOS 13.0, *) {
            mapView.overrideUserInterfaceStyle = .light
        }
        
        let config = MKStandardMapConfiguration(elevationStyle: .flat)
        config.pointOfInterestFilter = .excludingAll
        mapView.preferredConfiguration = config
        
        mapView.delegate = context.coordinator
        context.coordinator.mapView = mapView
        
        mapView.showsUserLocation = false
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        
        // Red dot for user location
        let userDot = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
        userDot.backgroundColor = .red
        userDot.layer.cornerRadius = 6
        userDot.layer.borderColor = UIColor.white.cgColor
        userDot.layer.borderWidth = 2
        userDot.layer.masksToBounds = true
        userDot.isUserInteractionEnabled = false
        userDot.tag = 1002
        mapView.addSubview(userDot)
        context.coordinator.userDotView = userDot
        
        // SF Symbol "xmark" for pin location
        let crossImageView = UIImageView()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        crossImageView.image = UIImage(systemName: "xmark", withConfiguration: symbolConfig)
        crossImageView.tintColor = .red
        crossImageView.frame.size = CGSize(width: 20, height: 20)
        crossImageView.isUserInteractionEnabled = false
        crossImageView.tag = 1003
        mapView.addSubview(crossImageView)
        context.coordinator.crossImageView = crossImageView
        
        // Initial zoom
        if let pinCoord = pinLocation {
            let userPoint = MKMapPoint(userLocation)
            let pinPoint = MKMapPoint(pinCoord)
            
            let rect = MKMapRect(
                origin: MKMapPoint(x: min(userPoint.x, pinPoint.x),
                                   y: min(userPoint.y, pinPoint.y)),
                size: MKMapSize(width: abs(userPoint.x - pinPoint.x),
                                height: abs(userPoint.y - pinPoint.y))
            )
            
            let paddedRect = rect.insetBy(dx: -rect.size.width * 0.3,
                                          dy: -rect.size.height * 0.3)
            mapView.setVisibleMapRect(paddedRect, animated: false)
        } else {
            let region = MKCoordinateRegion(center: userLocation,
                                            latitudinalMeters: 200,
                                            longitudinalMeters: 200)
            mapView.setRegion(region, animated: false)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.userLocation = userLocation
        context.coordinator.pinLocation = pinLocation
        context.coordinator.updateDotPositions()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        weak var mapView: MKMapView?
        weak var userDotView: UIView?
        weak var crossImageView: UIImageView?
        
        var userLocation: CLLocationCoordinate2D
        var pinLocation: CLLocationCoordinate2D?
        
        var displayLink: CADisplayLink?
        
        init(userLocation: CLLocationCoordinate2D, pinLocation: CLLocationCoordinate2D?) {
            self.userLocation = userLocation
            self.pinLocation = pinLocation
        }
        
        func startUpdating() {
            stopUpdating()
            displayLink = CADisplayLink(target: self, selector: #selector(updateLoop))
            displayLink?.add(to: .main, forMode: .common)
        }
        
        func stopUpdating() {
            displayLink?.invalidate()
            displayLink = nil
        }
        
        @objc func updateLoop() {
            updateDotPositions()
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            startUpdating()
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            stopUpdating()
            updateDotPositions()
        }
        
        func updateDotPositions() {
            guard let mapView else { return }
            
            if let userDotView {
                let point = mapView.convert(userLocation, toPointTo: mapView)
                userDotView.center = point
            }
            
            if let crossImageView, let pin = pinLocation {
                let point = mapView.convert(pin, toPointTo: mapView)
                crossImageView.center = point
            }
        }
    }
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
        print("Location error: \(error)")
    }
}

// MARK: - Geocoder

class AddressGeocoder: NSObject, ObservableObject {
    @Published var pinCoordinate: CLLocationCoordinate2D?
    
    func geocode(address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let location = placemarks?.first?.location {
                DispatchQueue.main.async {
                    self.pinCoordinate = location.coordinate
                }
            } else if let error = error {
                print("Geocode error: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
