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
                MapWithLiveRedDotView(
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

// MARK: - Map View with CADisplayLink Tracking

struct MapWithLiveRedDotView: UIViewRepresentable {
    let userLocation: CLLocationCoordinate2D
    let pinLocation: CLLocationCoordinate2D?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(pinLocation: pinLocation)
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
        
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        
        // Add red dot view
        let dotView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
        dotView.backgroundColor = .red
        dotView.layer.cornerRadius = 6
        dotView.layer.masksToBounds = true
        dotView.isUserInteractionEnabled = false
        dotView.tag = 9999
        mapView.addSubview(dotView)
        context.coordinator.redDotView = dotView
        
        // Initial region
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
        context.coordinator.pinLocation = pinLocation
        context.coordinator.updateRedDotPosition()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        weak var mapView: MKMapView?
        weak var redDotView: UIView?
        var pinLocation: CLLocationCoordinate2D?
        var displayLink: CADisplayLink?
        
        init(pinLocation: CLLocationCoordinate2D?) {
            self.pinLocation = pinLocation
        }
        
        func startUpdating() {
            stopUpdating() // prevent duplicates
            displayLink = CADisplayLink(target: self, selector: #selector(updateLoop))
            displayLink?.add(to: .main, forMode: .common)
        }
        
        func stopUpdating() {
            displayLink?.invalidate()
            displayLink = nil
        }
        
        @objc func updateLoop() {
            updateRedDotPosition()
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            startUpdating()
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            stopUpdating()
            updateRedDotPosition()
        }
        
        func updateRedDotPosition() {
            guard let mapView, let redDotView, let pinLocation else { return }
            let point = mapView.convert(pinLocation, toPointTo: mapView)
            redDotView.center = point
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

// MARK: - Preview (Optional)

#Preview {
    ContentView()
}
