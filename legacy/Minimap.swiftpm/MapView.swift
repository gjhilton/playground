import SwiftUI
import MapKit
import CoreLocation

// MARK: - Map View

struct MapView: UIViewRepresentable {
    // MARK: - Properties
    
    @Binding var region: MKCoordinateRegion
    let pinCoordinate: CLLocationCoordinate2D
    let userCoordinate: CLLocationCoordinate2D
    @Binding var pinPoint: CGPoint?
    @Binding var userPoint: CGPoint?
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        context.coordinator.mapView = mapView
        
        // Setup map view
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        mapView.setRegion(region, animated: false)
        
        // Configure map view
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        
        if #available(iOS 13.0, *) {
            let config = MKStandardMapConfiguration(elevationStyle: .flat)
            config.pointOfInterestFilter = .excludingAll
            mapView.preferredConfiguration = config
            mapView.overrideUserInterfaceStyle = .light
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        updateMapRegion(mapView)
        updateOverlayPoints(mapView: mapView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Private Methods
    
    private func updateMapRegion(_ mapView: MKMapView) {
        if !mapView.region.center.isApproximatelyEqual(to: region.center) ||
           !mapView.region.span.isApproximatelyEqual(to: region.span) {
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func updateOverlayPoints(mapView: MKMapView) {
        DispatchQueue.main.async {
            pinPoint = mapView.convert(pinCoordinate, toPointTo: mapView)
            userPoint = mapView.convert(userCoordinate, toPointTo: mapView)
        }
    }
}

// MARK: - Coordinator

extension MapView {
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