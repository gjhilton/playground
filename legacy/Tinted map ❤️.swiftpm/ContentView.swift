import SwiftUI
import MapKit

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
            // Bottom map: grayscale mirror
            Map(position: $cameraModel.slavePosition)
                .mapControlVisibility(.hidden)
                .allowsHitTesting(false)
                .saturation(0)
                .preferredColorScheme(.light) // ✅ Force light mode only here
            
            // Top map: interactive, transparent
            Map(position: $masterPosition)
                .onMapCameraChange(frequency: .continuous) { context in
                    cameraModel.slavePosition = .camera(context.camera)
                }
                .mapControlVisibility(.visible)
                .opacity(0.1)
            
            // Brown color overlay using multiply mode — doesn't block touch
            Color(red: 0.5, green: 0.2, blue:  0)
                .opacity(1)
                .blendMode(.screen)
                .allowsHitTesting(false)
           // Color(red: 1, green: 0.97, blue:  0.95)
                //.opacity(1)
                //.blendMode(.screen)
                //.allowsHitTesting(false)
            
        }
        .compositingGroup() // Needed for blendMode
        //.preferredColorScheme(.light)
        //.frame(height: 300)
        .cornerRadius(12)
        .padding(.horizontal)
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
