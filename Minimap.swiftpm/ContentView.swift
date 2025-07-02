import SwiftUI
import MapKit
import CoreLocation

// MARK: - ContentView

struct ContentView: View {
    var body: some View {
        LocationMap()
    }
}

// MARK: - LocationMap View

struct LocationMap: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region: MKCoordinateRegion?
    @State private var pinCoordinate: CLLocationCoordinate2D?
    @State private var hasSetInitialRegion = false
    
    // Points in the MKMapView's coordinate space for overlay placement
    @State private var pinPoint: CGPoint?
    @State private var userPoint: CGPoint?
    
    private let address = "30 Pier Road, Whitby, England YO21 3PU, GB"
    
    var body: some View {
        ZStack {
            if let userLocation = locationManager.location?.coordinate,
               let pinCoord = pinCoordinate,
               let region = region {
                
                MapView(
                    region: Binding(
                        get: { region },
                        set: { newRegion in
                            self.region = newRegion
                        }
                    ),
                    pinCoordinate: pinCoord,
                    userCoordinate: userLocation,
                    pinPoint: $pinPoint,
                    userPoint: $userPoint
                )
                .saturation(0)
                .edgesIgnoringSafeArea(.all)
                
                GeometryReader { geo in
                    ZStack {
                        if let pinPoint = pinPoint {
                            PinView()
                                .position(x: pinPoint.x, y: pinPoint.y)
                        }
                        if let userPoint = userPoint {
                            UserLocationView()
                                .position(x: userPoint.x, y: userPoint.y)
                        }
                    }
                }
            } else {
                LoadingView()
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: updateRegion) {
                        Text("Re-center")
                            .padding(10)
                            .background(Color.white.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            geocodeAddress()
        }
        .onChange(of: locationManager.location) { _ in
            updateRegionIfNeeded()
        }
        .onChange(of: pinCoordinate) { _ in
            updateRegionIfNeeded()
        }
    }
    
    private func geocodeAddress() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            if let location = placemarks?.first?.location {
                DispatchQueue.main.async {
                    pinCoordinate = location.coordinate
                }
            }
        }
    }
    
    private func updateRegionIfNeeded() {
        guard
            let userLoc = locationManager.location?.coordinate,
            let pinCoord = pinCoordinate,
            !hasSetInitialRegion
        else { return }
        
        region = MKCoordinateRegion.regionCovering(coordinates: [userLoc, pinCoord])
        hasSetInitialRegion = true
    }
    
    private func updateRegion() {
        guard let userLoc = locationManager.location?.coordinate,
              let pinCoord = pinCoordinate else { return }
        region = MKCoordinateRegion.regionCovering(coordinates: [userLoc, pinCoord])
    }
}

// MARK: - MapViewRepresentable with overlay point calculation

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    
    let pinCoordinate: CLLocationCoordinate2D
    let userCoordinate: CLLocationCoordinate2D
    
    @Binding var pinPoint: CGPoint?
    @Binding var userPoint: CGPoint?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        context.coordinator.mapView = mapView
        
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.setRegion(region, animated: false)
        
        if #available(iOS 13.0, *) {
            let config = MKStandardMapConfiguration(elevationStyle: .flat)
            config.pointOfInterestFilter = .excludingAll
            mapView.preferredConfiguration = config
            mapView.overrideUserInterfaceStyle = .light
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        if !mapView.region.center.isApproximatelyEqual(to: region.center) ||
            !mapView.region.span.isApproximatelyEqual(to: region.span) {
            mapView.setRegion(region, animated: true)
        }
        // Calculate overlay points whenever UIView updates
        updateOverlayPoints(mapView: mapView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func updateOverlayPoints(mapView: MKMapView) {
        DispatchQueue.main.async {
            pinPoint = mapView.convert(pinCoordinate, toPointTo: mapView)
            userPoint = mapView.convert(userCoordinate, toPointTo: mapView)
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        weak var mapView: MKMapView?
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
                self.parent.updateOverlayPoints(mapView: mapView)
            }
        }
    }
}

// MARK: - Overlay Views

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
