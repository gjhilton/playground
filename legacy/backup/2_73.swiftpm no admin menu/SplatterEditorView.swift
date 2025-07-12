// Version: 2.73
import SwiftUI

// MARK: - Configuration Mode Toggle
// Configuration mode is controlled in SplatterView.swift

struct SplatterEditorView: View {
    @ObservedObject var viewModel: SplatterViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // Track whether we're in landscape on iPad
    private var isLandscapeOnIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .compact
    }
    
    var body: some View {
        if isLandscapeOnIPad {
            HStack(spacing: 0) {
                // Editor sidebar
                editorSidebar
                    .frame(width: 320)
                    .background(Color(.systemBackground))
                
                // Main content area
                mainContentArea
            }
        } else {
            // Portrait mode - hide editor
            mainContentArea
        }
    }
    
    private var editorSidebar: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    renderingPassesSection
                    centralDotSection
                    largeDotSection
                    mediumDotSection
                    smallDotSection
                    splashSection
                    saveSection
                }
                .padding()
            }
            .navigationTitle("Splatter Editor")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var mainContentArea: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(viewModel.renderPasses, id: \.name) { renderPass in
                    if renderPass.enabled {
                        MetalOverlayView(
                            dots: viewModel.metalData.dots,
                            splotColor: renderPass.color,
                            renderMask: renderPass.renderMask
                        )
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .blendMode(.multiply)
                        .opacity(renderPass.opacity)
                        .zIndex(renderPass.zIndex)
                    }
                }
            }
            .onAppear {
                viewModel.updateMetalData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("SplatterAddSplat"))) { notification in
                if let location = notification.object as? CGPoint {
                    viewModel.addSplat(at: location, screenWidth: geo.size.width, screenHeight: geo.size.height)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("SplatterClear"))) { _ in
            viewModel.clear()
        }
    }
    
    // MARK: - Editor Sections
    
    private var renderingPassesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rendering Passes")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Background Pass
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Toggle("Background", isOn: $viewModel.rendering.backgroundPassEnabled)
                            .font(.subheadline)
                        Spacer()
                    }
                    
                    if viewModel.rendering.backgroundPassEnabled {
                        HStack {
                            Text("Color")
                                .frame(width: 50, alignment: .leading)
                            ColorPicker("", selection: $viewModel.rendering.backgroundPassColor)
                                .frame(width: 40)
                            Spacer()
                        }
                        
                        HStack {
                            Text("Opacity")
                                .frame(width: 50, alignment: .leading)
                            Slider(value: $viewModel.rendering.backgroundPassOpacity, in: 0...1)
                            Text("\(viewModel.rendering.backgroundPassOpacity, specifier: "%.2f")")
                                .frame(width: 40, alignment: .trailing)
                                .font(.caption)
                        }
                    }
                }
                
                Divider()
                
                // Foreground Pass
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Toggle("Foreground", isOn: $viewModel.rendering.foregroundPassEnabled)
                            .font(.subheadline)
                        Spacer()
                    }
                    
                    if viewModel.rendering.foregroundPassEnabled {
                        HStack {
                            Text("Color")
                                .frame(width: 50, alignment: .leading)
                            ColorPicker("", selection: $viewModel.rendering.foregroundPassColor)
                                .frame(width: 40)
                            Spacer()
                        }
                        
                        HStack {
                            Text("Opacity")
                                .frame(width: 50, alignment: .leading)
                            Slider(value: $viewModel.rendering.foregroundPassOpacity, in: 0...1)
                            Text("\(viewModel.rendering.foregroundPassOpacity, specifier: "%.2f")")
                                .frame(width: 40, alignment: .trailing)
                                .font(.caption)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
    
    private var centralDotSection: some View {
        DotParameterSection(
            title: "Central Dot",
            enabled: $viewModel.centralDot.enabled,
            radiusMin: $viewModel.centralDot.radiusMin,
            radiusMax: $viewModel.centralDot.radiusMax
        )
    }
    
    private var largeDotSection: some View {
        ScatteredDotParameterSection(
            title: "Large Dots",
            enabled: $viewModel.largeDots.enabled,
            radiusMin: $viewModel.largeDots.radiusMin,
            radiusMax: $viewModel.largeDots.radiusMax,
            countMin: $viewModel.largeDots.countMin,
            countMax: $viewModel.largeDots.countMax,
            distanceMin: $viewModel.largeDots.distanceMin,
            distanceMax: $viewModel.largeDots.distanceMax
        )
    }
    
    private var mediumDotSection: some View {
        ScatteredDotParameterSection(
            title: "Medium Dots",
            enabled: $viewModel.mediumDots.enabled,
            radiusMin: $viewModel.mediumDots.radiusMin,
            radiusMax: $viewModel.mediumDots.radiusMax,
            countMin: $viewModel.mediumDots.countMin,
            countMax: $viewModel.mediumDots.countMax,
            distanceMin: $viewModel.mediumDots.distanceMin,
            distanceMax: $viewModel.mediumDots.distanceMax
        )
    }
    
    private var smallDotSection: some View {
        ScatteredDotParameterSection(
            title: "Small Dots",
            enabled: $viewModel.smallDots.enabled,
            radiusMin: $viewModel.smallDots.radiusMin,
            radiusMax: $viewModel.smallDots.radiusMax,
            countMin: $viewModel.smallDots.countMin,
            countMax: $viewModel.smallDots.countMax,
            distanceMin: $viewModel.smallDots.distanceMin,
            distanceMax: $viewModel.smallDots.distanceMax
        )
    }
    
    private var splashSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Splash Dots")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                Toggle("Enabled", isOn: $viewModel.splashes.enabled)
                    .font(.subheadline)
                
                if viewModel.splashes.enabled {
                    ParameterSlider(
                        title: "Count Min",
                        value: Binding(
                            get: { Double(viewModel.splashes.countMin) },
                            set: { viewModel.splashes.countMin = Int($0) }
                        ),
                        range: 0...20
                    )
                    
                    ParameterSlider(
                        title: "Count Max",
                        value: Binding(
                            get: { Double(viewModel.splashes.countMax) },
                            set: { viewModel.splashes.countMax = Int($0) }
                        ),
                        range: 0...20
                    )
                    
                    ParameterSlider(
                        title: "Width Min",
                        value: Binding(
                            get: { Double(viewModel.splashes.widthMin) },
                            set: { viewModel.splashes.widthMin = CGFloat($0) }
                        ),
                        range: 5...50
                    )
                    
                    ParameterSlider(
                        title: "Width Max",
                        value: Binding(
                            get: { Double(viewModel.splashes.widthMax) },
                            set: { viewModel.splashes.widthMax = CGFloat($0) }
                        ),
                        range: 5...50
                    )
                    
                    ParameterSlider(
                        title: "Distance Min",
                        value: Binding(
                            get: { Double(viewModel.splashes.distanceMin) },
                            set: { viewModel.splashes.distanceMin = CGFloat($0) }
                        ),
                        range: 20...200
                    )
                    
                    ParameterSlider(
                        title: "Distance Max",
                        value: Binding(
                            get: { Double(viewModel.splashes.distanceMax) },
                            set: { viewModel.splashes.distanceMax = CGFloat($0) }
                        ),
                        range: 20...200
                    )
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
    
    private var saveSection: some View {
        VStack(spacing: 12) {
            Button("Save Configuration to Clipboard") {
                saveConfigurationToClipboard()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Text("Saves all current parameter values as Swift code ready to paste into source")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Actions
    
    private func saveConfigurationToClipboard() {
        let config = generateConfigurationCode()
        UIPasteboard.general.string = config
        
        // Show a brief confirmation (you might want to add a proper toast notification)
        print("✅ Configuration copied to clipboard!")
    }
    
    private func generateConfigurationCode() -> String {
        return """
        // Generated Splatter Configuration - Version 2.73
        
        // Rendering Parameters
        backgroundPassEnabled: \(viewModel.rendering.backgroundPassEnabled)
        foregroundPassEnabled: \(viewModel.rendering.foregroundPassEnabled)
        backgroundPassColor: Color(red: \(viewModel.rendering.backgroundPassColor.cgColor?.components?[0] ?? 0.55), green: \(viewModel.rendering.backgroundPassColor.cgColor?.components?[1] ?? 0.0), blue: \(viewModel.rendering.backgroundPassColor.cgColor?.components?[2] ?? 0.0))
        foregroundPassColor: Color(red: \(viewModel.rendering.foregroundPassColor.cgColor?.components?[0] ?? 0.0), green: \(viewModel.rendering.foregroundPassColor.cgColor?.components?[1] ?? 0.6), blue: \(viewModel.rendering.foregroundPassColor.cgColor?.components?[2] ?? 0.0))
        backgroundPassOpacity: \(viewModel.rendering.backgroundPassOpacity)
        foregroundPassOpacity: \(viewModel.rendering.foregroundPassOpacity)
        
        // Central Dot Parameters
        centralDot.enabled: \(viewModel.centralDot.enabled)
        centralDot.radiusMin: \(viewModel.centralDot.radiusMin)
        centralDot.radiusMax: \(viewModel.centralDot.radiusMax)
        
        // Large Dot Parameters
        largeDots.enabled: \(viewModel.largeDots.enabled)
        largeDots.radiusMin: \(viewModel.largeDots.radiusMin)
        largeDots.radiusMax: \(viewModel.largeDots.radiusMax)
        largeDots.countMin: \(viewModel.largeDots.countMin)
        largeDots.countMax: \(viewModel.largeDots.countMax)
        largeDots.distanceMin: \(viewModel.largeDots.distanceMin)
        largeDots.distanceMax: \(viewModel.largeDots.distanceMax)
        
        // Medium Dot Parameters
        mediumDots.enabled: \(viewModel.mediumDots.enabled)
        mediumDots.radiusMin: \(viewModel.mediumDots.radiusMin)
        mediumDots.radiusMax: \(viewModel.mediumDots.radiusMax)
        mediumDots.countMin: \(viewModel.mediumDots.countMin)
        mediumDots.countMax: \(viewModel.mediumDots.countMax)
        mediumDots.distanceMin: \(viewModel.mediumDots.distanceMin)
        mediumDots.distanceMax: \(viewModel.mediumDots.distanceMax)
        
        // Small Dot Parameters
        smallDots.enabled: \(viewModel.smallDots.enabled)
        smallDots.radiusMin: \(viewModel.smallDots.radiusMin)
        smallDots.radiusMax: \(viewModel.smallDots.radiusMax)
        smallDots.countMin: \(viewModel.smallDots.countMin)
        smallDots.countMax: \(viewModel.smallDots.countMax)
        smallDots.distanceMin: \(viewModel.smallDots.distanceMin)
        smallDots.distanceMax: \(viewModel.smallDots.distanceMax)
        
        // Splash Parameters
        splashes.enabled: \(viewModel.splashes.enabled)
        splashes.countMin: \(viewModel.splashes.countMin)
        splashes.countMax: \(viewModel.splashes.countMax)
        splashes.widthMin: \(viewModel.splashes.widthMin)
        splashes.widthMax: \(viewModel.splashes.widthMax)
        splashes.distanceMin: \(viewModel.splashes.distanceMin)
        splashes.distanceMax: \(viewModel.splashes.distanceMax)
        """
    }
}

// MARK: - Helper Views

struct DotParameterSection: View {
    let title: String
    @Binding var enabled: Bool
    @Binding var radiusMin: CGFloat
    @Binding var radiusMax: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                Toggle("Enabled", isOn: $enabled)
                    .font(.subheadline)
                
                if enabled {
                    ParameterSlider(
                        title: "Radius Min",
                        value: Binding(
                            get: { Double(radiusMin) },
                            set: { radiusMin = CGFloat($0) }
                        ),
                        range: 5...100
                    )
                    
                    ParameterSlider(
                        title: "Radius Max",
                        value: Binding(
                            get: { Double(radiusMax) },
                            set: { radiusMax = CGFloat($0) }
                        ),
                        range: 5...100
                    )
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
}

struct ScatteredDotParameterSection: View {
    let title: String
    @Binding var enabled: Bool
    @Binding var radiusMin: CGFloat
    @Binding var radiusMax: CGFloat
    @Binding var countMin: Int
    @Binding var countMax: Int
    @Binding var distanceMin: CGFloat
    @Binding var distanceMax: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                Toggle("Enabled", isOn: $enabled)
                    .font(.subheadline)
                
                if enabled {
                    ParameterSlider(
                        title: "Radius Min",
                        value: Binding(
                            get: { Double(radiusMin) },
                            set: { radiusMin = CGFloat($0) }
                        ),
                        range: 5...100
                    )
                    
                    ParameterSlider(
                        title: "Radius Max",
                        value: Binding(
                            get: { Double(radiusMax) },
                            set: { radiusMax = CGFloat($0) }
                        ),
                        range: 5...100
                    )
                    
                    ParameterSlider(
                        title: "Count Min",
                        value: Binding(
                            get: { Double(countMin) },
                            set: { countMin = Int($0) }
                        ),
                        range: 0...20
                    )
                    
                    ParameterSlider(
                        title: "Count Max",
                        value: Binding(
                            get: { Double(countMax) },
                            set: { countMax = Int($0) }
                        ),
                        range: 0...20
                    )
                    
                    ParameterSlider(
                        title: "Distance Min",
                        value: Binding(
                            get: { Double(distanceMin) },
                            set: { distanceMin = CGFloat($0) }
                        ),
                        range: 10...300
                    )
                    
                    ParameterSlider(
                        title: "Distance Max",
                        value: Binding(
                            get: { Double(distanceMax) },
                            set: { distanceMax = CGFloat($0) }
                        ),
                        range: 10...300
                    )
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
}

struct ParameterSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(value, specifier: "%.1f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $value, in: range)
                .accentColor(.blue)
        }
    }
}