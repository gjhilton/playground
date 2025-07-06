
import SwiftUI
import UIKit
import MapKit
import CoreLocation

// Custom annotation for a tour stop
class TourStopAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}

// Tour stop data structure
struct TourStop {
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
    let index: Int
}

// Custom overlay for tour graphics
class TourSymbolOverlay: NSObject, MKOverlay {
    let coordinates: [CLLocationCoordinate2D]
    let symbolNames: [String]
    var boundingMapRect: MKMapRect {
        guard !coordinates.isEmpty else { return .null }
        if coordinates.count == 1 {
            // Use a very large rect around the point to cover the map
            let center = MKMapPoint(coordinates[0])
            let size: Double = 10000000 // very large, covers most of the map
            return MKMapRect(x: center.x - size/2, y: center.y - size/2, width: size, height: size)
        }
        var minMapPoint = MKMapPoint(coordinates[0])
        var maxMapPoint = minMapPoint
        for coord in coordinates {
            let point = MKMapPoint(coord)
            minMapPoint.x = min(minMapPoint.x, point.x)
            minMapPoint.y = min(minMapPoint.y, point.y)
            maxMapPoint.x = max(maxMapPoint.x, point.x)
            maxMapPoint.y = max(maxMapPoint.y, point.y)
        }
        return MKMapRect(
            origin: MKMapPoint(x: minMapPoint.x, y: minMapPoint.y),
            size: MKMapSize(width: maxMapPoint.x - minMapPoint.x, height: maxMapPoint.y - minMapPoint.y)
        )
    }
    var coordinate: CLLocationCoordinate2D {
        guard !coordinates.isEmpty else { return CLLocationCoordinate2D(latitude: 0, longitude: 0) }
        let lat = coordinates.map { $0.latitude }.reduce(0, +) / Double(coordinates.count)
        let lon = coordinates.map { $0.longitude }.reduce(0, +) / Double(coordinates.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    init(coordinates: [CLLocationCoordinate2D], symbolNames: [String]) {
        self.coordinates = coordinates
        self.symbolNames = symbolNames
        super.init()
    }
}

class TourSymbolOverlayRenderer: MKOverlayRenderer {
    let symbolSize: CGFloat = 30
    var animatedZoomScale: CGFloat = 1.0
    private var displayLink: CADisplayLink?
    private var animationStartTime: CFTimeInterval = 0
    private var animationDuration: CFTimeInterval = 0.2
    private var startZoomScale: CGFloat = 1.0
    private var targetZoomScale: CGFloat = 1.0
    
    func animateZoom(from: CGFloat, to: CGFloat) {
        displayLink?.invalidate()
        startZoomScale = from
        targetZoomScale = to
        animationStartTime = CACurrentMediaTime()
        animatedZoomScale = from
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateAnimation() {
        let elapsed = CACurrentMediaTime() - animationStartTime
        let t = min(CGFloat(elapsed / animationDuration), 1.0)
        animatedZoomScale = startZoomScale + (targetZoomScale - startZoomScale) * t
        setNeedsDisplay()
        if t >= 1.0 {
            displayLink?.invalidate()
            displayLink = nil
        }
    }
    
    override func canDraw(_ mapRect: MKMapRect, zoomScale: MKZoomScale) -> Bool {
        return true
    }
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = overlay as? TourSymbolOverlay else { return }
        for (i, coord) in overlay.coordinates.enumerated() {
            let mapPoint = MKMapPoint(coord)
            let point = self.point(for: mapPoint)
            // Animate symbol size using animatedZoomScale
            let mapCircleSize = symbolSize / animatedZoomScale
            let circleRect = CGRect(x: point.x - mapCircleSize/2, y: point.y - mapCircleSize/2, width: mapCircleSize, height: mapCircleSize)
            context.setStrokeColor(UIColor.blue.cgColor)
            context.setLineWidth(8 / animatedZoomScale)
            context.strokeEllipse(in: circleRect)
        }
    }
}

// Custom overlay UIView for screen-space graphics
class MapOverlayView: UIView {
    var mapView: MKMapView?
    var coordinates: [CLLocationCoordinate2D] = []
    var routeGeoJSON: [[String: Any]] = [] // Store GeoJSON route data
    
    override func draw(_ rect: CGRect) {
        guard let mapView = mapView else { return }
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        // Draw routes first (behind markers)
        drawRoutes(ctx: ctx, mapView: mapView)
        
        // Draw location markers
        drawMarkers(ctx: ctx, mapView: mapView)
    }
    
    private func drawRoutes(ctx: CGContext, mapView: MKMapView) {
        for route in routeGeoJSON {
            guard let geometry = route["geometry"] as? [String: Any],
                  let coordinates = geometry["coordinates"] as? [[Double]] else { continue }
            
            // Convert GeoJSON coordinates to screen points
            var points: [CGPoint] = []
            for coord in coordinates {
                let coordinate = CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0])
                let point = mapView.convert(coordinate, toPointTo: self)
                points.append(point)
            }
            
            // Draw the route line
            if points.count >= 2 {
                ctx.setStrokeColor(UIColor.blue.cgColor)
                ctx.setLineWidth(8.0)
                ctx.setLineCap(.round)
                ctx.setLineJoin(.round)
                
                ctx.move(to: points[0])
                for i in 1..<points.count {
                    ctx.addLine(to: points[i])
                }
                ctx.strokePath()
            }
        }
    }
    
    private func drawMarkers(ctx: CGContext, mapView: MKMapView) {
        let circleSize: CGFloat = 30
        for (i, coord) in coordinates.enumerated() {
            let point = mapView.convert(coord, toPointTo: self)
            let letter = String(UnicodeScalar(65 + i)!) // 65 = 'A' (uppercase)
            let rect = CGRect(x: point.x - circleSize/2, y: point.y - circleSize/2, width: circleSize, height: circleSize)
            print("Drawing letter: \(letter) at \(rect)")
            
            // Draw a blood red square background
            ctx.setFillColor(UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0).cgColor)
            ctx.fill(rect)
            
            // Draw white bold capital letter text
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: circleSize * 0.6, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let textSize = letter.size(withAttributes: textAttributes)
            let textRect = CGRect(
                x: point.x - textSize.width/2,
                y: point.y - textSize.height/2,
                width: textSize.width,
                height: textSize.height
            )
            letter.draw(in: textRect, withAttributes: textAttributes)
        }
    }
}

// UIKit TourView
class TourView: UIViewController, MKMapViewDelegate {
    
    private let mapView = MKMapView()
    private let addresses: [String]
    private let geocoder = CLGeocoder()
    private var overlayView: MapOverlayView?
    private var geocodedCoords: [CLLocationCoordinate2D] = []
    private var routeGeoJSON: [[String: Any]] = [] // Store GeoJSON route data
    
    init(addresses: [String]) {
        self.addresses = addresses
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupOverlayView()
        geocodeAddresses()
    }
    
    private func setupMapView() {
        view.backgroundColor = .white
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        // Configure map appearance
        mapView.mapType = .standard
#if targetEnvironment(macCatalyst)
        if #available(macCatalyst 13.1, *) {
            mapView.pointOfInterestFilter = .excludingAll
        }
#else
        mapView.showsPointsOfInterest = false
#endif
        mapView.showsBuildings = false
        mapView.showsTraffic = false
        mapView.showsScale = false
        mapView.showsCompass = false
        mapView.showsUserLocation = false
        // Force light mode
        if #available(iOS 13.0, *) {
            mapView.overrideUserInterfaceStyle = .light
        }
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupOverlayView() {
        let overlay = MapOverlayView(frame: .zero)
        overlay.backgroundColor = .clear
        overlay.isUserInteractionEnabled = false
        overlay.mapView = mapView
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.overlayView = overlay
    }
    
    private func geocodeAddresses() {
        geocodedCoords = []
        func geocodeNext(index: Int) {
            guard index < addresses.count else { 
                // Geocoding complete, now get directions
                getWalkingDirections()
                return 
            }
            let address = addresses[index]
            geocoder.geocodeAddressString(address) { [weak self] placemarks, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let placemark = placemarks?.first, let location = placemark.location {
                        self.geocodedCoords.append(location.coordinate)
                        self.overlayView?.coordinates = self.geocodedCoords
                        self.overlayView?.setNeedsDisplay()
                        self.fitTourStopsInView(tourStops: self.geocodedCoords.map { TourStop(coordinate: $0, title: "", subtitle: "", index: 0) })
                    }
                    geocodeNext(index: index + 1)
                }
            }
        }
        geocodeNext(index: 0)
    }
    
    private func getWalkingDirections() {
        guard geocodedCoords.count >= 2 else { return }
        
        func getDirectionsForSegment(index: Int) {
            guard index < geocodedCoords.count - 1 else { 
                // All directions complete, update overlay
                overlayView?.routeGeoJSON = routeGeoJSON
                overlayView?.setNeedsDisplay()
                return 
            }
            
            let startCoord = geocodedCoords[index]
            let endCoord = geocodedCoords[index + 1]
            
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoord))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endCoord))
            request.transportType = .walking
            
            let directions = MKDirections(request: request)
            directions.calculate { [weak self] response, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let route = response?.routes.first {
                        // Convert route to GeoJSON format
                        let geoJSON = self.routeToGeoJSON(route)
                        self.routeGeoJSON.append(geoJSON)
                        print("Got directions for segment \(index + 1): \(route.distance)m")
                    }
                    getDirectionsForSegment(index: index + 1)
                }
            }
        }
        
        getDirectionsForSegment(index: 0)
    }
    
    private func routeToGeoJSON(_ route: MKRoute) -> [String: Any] {
        var coordinates: [[Double]] = []
        
        for step in route.steps {
            let polyline = step.polyline
            var points = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: polyline.pointCount)
            polyline.getCoordinates(&points, range: NSRange(location: 0, length: polyline.pointCount))
            
            for point in points {
                coordinates.append([point.longitude, point.latitude])
            }
        }
        
        return [
            "type": "Feature",
            "geometry": [
                "type": "LineString",
                "coordinates": coordinates
            ],
            "properties": [
                "distance": route.distance,
                "expectedTravelTime": route.expectedTravelTime
            ]
        ]
    }
    
    private func fitTourStopsInView(tourStops: [TourStop]) {
        guard !tourStops.isEmpty else { return }
        // Remove duplicate coordinates manually
        let coords = tourStops.map { $0.coordinate }
        var uniqueCoords: [CLLocationCoordinate2D] = []
        for coord in coords {
            if !uniqueCoords.contains(where: { $0.latitude == coord.latitude && $0.longitude == coord.longitude }) {
                uniqueCoords.append(coord)
            }
        }
        
        
        guard !uniqueCoords.isEmpty else { return }
        var minLat = uniqueCoords[0].latitude
        var maxLat = uniqueCoords[0].latitude
        var minLon = uniqueCoords[0].longitude
        var maxLon = uniqueCoords[0].longitude
        for coord in uniqueCoords {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        let latPadding = 0.002
        let lonPadding = 0.002
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) + latPadding, 0.005),
            longitudeDelta: max((maxLon - minLon) + lonPadding, 0.005)
        )
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        // No overlay logic for these symbols
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // No overlay logic for these symbols
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        overlayView?.setNeedsDisplay()
    }
    
    private func currentZoomScale() -> CGFloat {
        let mapRect = mapView.visibleMapRect
        let viewWidth = mapView.bounds.width
        return CGFloat(mapRect.size.width) / viewWidth
    }
}

// SwiftUI wrapper for UIKit TourView
struct TourViewRepresentable: UIViewControllerRepresentable {
    let addresses: [String]
    
    func makeUIViewController(context: Context) -> TourView {
        return TourView(addresses: addresses)
    }
    
    func updateUIViewController(_ uiViewController: TourView, context: Context) {
        // No updates needed
    }
}

// Main ContentView
struct ContentView: View {
    let sampleAddresses = [
        "Whitby station, Station Square, Whitby, North Yorkshire, YO21 1YN",
        "Whitby Museum, Pannett Park, Whitby, North Yorkshire, YO21 1RE",
        "6 Royal Crescent, Whitby, North Yorkshire, YO21 3EJ",
        "Swing Bridge, Bridge St, Whitby YO22 4BG",
        "St Mary's church, Abbey Plain, Whitby YO22 4JR"
    ]
    
    var body: some View {
        TourViewRepresentable(addresses: sampleAddresses)
    }
}

