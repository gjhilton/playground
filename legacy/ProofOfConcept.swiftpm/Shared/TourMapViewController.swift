//
//  TourMapViewController.swift
//  Dracumentary
//
//  Created by g hilton on 05/07/2025.
//

import UIKit
import MapKit
import CoreLocation

class TourMapViewController: UIViewController {
    
    // MARK: - Properties
    var onNavigate: ((UIViewController) -> Void)?
    private let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    private var tourAnnotations: [MKPointAnnotation] = []
    private var selectedLocation: TourLocation?
    private var directionsOverlay: MKPolyline?
    
    // MARK: - UI Elements
    private let locationLabel = UILabel()
    private let directionsView = UIView()
    private let directionsLabel = UILabel()
    private let atLocationButton = UIButton()
    private let audioToggleButton = UIButton()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupMapView()
        setupLocationManager()
        setupUI()
        setupConstraints()
        addTourLocations()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestLocationPermission()
    }
    
    // MARK: - Setup
    private func setupView() {
        view.backgroundColor = .black
    }
    
    private func setupMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        // Set initial region to Whitby
        let whitbyRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 54.4858, longitude: -0.6206),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        mapView.setRegion(whitbyRegion, animated: false)
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func setupUI() {
        // Location label (appears when near a tour location)
        locationLabel.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 0.9) // Parchment
        locationLabel.textColor = .black
        locationLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        locationLabel.textAlignment = .center
        locationLabel.layer.cornerRadius = 8
        locationLabel.layer.borderWidth = 1
        locationLabel.layer.borderColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        locationLabel.isHidden = true
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(locationLabel)
        
        // Directions view
        directionsView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 0.95)
        directionsView.layer.cornerRadius = 12
        directionsView.layer.borderWidth = 2
        directionsView.layer.borderColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        directionsView.isHidden = true
        directionsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(directionsView)
        
        // Directions label
        directionsLabel.text = "Loading directions..."
        directionsLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        directionsLabel.textColor = .black
        directionsLabel.numberOfLines = 0
        directionsLabel.translatesAutoresizingMaskIntoConstraints = false
        directionsView.addSubview(directionsLabel)
        
        // At location button
        atLocationButton.setTitle("I'm at this location", for: .normal)
        atLocationButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        atLocationButton.setTitleColor(.white, for: .normal)
        atLocationButton.backgroundColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        atLocationButton.layer.cornerRadius = 8
        atLocationButton.addTarget(self, action: #selector(atLocationButtonTapped), for: .touchUpInside)
        atLocationButton.translatesAutoresizingMaskIntoConstraints = false
        directionsView.addSubview(atLocationButton)
        
        // Audio toggle button
        audioToggleButton.setTitle("🔊", for: .normal)
        audioToggleButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        audioToggleButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        audioToggleButton.layer.cornerRadius = 25
        audioToggleButton.addTarget(self, action: #selector(audioToggleButtonTapped), for: .touchUpInside)
        audioToggleButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(audioToggleButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            locationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            locationLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            locationLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            locationLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            locationLabel.heightAnchor.constraint(equalToConstant: 40),
            
            directionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            directionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            directionsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            directionsLabel.topAnchor.constraint(equalTo: directionsView.topAnchor, constant: 20),
            directionsLabel.leadingAnchor.constraint(equalTo: directionsView.leadingAnchor, constant: 20),
            directionsLabel.trailingAnchor.constraint(equalTo: directionsView.trailingAnchor, constant: -20),
            
            atLocationButton.topAnchor.constraint(equalTo: directionsLabel.bottomAnchor, constant: 15),
            atLocationButton.leadingAnchor.constraint(equalTo: directionsView.leadingAnchor, constant: 20),
            atLocationButton.trailingAnchor.constraint(equalTo: directionsView.trailingAnchor, constant: -20),
            atLocationButton.bottomAnchor.constraint(equalTo: directionsView.bottomAnchor, constant: -20),
            atLocationButton.heightAnchor.constraint(equalToConstant: 50),
            
            audioToggleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            audioToggleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            audioToggleButton.widthAnchor.constraint(equalToConstant: 50),
            audioToggleButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - Tour Locations
    private func addTourLocations() {
        let tourData = TourData.shared
        
        for location in tourData.locations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotation.title = location.name
            annotation.subtitle = location.address
            tourAnnotations.append(annotation)
            mapView.addAnnotation(annotation)
        }
    }
    
    // MARK: - Location Permission
    private func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    // MARK: - Location Proximity Check
    private func checkLocationProximity() {
        guard let userLocation = AppState.shared.userLocation else { return }
        
        let tourData = TourData.shared
        let proximityThreshold: CLLocationDistance = 40 // 40 meters
        
        for location in tourData.locations {
            let locationCLLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let distance = userLocation.distance(from: locationCLLocation)
            
            if distance <= proximityThreshold {
                showLocationLabel(for: location)
                return
            }
        }
        
        hideLocationLabel()
    }
    
    private func showLocationLabel(for location: TourLocation) {
        locationLabel.text = location.name
        locationLabel.isHidden = false
    }
    
    private func hideLocationLabel() {
        locationLabel.isHidden = true
    }
    
    // MARK: - Directions
    private func showDirections(to location: TourLocation) {
        guard let userLocation = AppState.shared.userLocation else {
            directionsLabel.text = "Unable to get your location"
            directionsView.isHidden = false
            return
        }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.directionsLabel.text = "Error getting directions: \(error.localizedDescription)"
                    self?.directionsView.isHidden = false
                    return
                }
                
                guard let route = response?.routes.first else {
                    self?.directionsLabel.text = "No route found"
                    self?.directionsView.isHidden = false
                    return
                }
                
                // Show route on map
                self?.showRoute(route)
                
                // Show first step
                if let firstStep = route.steps.first {
                    self?.directionsLabel.text = firstStep.instructions
                }
                
                self?.directionsView.isHidden = false
            }
        }
    }
    
    private func showRoute(_ route: MKRoute) {
        // Remove existing overlay
        if let existingOverlay = directionsOverlay {
            mapView.removeOverlay(existingOverlay)
        }
        
        // Add new overlay
        directionsOverlay = route.polyline
        mapView.addOverlay(route.polyline)
        
        // Fit map to show the entire route
        let rect = route.polyline.boundingMapRect
        mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 200, right: 50), animated: true)
    }
    
    // MARK: - Actions
    @objc private func atLocationButtonTapped() {
        guard let selectedLocation = selectedLocation else { return }
        
        // Mark location as visited
        AppState.shared.markLocationVisited(selectedLocation.id)
        
        // Navigate to location content
        let locationContentVC = LocationContentViewController(location: selectedLocation)
        onNavigate?(locationContentVC)
    }
    
    @objc private func audioToggleButtonTapped() {
        // Toggle audio state
        let isAudioOn = audioToggleButton.title(for: .normal) == "🔊"
        audioToggleButton.setTitle(isAudioOn ? "🔇" : "🔊", for: .normal)
    }
}

// MARK: - MKMapViewDelegate
extension TourMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKind(of: MKUserLocation.self) else { return nil }
        
        let identifier = "TourLocation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        
        // Customize the annotation
        if let markerView = annotationView as? MKMarkerAnnotationView {
            markerView.markerTintColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0) // Blood red
            markerView.glyphText = "🏛️"
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0) // Blood red
            renderer.lineWidth = 4
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation,
              let location = TourData.shared.locations.first(where: { $0.coordinate.latitude == annotation.coordinate.latitude && $0.coordinate.longitude == annotation.coordinate.longitude }) else { return }
        
        selectedLocation = location
        
        if AppState.shared.currentMode == .promenade {
            showDirections(to: location)
        } else {
            // In parlour mode, go directly to content
            let locationContentVC = LocationContentViewController(location: location)
            onNavigate?(locationContentVC)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension TourMapViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestLocationPermission()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        AppState.shared.userLocation = location
        checkLocationProximity()
    }
} 