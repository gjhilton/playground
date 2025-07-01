import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090), // placeholder
            latitudinalMeters: 200,
            longitudinalMeters: 200
        )
    )
    
    var body: some View {
        ZStack {
            if let location = locationManager.location {
                Map(position: $cameraPosition) {
                    UserAnnotation()
                }
                .onAppear {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: location.coordinate,
                            latitudinalMeters: 200,
                            longitudinalMeters: 200
                        )
                    )
                }
                .edgesIgnoringSafeArea(.all)
            } else {
                VStack {
                    ProgressView()
                    Text("Fetching location…")
                }
            }
        }
    }
}

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
        if let loc = locations.first {
            DispatchQueue.main.async {
                self.location = loc
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}
