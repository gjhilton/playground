import SwiftUI
import MapKit
import CoreLocation

// MARK: - Location Map View

struct LocationMapView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = MapViewModel()
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if viewModel.isReady {
                mapContent
            } else if viewModel.isLoading {
                LoadingView(message: "Initializing map...")
            } else if let error = viewModel.locationError {
                ErrorView(error: error) {
                    Task {
                        await viewModel.initialize()
                    }
                }
            } else if let error = viewModel.geocodingError {
                ErrorView(error: error) {
                    Task {
                        await viewModel.initialize()
                    }
                }
            } else {
                LoadingView(message: "Waiting for location...")
            }
        }
        .task {
            await viewModel.initialize()
        }
    }
    
    // MARK: - Map Content
    
    @ViewBuilder
    private var mapContent: some View {
        if let region = viewModel.region,
           let pinCoordinate = viewModel.pinCoordinate,
           let userCoordinate = viewModel.userCoordinate {
            
            ZStack {
                // Map View
                MapView(
                    region: Binding(
                        get: { region },
                        set: { viewModel.region = $0 }
                    ),
                    pinCoordinate: pinCoordinate,
                    userCoordinate: userCoordinate,
                    pinPoint: $viewModel.pinPoint,
                    userPoint: $viewModel.userPoint
                )
                .saturation(0) // Grayscale effect
                .ignoresSafeArea()
                
                // Overlay Markers
                GeometryReader { geometry in
                    ZStack {
                        if let pinPoint = viewModel.pinPoint {
                            PinView()
                                .position(x: pinPoint.x, y: pinPoint.y)
                        }
                        
                        if let userPoint = viewModel.userPoint {
                            UserLocationView()
                                .position(x: userPoint.x, y: userPoint.y)
                        }
                    }
                }
                
                // Controls
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        RecenterButton {
                            viewModel.recenterMap()
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LocationMapView()
} 