import SwiftUI
import MapKit

// ObservableObject that stores the camera state
class CameraPositionModel: ObservableObject {
    @Published var slavePosition: MapCameraPosition
    
    init() {
        let camera = MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            distance: 5000,
            heading: 0,
            pitch: 0
        )
        self.slavePosition = .camera(camera)
    }
}

struct DoubleMap: View {
    @StateObject private var cameraModel = CameraPositionModel()
    @State private var masterPosition: MapCameraPosition = .camera(MapCamera(
        centerCoordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        distance: 5000,
        heading: 0,
        pitch: 0
    ))
    
    var body: some View {
        ZStack {
            // Bottom map: grayscale, mirrors top map's camera
            Map(position: $cameraModel.slavePosition)
                .mapControlVisibility(.hidden)
                .allowsHitTesting(false)
                .saturation(0)
            
            // Top map: interactive, semi-transparent
            Map(position: $masterPosition)
                .onMapCameraChange(frequency: .continuous) { context in
                    cameraModel.slavePosition = .camera(context.camera)
                }
                .mapControlVisibility(.visible)
                .opacity(0.01)
        }
        .frame(height: 300)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Overlayed Maps — Interactive Layer at 0.1 Opacity")
                .font(.headline)
            DoubleMap()
        }
    }
}

#Preview {
    ContentView()
}
