import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region: MKCoordinateRegion?
    @State private var pinCoordinate: CLLocationCoordinate2D?
    @State private var hasSetInitialRegion = false
    
    var body: some View {
        ZStack {
            if let userLocation = locationManager.location?.coordinate,
               let pinCoordinate = pinCoordinate,
               let bindingRegion = Binding($region) {
                
                // Pass pin and user coords + region binding
                MapView(region: bindingRegion,
                        pinCoordinate: pinCoordinate,
                        userCoordinate: userLocation)
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button("Re-center") {
                            updateRegion()
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding()
                    }
                }
            } else {
                LoadingView()
            }
        }
        .onAppear {
            geocodeAddress("30 Pier Road, Whitby, England YO21 3PU, GB")
        }
        .onChange(of: locationManager.location?.coordinate) { _ in
            updateRegionIfNeeded()
        }
    }
    
    private func geocodeAddress(_ address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let coordinate = placemarks?.first?.location?.coordinate {
                pinCoordinate = coordinate
                updateRegionIfNeeded()
            }
        }
    }
    
    private func updateRegionIfNeeded() {
        guard let userLoc = locationManager.location?.coordinate,
              let pinCoord = pinCoordinate else { return }
        if !hasSetInitialRegion {
            region = MKCoordinateRegion.regionCovering(coordinates: [userLoc, pinCoord])
            hasSetInitialRegion = true
        }
    }
    
    private func updateRegion() {
        guard let userLoc = locationManager.location?.coordinate,
              let pinCoord = pinCoordinate else { return }
        region = MKCoordinateRegion.regionCovering(coordinates: [userLoc, pinCoord])
    }
}

// MARK: - MapViewRepresentable with overlay views that track rotation

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let pinCoordinate: CLLocationCoordinate2D
    let userCoordinate: CLLocationCoordinate2D
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
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
        
        // Add overlay container view for SwiftUI overlays
        context.coordinator.setupOverlayViews(on: mapView)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region if needed
        if !mapView.region.center.isApproximatelyEqual(to: region.center) ||
            !mapView.region.span.isApproximatelyEqual(to: region.span) {
            mapView.setRegion(region, animated: true)
        }
        
        // Update overlay positions for pin and user location
        context.coordinator.updateOverlayPositions()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        private var pinViewHosting: UIHostingController<PinView>?
        private var userViewHosting: UIHostingController<UserLocationView>?
        private weak var mapView: MKMapView?
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func setupOverlayViews(on mapView: MKMapView) {
            self.mapView = mapView
            
            // Create SwiftUI views hosted inside UIKit views
            let pinView = PinView()
            let userView = UserLocationView()
            
            let pinHosting = UIHostingController(rootView: pinView)
            let userHosting = UIHostingController(rootView: userView)
            
            // Make transparent backgrounds
            pinHosting.view.backgroundColor = .clear
            userHosting.view.backgroundColor = .clear
            
            // Add to mapView
            mapView.addSubview(pinHosting.view)
            mapView.addSubview(userHosting.view)
            
            pinHosting.view.frame.size = CGSize(width: 30, height: 30)
            userHosting.view.frame.size = CGSize(width: 30, height: 30)
            
            self.pinViewHosting = pinHosting
            self.userViewHosting = userHosting
            
            updateOverlayPositions()
        }
        
        func updateOverlayPositions() {
            guard let mapView = mapView else { return }
            
            // Convert coordinates to points in the mapView's coordinate system
            let pinPoint = mapView.convert(parent.pinCoordinate, toPointTo: mapView)
            let userPoint = mapView.convert(parent.userCoordinate, toPointTo: mapView)
            
            // Check if points are inside mapView.bounds before showing
            if mapView.bounds.contains(pinPoint) {
                pinViewHosting?.view.isHidden = false
                pinViewHosting?.view.center = pinPoint
            } else {
                pinViewHosting?.view.isHidden = true
            }
            
            if mapView.bounds.contains(userPoint) {
                userViewHosting?.view.isHidden = false
                userViewHosting?.view.center = userPoint
            } else {
                userViewHosting?.view.isHidden = true
            }
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            // Update binding region in SwiftUI
            DispatchQueue.main.async {
                self.parent.region = mapView.region
                self.updateOverlayPositions()
            }
        }
    }
}

// MARK: - Pin and User views (SwiftUI)

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

// MARK: - Extensions & Helpers

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
