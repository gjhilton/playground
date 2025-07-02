import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 54.4885, longitude: -0.6152),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    let pinCoordinate = CLLocationCoordinate2D(latitude: 54.4885, longitude: -0.6152)
    
    var body: some View {
        ZStack {
            if let userLoc = locationManager.location?.coordinate {
                MapViewRepresentable(region: $region)
                    .saturation(0) // grayscale map only
                    .edgesIgnoringSafeArea(.all)
                
                GeometryReader { geo in
                    // Pin: white mappin on solid red circle
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 28, height: 28)
                        Image(systemName: "mappin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.white)
                    }
                    .position(geo.convertCoordinateToPoint(pinCoordinate, region: region))
                    
                    // User location: red circle with thick border and 80% transparent fill
                    Circle()
                        .fill(Color.red.opacity(0.8))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.red, lineWidth: 4)
                        )
                        .position(geo.convertCoordinateToPoint(userLoc, region: region))
                }
                .allowsHitTesting(false)
            } else {
                VStack {
                    ProgressView()
                    Text("Waiting for location…")
                }
            }
        }
        .onAppear {
            if let userLoc = locationManager.location?.coordinate {
                region = regionCovering(coordinates: [userLoc, pinCoordinate])
            }
        }
        .onChange(of: locationManager.location) { newLoc in
            guard let userLoc = newLoc?.coordinate else { return }
            region = regionCovering(coordinates: [userLoc, pinCoordinate])
        }
    }
}

// MARK: - MKMapView wrapper

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        if #available(iOS 13.0, *) {
            // Configure map to hide POIs but show streets
            let config = MKStandardMapConfiguration(elevationStyle: .flat)
            config.pointOfInterestFilter = .excludingAll
            mapView.preferredConfiguration = config
            
            // Force light mode map style
            mapView.overrideUserInterfaceStyle = .light
        }
        
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.setRegion(region, animated: false)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Avoid jitter updating if approx same
        if !mapView.region.center.isApproximatelyEqual(to: region.center) ||
            !mapView.region.span.isApproximatelyEqual(to: region.span) {
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
    }
}

// MARK: - Helper functions

func regionCovering(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
    guard !coordinates.isEmpty else {
        return MKCoordinateRegion()
    }
    
    let lats = coordinates.map { $0.latitude }
    let lons = coordinates.map { $0.longitude }
    
    let minLat = lats.min()!
    let maxLat = lats.max()!
    let minLon = lons.min()!
    let maxLon = lons.max()!
    
    let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                        longitude: (minLon + maxLon) / 2)
    
    let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.5,
                                longitudeDelta: (maxLon - minLon) * 1.5)
    
    return MKCoordinateRegion(center: center, span: span)
}

extension GeometryProxy {
    func convertCoordinateToPoint(_ coordinate: CLLocationCoordinate2D, region: MKCoordinateRegion) -> CGPoint {
        let mapWidth = size.width
        let mapHeight = size.height
        
        let centerLat = region.center.latitude
        let centerLon = region.center.longitude
        
        let latDelta = region.span.latitudeDelta
        let lonDelta = region.span.longitudeDelta
        
        let x = (coordinate.longitude - (centerLon - lonDelta / 2)) / lonDelta
        let y = 1 - ((coordinate.latitude - (centerLat - latDelta / 2)) / latDelta)
        
        let clampedX = min(max(0, x), 1)
        let clampedY = min(max(0, y), 1)
        
        return CGPoint(x: clampedX * mapWidth, y: clampedY * mapHeight)
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
}

#Preview {
    ContentView()
}
