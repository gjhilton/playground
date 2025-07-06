import SwiftUI

// MARK: - Pin View

struct PinView: View {
    // MARK: - Properties
    
    private let size: CGFloat
    private let color: Color
    
    // MARK: - Initialization
    
    init(size: CGFloat = 30, color: Color = .red) {
        self.size = size
        self.color = color
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Image(systemName: "mappin.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundColor(color)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - User Location View

struct UserLocationView: View {
    // MARK: - Properties
    
    private let size: CGFloat
    private let color: Color
    
    // MARK: - Initialization
    
    init(size: CGFloat = 30, color: Color = .red) {
        self.size = size
        self.color = color
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Outer circle with opacity
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: size, height: size)
            
            // Inner circle with stroke
            Circle()
                .stroke(color, lineWidth: 3)
                .frame(width: size * 0.6, height: size * 0.6)
            
            // Center dot
            Circle()
                .fill(color)
                .frame(width: size * 0.2, height: size * 0.2)
        }
        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    // MARK: - Properties
    
    private let message: String
    
    // MARK: - Initialization
    
    init(message: String = "Loading map...") {
        self.message = message
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Error View

struct ErrorView: View {
    // MARK: - Properties
    
    private let error: LocalizedError
    private let retryAction: () -> Void
    
    // MARK: - Initialization
    
    init(error: LocalizedError, retryAction: @escaping () -> Void) {
        self.error = error
        self.retryAction = retryAction
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Error")
                .font(.headline)
            
            Text(error.errorDescription ?? "An unknown error occurred")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Re-center Button

struct RecenterButton: View {
    // MARK: - Properties
    
    private let action: () -> Void
    
    // MARK: - Initialization
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                Text("Re-center")
            }
            .font(.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
} 