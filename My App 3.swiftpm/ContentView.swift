import SwiftUI
import MapKit

// ObservableObject that stores the camera state
class CameraPositionModel: ObservableObject {
    @Published var position: MapCameraPosition
    
    init() {
        let camera = MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            distance: 5000,
            heading: 0,
            pitch: 0
        )
        self.position = .camera(camera)
    }
}

struct DoubleMap: View {
    @StateObject private var cameraModel = CameraPositionModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Interactive Map (top) & Grayscale Mirror (bottom)")
                .font(.headline)
            
            // Interactive map with camera tracking and opacity
            Map(position: $cameraModel.position)
                .onMapCameraChange { context in
                    // This ensures updates from user interaction are captured
                    cameraModel.position = .camera(context.camera)
                }
                .mapControlVisibility(.visible)
                .opacity(0.3)
                .frame(height: 300)
                .cornerRadius(12)
                .padding(.horizontal)
            
            // Grayscale mirror map, always uses latest camera
            Map(position: $cameraModel.position)
                .mapControlVisibility(.hidden)
                .allowsHitTesting(false)
                .saturation(0)
                .frame(height: 300)
                .cornerRadius(12)
                .padding(.horizontal)
        }
    }
}

struct ContentView: View {
    var body: some View {
        DoubleMap()
    }
}

#Preview {
    ContentView()
}
