import SwiftUI
import MapKit
import CoreLocation

// MARK: - Models

struct TourLocation: Equatable {
    let address: String
    var coordinate: CLLocationCoordinate2D?
    var title: String?
    var subtitle: String?
}

struct TourRoute {
    let coordinates: [CLLocationCoordinate2D]
    let distance: Double
    let duration: Double
}

// MARK: - Services

class GeocodingService {
    private let geocoder = CLGeocoder()
    private var cache: [String: CLLocationCoordinate2D] = [:]
    
    func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        if let cached = cache[address] {
            return cached
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let location = placemarks?.first?.location else {
                    continuation.resume(throwing: NSError(domain: "GeocodingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No location found for address"]))
                    return
                }
                
                self.cache[address] = location.coordinate
                continuation.resume(returning: location.coordinate)
            }
        }
    }
}

class DirectionsService {
    func getDirections(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async throws -> TourRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = .walking

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        guard let route = response.routes.first else {
            throw NSError(domain: "DirectionsError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No route found"])
        }
        let coordinates = route.polyline.coordinates
        let tourRoute = TourRoute(
            coordinates: coordinates,
            distance: route.distance,
            duration: route.expectedTravelTime
        )
        return tourRoute
    }
}

// MARK: - ViewModel

class TourViewModel: ObservableObject {
    @Published var locations: [TourLocation] = []
    @Published var routes: [TourRoute] = []
    @Published var isLoading = false
    @Published var errorMessages: [String] = []
    @Published var geocodingProgress: (current: Int, total: Int)?
    @Published var routingProgress: (current: Int, total: Int)?
    
    private let geocodingService = GeocodingService()
    private let directionsService = DirectionsService()
    
    func loadTour(addresses: [String]) {
        isLoading = true
        errorMessages.removeAll()
        
        Task {
            await loadTourAsync(addresses: addresses)
        }
    }
    
    @MainActor
    private func loadTourAsync(addresses: [String]) async {
        // Geocode addresses
        geocodingProgress = (0, addresses.count)
        var geocodedLocations: [TourLocation] = []
        var geocodingErrors: [String] = []
        
        for (index, address) in addresses.enumerated() {
            do {
                let coordinate = try await geocodingService.geocodeAddress(address)
                let location = TourLocation(
                    address: address,
                    coordinate: coordinate,
                    title: "Location \(index + 1)",
                    subtitle: address
                )
                geocodedLocations.append(location)
                geocodingProgress = (index + 1, addresses.count)
            } catch {
                geocodingErrors.append("Failed to geocode: \(address)")
            }
        }
        
        locations = geocodedLocations
        geocodingProgress = nil
        
        if !geocodingErrors.isEmpty {
            errorMessages.append(contentsOf: geocodingErrors)
        }
        
        // Get directions between consecutive locations
        if geocodedLocations.count > 1 {
            routingProgress = (0, geocodedLocations.count - 1)
            var tourRoutes: [TourRoute] = []
            var routingErrors: [String] = []
            
            for i in 0..<(geocodedLocations.count - 1) {
                guard let fromCoord = geocodedLocations[i].coordinate,
                      let toCoord = geocodedLocations[i + 1].coordinate else { continue }
                
                do {
                    let route = try await directionsService.getDirections(from: fromCoord, to: toCoord)
                    tourRoutes.append(route)
                    routingProgress = (i + 1, geocodedLocations.count - 1)
                } catch {
                    routingErrors.append("Failed to get route from \(geocodedLocations[i].title ?? "Location \(i + 1)") to \(geocodedLocations[i + 1].title ?? "Location \(i + 2)")")
                }
            }
            
            routes = tourRoutes
            routingProgress = nil
            
            if !routingErrors.isEmpty {
                errorMessages.append(contentsOf: routingErrors)
            }
        }
        
        isLoading = false
    }
    
    var hasValidData: Bool {
        return !locations.isEmpty && locations.allSatisfy { $0.coordinate != nil }
    }
}

// MARK: - MapView with UIViewRepresentable

struct TourMapView: UIViewRepresentable {
    @ObservedObject var viewModel: TourViewModel
    @Binding var region: MKCoordinateRegion
    @Binding var overlayPoints: [CGPoint]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        context.coordinator.mapView = mapView
        context.coordinator.parent = self
        
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
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
        context.coordinator.updateOverlayPoints()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TourMapView
        weak var mapView: MKMapView?
        
        init(_ parent: TourMapView) {
            self.parent = parent
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
                self.updateOverlayPoints()
            }
        }
        
        func updateOverlayPoints() {
            guard let mapView = mapView else { return }
            
            let points = parent.viewModel.locations.compactMap { location -> CGPoint? in
                guard let coordinate = location.coordinate else { return nil }
                return mapView.convert(coordinate, toPointTo: mapView)
            }
            
            DispatchQueue.main.async {
                self.parent.overlayPoints = points
            }
        }
    }
}

// MARK: - Overlay Views

struct TourMapOverlay: View {
    let overlayPoints: [CGPoint]
    let mapSize: CGSize
    let locations: [TourLocation]
    let routes: [TourRoute]
    let region: MKCoordinateRegion
    
    func point(for coordinate: CLLocationCoordinate2D) -> CGPoint {
        let minLon = region.center.longitude - region.span.longitudeDelta/2
        let maxLon = region.center.longitude + region.span.longitudeDelta/2
        let minLat = region.center.latitude - region.span.latitudeDelta/2
        let maxLat = region.center.latitude + region.span.latitudeDelta/2
        let x = (coordinate.longitude - minLon) / (maxLon - minLon) * mapSize.width
        let y = (1 - (coordinate.latitude - minLat) / (maxLat - minLat)) * mapSize.height
        return CGPoint(x: x, y: y)
    }
    
    var body: some View {
        Canvas { context, size in
            // Draw routes
            for route in routes {
                var path = Path()
                let points = route.coordinates.map { point(for: $0) }
                if let first = points.first {
                    path.move(to: first)
                    for pt in points.dropFirst() { path.addLine(to: pt) }
                }
                context.stroke(path, with: .color(Color(red: 0.8, green: 0, blue: 0)), lineWidth: 6)
            }
            
            // Draw markers using overlayPoints for perfect sync
            for (i, point) in overlayPoints.enumerated() {
                let rect = CGRect(x: point.x - 15, y: point.y - 15, width: 30, height: 30)
                context.fill(Path(rect), with: .color(Color(red: 0.8, green: 0, blue: 0)))
                let letter = String(UnicodeScalar(65 + i)!)
                let text = Text(letter).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                context.draw(text, at: CGPoint(x: point.x, y: point.y))
            }
        }
        .allowsHitTesting(false)
    }
}

struct ProgressOverlay: View {
    let geocodingProgress: (current: Int, total: Int)?
    let routingProgress: (current: Int, total: Int)?
    
    var body: some View {
        if let progress = geocodingProgress {
            VStack {
                ProgressView(value: Double(progress.current), total: Double(progress.total))
                    .progressViewStyle(LinearProgressViewStyle())
                Text("Geocoding \(progress.current) of \(progress.total)...")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(radius: 8)
        } else if let progress = routingProgress {
            VStack {
                ProgressView(value: Double(progress.current), total: Double(progress.total))
                    .progressViewStyle(LinearProgressViewStyle())
                Text("Routing \(progress.current) of \(progress.total)...")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(radius: 8)
        }
    }
}

// MARK: - Main Tour View

struct TourView: View {
    @StateObject private var viewModel = TourViewModel()
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 54.4858, longitude: -0.6206), // Whitby
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var overlayPoints: [CGPoint] = []
    @State private var hasSetInitialRegion = false
    
    private let sampleAddresses = [
        "Whitby station, Station Square, Whitby, North Yorkshire, YO21 1YN",
        "Whitby Museum, Pannett Park, Whitby, North Yorkshire, YO21 1RE",
        "6 Royal Crescent, Whitby, North Yorkshire, YO21 3EJ",
        "Swing Bridge, Bridge St, Whitby YO22 4BG",
        "St Mary's church, Abbey Plain, Whitby YO22 4JR"
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                TourMapView(
                    viewModel: viewModel,
                    region: $region,
                    overlayPoints: $overlayPoints
                )
                .saturation(0)
                .edgesIgnoringSafeArea(.all)
                
                TourMapOverlay(
                    overlayPoints: overlayPoints,
                    mapSize: geo.size,
                    locations: viewModel.locations,
                    routes: viewModel.routes,
                    region: region
                )
                
                if viewModel.geocodingProgress != nil || viewModel.routingProgress != nil {
                    ProgressOverlay(
                        geocodingProgress: viewModel.geocodingProgress,
                        routingProgress: viewModel.routingProgress
                    )
                    .frame(maxWidth: 300)
                    .position(x: geo.size.width/2, y: geo.size.height/6)
                }
                
                if !viewModel.errorMessages.isEmpty {
                    VStack {
                        ForEach(viewModel.errorMessages, id: \.self) { error in
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(8)
                        }
                    }
                    .position(x: geo.size.width/2, y: geo.size.height - 100)
                }
            }
        }
        .onAppear {
            viewModel.loadTour(addresses: sampleAddresses)
        }
        .onChange(of: viewModel.locations) { locations in
            if !hasSetInitialRegion && !locations.isEmpty {
                updateRegionToShowAllLocations()
                hasSetInitialRegion = true
            }
        }
    }
    
    private func updateRegionToShowAllLocations() {
        let coordinates = viewModel.locations.compactMap { $0.coordinate }
        guard !coordinates.isEmpty else { return }
        
        region = MKCoordinateRegion.regionCovering(coordinates: coordinates)
    }
}

// MARK: - ContentView

struct ContentView: View {
    var body: some View {
        TourView()
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

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        let pointCount = self.pointCount
        coordinates.reserveCapacity(pointCount)
        
        for i in 0..<pointCount {
            var coordinate = CLLocationCoordinate2D()
            self.getCoordinates(&coordinate, range: NSRange(location: i, length: 1))
            coordinates.append(coordinate)
        }
        
        return coordinates
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

// MARK: - GeoJSON Helpers

import Foundation

func coordinatesFromGeoJSON(_ geoJSON: [String: Any]) -> [CLLocationCoordinate2D] {
    guard
        let geometry = geoJSON["geometry"] as? [String: Any],
        let type = geometry["type"] as? String,
        let coords = geometry["coordinates"]
    else { return [] }

    if type == "LineString", let coordArray = coords as? [[Double]] {
        return coordArray.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
    } else if type == "Point", let coord = coords as? [Double], coord.count == 2 {
        return [CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0])]
    }
    // Add support for MultiPoint, Polygon, etc. as needed
    return []
}

// Example usage in overlay logic:
// Suppose you have a geoJSON dictionary and a mapView reference
// let geoJSON: [String: Any] = ...
// let coordinates = coordinatesFromGeoJSON(geoJSON)
// let points = coordinates.map { mapView.convert($0, toPointTo: mapView) }
// Now use `points` to draw your overlay



