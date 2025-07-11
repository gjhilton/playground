
import SwiftUI
import MapKit
import CoreLocation
import Combine // Added for Combine framework

// MARK: - Models

struct TourLocation {
    let address: String
    let coordinate: CLLocationCoordinate2D?
    let title: String
    
    init(address: String, coordinate: CLLocationCoordinate2D? = nil, title: String = "") {
        self.address = address
        self.coordinate = coordinate
        self.title = title
    }
}

struct TourRoute {
    let startIndex: Int
    let endIndex: Int
    let coordinates: [CLLocationCoordinate2D]
    let distance: CLLocationDistance
    let expectedTravelTime: TimeInterval
    
    var geoJSON: [String: Any] {
        let coordinates = self.coordinates.map { [$0.longitude, $0.latitude] }
        return [
            "type": "Feature",
            "geometry": [
                "type": "LineString",
                "coordinates": coordinates
            ],
            "properties": [
                "distance": distance,
                "expectedTravelTime": expectedTravelTime,
                "startIndex": startIndex,
                "endIndex": endIndex
            ]
        ]
    }
}

// MARK: - Services

protocol TourServiceProtocol {
    func geocodeLocations(_ addresses: [String], completion: @escaping ([TourLocation]) -> Void)
    func getWalkingDirections(between locations: [TourLocation], completion: @escaping ([TourRoute]) -> Void)
}

class TourService: TourServiceProtocol {
    private let geocoder = CLGeocoder()
    private let directionsQueue = DispatchQueue(label: "com.tour.directions", qos: .userInitiated)
    
    func geocodeLocations(_ addresses: [String], completion: @escaping ([TourLocation]) -> Void) {
        var geocodedLocations: [TourLocation] = []
        func geocodeNext(index: Int) {
            guard index < addresses.count else {
                completion(geocodedLocations)
                return
            }
            let address = addresses[index]
            geocoder.geocodeAddressString(address) { placemarks, error in
                let location: TourLocation
                if let placemark = placemarks?.first, let coordinate = placemark.location?.coordinate {
                    location = TourLocation(
                        address: address,
                        coordinate: coordinate,
                        title: placemark.name ?? address
                    )
                } else {
                    location = TourLocation(address: address, coordinate: nil)
                }
                // Print geocode result with timestamp
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss.SSS"
                let timestamp = formatter.string(from: Date())
                print("[\(timestamp)] Geocoded: \(address) => \(String(describing: location.coordinate))")
                DispatchQueue.main.async {
                    geocodedLocations.append(location)
                    geocodeNext(index: index + 1)
                }
            }
        }
        geocodeNext(index: 0)
    }
    
    func getWalkingDirections(between locations: [TourLocation], completion: @escaping ([TourRoute]) -> Void) {
        guard locations.count >= 2 else {
            completion([])
            return
        }
        
        var routes: [TourRoute] = []
        let group = DispatchGroup()
        
        for i in 0..<(locations.count - 1) {
            guard let startCoord = locations[i].coordinate,
                  let endCoord = locations[i + 1].coordinate else { continue }
            
            group.enter()
            getDirections(from: startCoord, to: endCoord, startIndex: i, endIndex: i + 1) { route in
                if let route = route {
                    routes.append(route)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(routes.sorted { $0.startIndex < $1.startIndex })
        }
    }
    
    private func getDirections(from start: CLLocationCoordinate2D, 
                               to end: CLLocationCoordinate2D, 
                               startIndex: Int, 
                               endIndex: Int, 
                               completion: @escaping (TourRoute?) -> Void) {
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let route = response?.routes.first else {
                completion(nil)
                return
            }
            
            let coordinates = self.extractCoordinates(from: route)
            let tourRoute = TourRoute(
                startIndex: startIndex,
                endIndex: endIndex,
                coordinates: coordinates,
                distance: route.distance,
                expectedTravelTime: route.expectedTravelTime
            )
            
            completion(tourRoute)
        }
    }
    
    private func extractCoordinates(from route: MKRoute) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        
        for step in route.steps {
            let polyline = step.polyline
            var points = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: polyline.pointCount)
            polyline.getCoordinates(&points, range: NSRange(location: 0, length: polyline.pointCount))
            coordinates.append(contentsOf: points)
        }
        
        return coordinates
    }
}

// MARK: - View Models

class TourViewModel: ObservableObject {
    @Published var locations: [TourLocation] = []
    @Published var routes: [TourRoute] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isGeocoding = false
    
    private let tourService: TourServiceProtocol
    
    init(tourService: TourServiceProtocol = TourService()) {
        self.tourService = tourService
    }
    
    func loadTour(addresses: [String]) {
        isLoading = true
        isGeocoding = true
        errorMessage = nil
        
        tourService.geocodeLocations(addresses) { [weak self] locations in
            self?.locations = locations // Do not filter here
            self?.isGeocoding = false
            
            self?.tourService.getWalkingDirections(between: locations.filter { $0.coordinate != nil }) { routes in
                DispatchQueue.main.async {
                    self?.routes = routes
                    self?.isLoading = false
                }
            }
        }
    }
    
    var hasValidData: Bool {
        return !locations.isEmpty && locations.allSatisfy { $0.coordinate != nil }
    }
}

// MARK: - Views

class MapOverlayView: UIView {
    private var mapView: MKMapView?
    private var locations: [TourLocation] = []
    private var routes: [TourRoute] = []
    
    // MARK: - Configuration
    
    struct Configuration {
        let markerSize: CGFloat = 30
        let routeLineWidth: CGFloat = 6
        let markerColor = UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
        let routeColor = UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
        let textColor = UIColor.white
        let font = UIFont.systemFont(ofSize: 18, weight: .bold)
    }
    
    private let config = Configuration()
    
    // MARK: - Public Interface
    
    func configure(mapView: MKMapView) {
        self.mapView = mapView
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    func updateData(locations: [TourLocation], routes: [TourRoute]) {
        self.locations = locations
        self.routes = routes
        setNeedsDisplay()
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        guard let mapView = mapView,
              let ctx = UIGraphicsGetCurrentContext() else { return }
        
        drawRoutes(ctx: ctx, mapView: mapView)
        drawMarkers(ctx: ctx, mapView: mapView)
    }
    
    private func drawRoutes(ctx: CGContext, mapView: MKMapView) {
        for route in routes {
            let points = route.coordinates.compactMap { coordinate in
                mapView.convert(coordinate, toPointTo: self)
            }
            
            guard points.count >= 2 else { continue }
            
            ctx.setStrokeColor(config.routeColor.cgColor)
            ctx.setLineWidth(config.routeLineWidth)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            
            ctx.move(to: points[0])
            for point in points.dropFirst() {
                ctx.addLine(to: point)
            }
            ctx.strokePath()
        }
    }
    
    private func drawMarkers(ctx: CGContext, mapView: MKMapView) {
        for (index, location) in locations.enumerated() {
            guard let coordinate = location.coordinate else { continue }
            
            let point = mapView.convert(coordinate, toPointTo: self)
            let letter = String(UnicodeScalar(65 + index)!) // A, B, C, D, E
            let rect = CGRect(
                x: point.x - config.markerSize/2,
                y: point.y - config.markerSize/2,
                width: config.markerSize,
                height: config.markerSize
            )
            
            // Draw marker background
            ctx.setFillColor(config.markerColor.cgColor)
            ctx.fill(rect)
            
            // Draw letter
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: config.font,
                .foregroundColor: config.textColor
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

class TourViewController: UIViewController {
    private let mapView = MKMapView()
    private let overlayView = MapOverlayView()
    private let viewModel: TourViewModel
    private var hasInitialZoom = false
    private var spinner: UIActivityIndicatorView?
    
    init(viewModel: TourViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupOverlayView()
        setupSpinner()
        setupBindings()
    }
    
    private func setupSpinner() {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        self.spinner = spinner
    }
    
    private func setupMapView() {
        view.backgroundColor = .white
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        // 🔧 Make the map view transparent
        mapView.alpha = 0.01 // 0 = fully transparent, 1 = fully opaque
        
        // OR if you want to make only the map background invisible (not overlays)
        mapView.isOpaque = false
        mapView.backgroundColor = .clear
        mapView.layer.backgroundColor = UIColor.clear.cgColor
        
        // Optionally remove extra visuals
        mapView.mapType = .standard
        mapView.showsPointsOfInterest = false
        mapView.showsBuildings = false
        mapView.showsTraffic = false
        mapView.showsScale = false
        mapView.showsCompass = false
        mapView.showsUserLocation = false
        
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
        overlayView.configure(mapView: mapView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupBindings() {
        viewModel.$isGeocoding
            .sink { [weak self] isGeocoding in
                guard let self = self else { return }
                if isGeocoding {
                    self.spinner?.startAnimating()
                    self.mapView.isHidden = true
                    self.overlayView.isHidden = true
                } else {
                    self.spinner?.stopAnimating()
                    self.mapView.isHidden = false
                    self.overlayView.isHidden = false
                    // Only fit map once when geocoding is done and we have valid locations
                    let allValid = !self.viewModel.locations.isEmpty && self.viewModel.locations.allSatisfy { $0.coordinate != nil }
                    if allValid && !self.hasInitialZoom {
                        self.hasInitialZoom = true
                        self.fitMapToLocations(self.viewModel.locations)
                    }
                }
            }
            .store(in: &cancellables)
        
        viewModel.$locations
            .sink { [weak self] locations in
                guard let self = self else { return }
                self.overlayView.updateData(locations: locations, routes: self.viewModel.routes)
            }
            .store(in: &cancellables)
        
        viewModel.$routes
            .sink { [weak self] routes in
                guard let self = self else { return }
                self.overlayView.updateData(locations: self.viewModel.locations, routes: routes)
            }
            .store(in: &cancellables)
    }
    
    private func fitMapToLocations(_ locations: [TourLocation]) {
        guard !locations.isEmpty else { return }
        
        let coordinates = locations.compactMap { $0.coordinate }
        guard !coordinates.isEmpty else { return }
        
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
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
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - MapKit Delegate

extension TourViewController: MKMapViewDelegate {
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        overlayView.setNeedsDisplay()
    }
}

// MARK: - SwiftUI Integration

struct TourViewRepresentable: UIViewControllerRepresentable {
    let addresses: [String]
    
    func makeUIViewController(context: Context) -> TourViewController {
        let viewModel = TourViewModel()
        let controller = TourViewController(viewModel: viewModel)
        viewModel.loadTour(addresses: addresses)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: TourViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Main ContentView

struct ContentView: View {
    private let sampleAddresses = [
        "Whitby station, Station Square, Whitby, North Yorkshire, YO21 1YN",
        "Whitby Museum, Pannett Park, Whitby, North Yorkshire, YO21 1RE",
        "6 Royal Crescent, Whitby, North Yorkshire, YO21 3EJ",
        "North Terrace, Whitby YO21 3HA",
        "1 bakehouse yard, yo21 3ps",
        "Swing Bridge, Bridge St, Whitby YO22 4BG",
        "St Mary's church, Abbey Plain, Whitby YO22 4JR"
    ]
    
    var body: some View {
        TourViewRepresentable(addresses: sampleAddresses)
    }
}

// MARK: - Legacy Support (for existing TourStop struct)

struct TourStop {
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
    let index: Int
}


