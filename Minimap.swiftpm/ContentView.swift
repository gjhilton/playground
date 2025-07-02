import SwiftUI
import MapKit
import CoreLocation

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion()
    @State private var hasSetInitialRegion = false
    
    private let pinCoordinate = CLLocationCoordinate2D(latitude: 54.4885, longitude: -0.6152)
    
    var body: some View {
        ZStack {
            if let userLoc = locationManager.location?.coordinate {
                MapView(region: $region)
                    .saturation(0) // grayscale map
                    .edgesIgnoringSafeArea(.all)
                
                MapOverlays(pinCoordinate: pinCoordinate, userCoordinate: userLoc, region: region)
                    .allowsHitTesting(false)
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            region = MKCoordinateRegion.regionCovering(coordinates: [userLoc, pinCoordinate])
                            hasSetInitialRegion = true
                        }) {
                            Label("Re-center", systemImage: "location.north.line")
                                .padding(10)
                                .background(Color.white.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding()
                    }
                }
            } else {
                LoadingView()
            }
        }
        .onChange(of: locationManager.location) { _ in
            if !hasSetInitialRegion, let userLoc = locationManager.location?.coordinate {
                region = MKCoordinateRegion.regionCovering(coordinates: [userLoc, pinCoordinate])
                hasSetInitialRegion = true
            }
        }
    }
}

// MARK: - MapViewRepresentable

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        if #available(iOS 13.0, *) {
            let config = MKStandardMapConfiguration(elevationStyle: .flat)
            config.pointOfInterestFilter = .excludingAll
            mapView.preferredConfiguration = config
            mapView.overrideUserInterfaceStyle = .light
        }
        
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.setRegion(region, animated: false)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        if !mapView.region.center.isApproximatelyEqual(to: region.center) ||
            !mapView.region.span.isApproximatelyEqual(to: region.span) {
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
    }
}

// MARK: - Overlays View

struct MapOverlays: View {
    let pinCoordinate: CLLocationCoordinate2D
    let userCoordinate: CLLocationCoordinate2D
    let region: MKCoordinateRegion
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                PinView()
                    .position(geo.convertCoordinateToPoint(pinCoordinate, region: region))
                
                UserLocationView()
                    .position(geo.convertCoordinateToPoint(userCoordinate, region: region))
            }
        }
    }
}

struct PinView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red)
                .frame(width: 30, height: 30)
            
            Image(systemName: "mappin")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.white)
        }
    }
}

struct UserLocationView: View {
    var body: some View {
        Circle()
            .fill(Color.red.opacity(0.2))
            .frame(width: 30, height: 30)
            .overlay(
                Circle()
                    .stroke(Color.red, lineWidth: 6)
            )
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Waiting for location…")
        }
        .padding()
    }
}

// MARK: - Helpers

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

extension MKCoordinateRegion {
    static func regionCovering(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
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

// MARK: - LocationManager

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
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
        guard let loc = locations.last else { return }
        DispatchQueue.main.async {
            self.location = loc
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
