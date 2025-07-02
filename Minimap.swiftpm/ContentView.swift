import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var geocoder = AddressGeocoder()
    
    // To hold current region from the map
    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    
    var body: some View {
        ZStack {
            if let userLocation = locationManager.location {
                MapWrapperView(
                    userCoordinate: userLocation.coordinate,
                    pinCoordinate: geocoder.pinCoordinate,
                    region: $region
                )
                .saturation(0)  // <-- grayscale the map view
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    geocoder.geocode(address: "24-30 Pier Road, Whitby, England YO21 3PU, GB")
                }
                
                GeometryReader { geo in
                    // Overlay red markers on top of the map (not affected by saturation)
                    ZStack {
                        if let pin = geocoder.pinCoordinate {
                            RedXMark()
                                .position(geo.convertCoordinateToPoint(pin, region: region))
                        }
                        
                        RedDot()
                            .position(geo.convertCoordinateToPoint(userLocation.coordinate, region: region))
                    }
                    .allowsHitTesting(false) // So touches go through to the map
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

// MARK: - Map UIViewRepresentable wrapper

struct MapWrapperView: UIViewRepresentable {
    let userCoordinate: CLLocationCoordinate2D
    let pinCoordinate: CLLocationCoordinate2D?
    @Binding var region: MKCoordinateRegion
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        if #available(iOS 13.0, *) {
            mapView.overrideUserInterfaceStyle = .light
        }
        
        let config = MKStandardMapConfiguration(elevationStyle: .flat)
        config.pointOfInterestFilter = .excludingAll
        mapView.preferredConfiguration = config
        
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        
        // Initial region zoom to user and pin
        if let pin = pinCoordinate {
            let userPoint = MKMapPoint(userCoordinate)
            let pinPoint = MKMapPoint(pin)
            
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
            let region = MKCoordinateRegion(center: userCoordinate, latitudinalMeters: 200, longitudinalMeters: 200)
            mapView.setRegion(region, animated: false)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Keep region binding in sync with map view’s region
        if mapView.region.center.latitude != region.center.latitude ||
            mapView.region.center.longitude != region.center.longitude {
            region = mapView.region
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapWrapperView
        init(parent: MapWrapperView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
    }
}

// MARK: - Red markers as SwiftUI views

struct RedDot: View {
    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 12, height: 12)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(radius: 2)
    }
}

struct RedXMark: View {
    var body: some View {
        Image(systemName: "xmark")
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundColor(.red)
            .shadow(radius: 2)
    }
}

// MARK: - Helper for coordinate-to-point conversion

extension GeometryProxy {
    func convertCoordinateToPoint(_ coordinate: CLLocationCoordinate2D, region: MKCoordinateRegion) -> CGPoint {
        let mapWidth = size.width
        let mapHeight = size.height
        
        let centerLat = region.center.latitude
        let centerLon = region.center.longitude
        
        // Calculate how many degrees per point on the screen
        let latDelta = region.span.latitudeDelta
        let lonDelta = region.span.longitudeDelta
        
        // Convert coordinate to relative x,y between 0 and 1
        let x = (coordinate.longitude - (centerLon - lonDelta/2)) / lonDelta
        let y = 1 - ((coordinate.latitude - (centerLat - latDelta/2)) / latDelta)
        
        // Clamp to view bounds just in case
        let clampedX = min(max(0, x), 1)
        let clampedY = min(max(0, y), 1)
        
        return CGPoint(x: clampedX * mapWidth, y: clampedY * mapHeight)
    }
}

// MARK: - Location manager and geocoder (same as before)

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
}

class AddressGeocoder: NSObject, ObservableObject {
    @Published var pinCoordinate: CLLocationCoordinate2D?
    
    func geocode(address: String) {
        let geo = CLGeocoder()
        geo.geocodeAddressString(address) { places, error in
            if let loc = places?.first?.location {
                DispatchQueue.main.async {
                    self.pinCoordinate = loc.coordinate
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
