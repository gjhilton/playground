// Version: 3.07
import SwiftUI
import UIKit
import MetalKit
import simd
import Combine

// MARK: - Extensions

extension Color {
    var simd3: SIMD3<Float> {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SIMD3<Float>(Float(r), Float(g), Float(b))
    }
}

// MARK: - Random Number Generation

/// Protocol for injectable random number generation to enable testability and reproducibility
protocol RandomGenerator {
    func float(in range: ClosedRange<Float>) -> Float
    func int(in range: ClosedRange<Int>) -> Int
    func cgFloat(in range: ClosedRange<CGFloat>) -> CGFloat
    func double(in range: ClosedRange<Double>) -> Double
}

/// Default implementation using system random number generator
class DefaultRandomGenerator: RandomGenerator {
    func float(in range: ClosedRange<Float>) -> Float {
        Float.random(in: range)
    }
    
    func int(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range)
    }
    
    func cgFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        CGFloat.random(in: range)
    }
    
    func double(in range: ClosedRange<Double>) -> Double {
        Double.random(in: range)
    }
}

/// Deterministic random number generator for testing with reproducible sequences
/// Uses Linear Congruential Generator (LCG) with standard constants
class SeededRandomGenerator: RandomGenerator {
    private var state: UInt32
    
    // LCG constants (from Numerical Recipes)
    private let a: UInt32 = 1664525
    private let c: UInt32 = 1013904223
    
    init(seed: UInt64) {
        self.state = UInt32(seed & 0xFFFFFFFF)
    }
    
    private func nextUInt32() -> UInt32 {
        state = state &* a &+ c // Use overflow operators for proper wraparound
        return state
    }
    
    private func nextFloat() -> Float {
        Float(nextUInt32()) / Float(UInt32.max)
    }
    
    func float(in range: ClosedRange<Float>) -> Float {
        range.lowerBound + nextFloat() * (range.upperBound - range.lowerBound)
    }
    
    func int(in range: ClosedRange<Int>) -> Int {
        let count = range.count
        let randomValue = Int(nextUInt32() % UInt32(count))
        return range.lowerBound + randomValue
    }
    
    func cgFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        CGFloat(float(in: Float(range.lowerBound)...Float(range.upperBound)))
    }
    
    func double(in range: ClosedRange<Double>) -> Double {
        Double(float(in: Float(range.lowerBound)...Float(range.upperBound)))
    }
}

// MARK: - Data Structures

/// Metal-compatible dot structure for efficient GPU transfer
/// Uses SIMD types for optimal alignment and cache coherence
struct MetalDot: Equatable, Hashable {
    var position: SIMD2<Float> // (x, y) in Metal coordinate space [0,1]
    var radius: Float // Normalized radius [0,1]
    var type: Int32 // Dot type enum raw value [0-4]
    
    init(position: SIMD2<Float>, radius: Float, type: Int32) {
        self.position = position
        self.radius = radius
        self.type = type
    }
}

/// Aggregated metal data for efficient GPU operations
/// Cached results with dirty flag tracking for performance optimization
struct MetalDotData: Equatable {
    let dots: [MetalDot]
    let renderMask: UInt32
    
    init(dots: [MetalDot], renderMask: UInt32) {
        self.dots = dots
        self.renderMask = renderMask
    }
}

/// Central dot configuration for main ink splat blob
class CentralDotParams: ObservableObject {
    @Published var enabled: Bool = true
    @Published var radiusMin: Float = 0.15
    @Published var radiusMax: Float = 0.3
    @Published var colorVariation: Float = 0.15
}

/// Large satellite dot configuration for primary splat features
class LargeDotParams: ObservableObject {
    @Published var enabled: Bool = true
    @Published var count: Int = 25
    @Published var radiusMin: Float = 0.02
    @Published var radiusMax: Float = 0.08
    @Published var maxDistance: Float = 0.15
    @Published var colorVariation: Float = 0.25
}

/// Medium satellite dot configuration for secondary splat features
class MediumDotParams: ObservableObject {
    @Published var enabled: Bool = true
    @Published var count: Int = 40
    @Published var radiusMin: Float = 0.005
    @Published var radiusMax: Float = 0.025
    @Published var maxDistance: Float = 0.2
    @Published var colorVariation: Float = 0.4
}

/// Small satellite dot configuration for fine detail features
class SmallDotParams: ObservableObject {
    @Published var enabled: Bool = true
    @Published var count: Int = 80
    @Published var radiusMin: Float = 0.001
    @Published var radiusMax: Float = 0.008
    @Published var maxDistance: Float = 0.35
    @Published var colorVariation: Float = 0.6
}

/// High-performance rendering configuration
class RenderingParams: ObservableObject {
    @Published var influenceThreshold: Float = 0.001
    @Published var useSeededRNG: Bool = false
    @Published var rngSeed: UInt64 = 12345
    
    // Background pass configuration
    @Published var backgroundPassEnabled: Bool = true
    @Published var backgroundPassColor: Color = Color(red: 0.8, green: 0.1, blue: 0.1)
    @Published var backgroundPassOpacity: Float = 1.0
    @Published var backgroundCentralDot: Bool = true
    @Published var backgroundLargeDots: Bool = true
    @Published var backgroundMediumDots: Bool = true
    @Published var backgroundSmallDots: Bool = true
    
    // Foreground pass configuration
    @Published var foregroundPassEnabled: Bool = true
    @Published var foregroundPassColor: Color = Color(red: 0.3, green: 0.5, blue: 0.8)
    @Published var foregroundPassOpacity: Float = 0.6
    @Published var foregroundCentralDot: Bool = false
    @Published var foregroundLargeDots: Bool = true
    @Published var foregroundMediumDots: Bool = true
    @Published var foregroundSmallDots: Bool = false
}

// MARK: - Performance Monitoring

/// Performance metrics tracking for Metal rendering optimization
class PerformanceMonitor: ObservableObject {
    @Published var frameTime: TimeInterval = 0.0
    @Published var renderTime: TimeInterval = 0.0
    @Published var droppedFrames: Int = 0
    @Published var metalUtilization: Double = 0.0
    
    private static var shared = PerformanceMonitor()
    private var displayLink: CADisplayLink?
    private var lastFrameTime: CFAbsoluteTime = 0
    private var frameCount: Int = 0
    private var renderStartTime: CFAbsoluteTime = 0
    
    static func startDisplayTracking() {
        guard shared.displayLink == nil else { return }
        
        shared.displayLink = CADisplayLink(target: shared, selector: #selector(shared.displayLinkTick))
        shared.displayLink?.add(to: .main, forMode: .common)
        shared.lastFrameTime = CFAbsoluteTimeGetCurrent()
    }
    
    static func stopDisplayTracking() {
        shared.displayLink?.invalidate()
        shared.displayLink = nil
    }
    
    @objc private func displayLinkTick() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        if lastFrameTime > 0 {
            frameTime = currentTime - lastFrameTime
            if frameTime > 1.0/50.0 { // Dropped if slower than 50fps
                droppedFrames += 1
            }
        }
        lastFrameTime = currentTime
        frameCount += 1
    }
    
    static func startRenderTiming() {
        shared.renderStartTime = CFAbsoluteTimeGetCurrent()
    }
    
    static func endRenderTiming() {
        let renderEndTime = CFAbsoluteTimeGetCurrent()
        shared.renderTime = renderEndTime - shared.renderStartTime
    }
}

// MARK: - Constants

/// Centralized rendering constants for consistent behavior and easy tuning
enum RenderingConstants {
    // UI and Build Configuration
    static let showParameterControls: Bool = true
    
    // Performance and caching settings
    static let enablePerformanceLogging: Bool = false
    static let reactiveUpdateDebounceMs: Int = 16 // ~60fps debouncing
    
    // Metal rendering masks for selective dot rendering
    static let centralDotMask: UInt32 = 1 << 0
    static let largeDotMask: UInt32 = 1 << 1
    static let mediumDotMask: UInt32 = 1 << 2
    static let smallDotMask: UInt32 = 1 << 3
}

/// Render pass configuration for multi-pass rendering effects
struct RenderPass {
    let name: String
    let enabled: Bool
    let color: SIMD3<Float>
    let renderMask: UInt32
    let opacity: Float
    let zIndex: Double
}

// MARK: - View Model

/// Primary view model coordinating splat state and Metal rendering data
/// Implements reactive parameter binding with performance-optimized update batching
class SplatterViewModel: ObservableObject {
    @Published var splatData: [MetalDot] = []
    @Published var metalData: MetalDotData = MetalDotData(dots: [], renderMask: 0)
    
    // Parameter groups with reactive bindings
    @Published var centralDot = CentralDotParams()
    @Published var largeDots = LargeDotParams()
    @Published var mediumDots = MediumDotParams()
    @Published var smallDots = SmallDotParams()
    @Published var rendering = RenderingParams()
    
    // Cached computation state
    private var isDirty: Bool = true
    private var cancellables = Set<AnyCancellable>()
    
    var renderPasses: [RenderPass] {
        [
            RenderPass(
                name: "background",
                enabled: rendering.backgroundPassEnabled,
                color: rendering.backgroundPassColor.simd3,
                renderMask: computeBackgroundRenderMask(),
                opacity: rendering.backgroundPassOpacity,
                zIndex: 0
            ),
            RenderPass(
                name: "foreground",
                enabled: rendering.foregroundPassEnabled,
                color: rendering.foregroundPassColor.simd3,
                renderMask: computeForegroundRenderMask(),
                opacity: rendering.foregroundPassOpacity,
                zIndex: 1
            )
        ]
    }
    
    init() {
        setupReactiveBindings()
    }
    
    private func computeBackgroundRenderMask() -> UInt32 {
        var mask: UInt32 = 0
        if rendering.backgroundCentralDot { mask |= RenderingConstants.centralDotMask }
        if rendering.backgroundLargeDots { mask |= RenderingConstants.largeDotMask }
        if rendering.backgroundMediumDots { mask |= RenderingConstants.mediumDotMask }
        if rendering.backgroundSmallDots { mask |= RenderingConstants.smallDotMask }
        return mask
    }
    
    private func computeForegroundRenderMask() -> UInt32 {
        var mask: UInt32 = 0
        if rendering.foregroundCentralDot { mask |= RenderingConstants.centralDotMask }
        if rendering.foregroundLargeDots { mask |= RenderingConstants.largeDotMask }
        if rendering.foregroundMediumDots { mask |= RenderingConstants.mediumDotMask }
        if rendering.foregroundSmallDots { mask |= RenderingConstants.smallDotMask }
        return mask
    }
    
    private func computeRenderMask() -> UInt32 {
        // Generate dots for any type enabled in either pass
        let backgroundMask = computeBackgroundRenderMask()
        let foregroundMask = computeForegroundRenderMask()
        return backgroundMask | foregroundMask
    }
    
    func addSplat(at point: CGPoint, screenWidth: CGFloat, screenHeight: CGFloat) {
        let normalizedX = Float(point.x / screenWidth)
        let normalizedY = Float(point.y / screenHeight)
        let center = SIMD2<Float>(normalizedX, normalizedY)
        
        let rng: RandomGenerator = rendering.useSeededRNG 
            ? SeededRandomGenerator(seed: rendering.rngSeed)
            : DefaultRandomGenerator()
        
        var newDots: [MetalDot] = []
        
        // Central dot
        if centralDot.enabled {
            let minRadius = min(centralDot.radiusMin, centralDot.radiusMax)
            let maxRadius = max(centralDot.radiusMin, centralDot.radiusMax)
            let radius = rng.float(in: minRadius...maxRadius)
            newDots.append(MetalDot(position: center, radius: radius, type: 0))
        }
        
        // Large satellite dots
        if largeDots.enabled {
            for _ in 0..<largeDots.count {
                let angle = rng.float(in: 0...(2 * Float.pi))
                let distance = rng.float(in: 0...largeDots.maxDistance)
                let minRadius = min(largeDots.radiusMin, largeDots.radiusMax)
                let maxRadius = max(largeDots.radiusMin, largeDots.radiusMax)
                let radius = rng.float(in: minRadius...maxRadius)
                
                let offsetX = cos(angle) * distance
                let offsetY = sin(angle) * distance
                let position = SIMD2<Float>(center.x + offsetX, center.y + offsetY)
                
                newDots.append(MetalDot(position: position, radius: radius, type: 1))
            }
        }
        
        // Medium satellite dots
        if mediumDots.enabled {
            for _ in 0..<mediumDots.count {
                let angle = rng.float(in: 0...(2 * Float.pi))
                let distance = rng.float(in: 0...mediumDots.maxDistance)
                let minRadius = min(mediumDots.radiusMin, mediumDots.radiusMax)
                let maxRadius = max(mediumDots.radiusMin, mediumDots.radiusMax)
                let radius = rng.float(in: minRadius...maxRadius)
                
                let offsetX = cos(angle) * distance
                let offsetY = sin(angle) * distance
                let position = SIMD2<Float>(center.x + offsetX, center.y + offsetY)
                
                newDots.append(MetalDot(position: position, radius: radius, type: 2))
            }
        }
        
        // Small satellite dots
        if smallDots.enabled {
            for _ in 0..<smallDots.count {
                let angle = rng.float(in: 0...(2 * Float.pi))
                let distance = rng.float(in: 0...smallDots.maxDistance)
                let minRadius = min(smallDots.radiusMin, smallDots.radiusMax)
                let maxRadius = max(smallDots.radiusMin, smallDots.radiusMax)
                let radius = rng.float(in: minRadius...maxRadius)
                
                let offsetX = cos(angle) * distance
                let offsetY = sin(angle) * distance
                let position = SIMD2<Float>(center.x + offsetX, center.y + offsetY)
                
                newDots.append(MetalDot(position: position, radius: radius, type: 3))
            }
        }
        
        splatData.append(contentsOf: newDots)
        isDirty = true
        updateMetalData()
    }
    
    func clear() {
        splatData.removeAll()
        isDirty = true
        updateMetalData()
    }
    
    func updateMetalData() {
        guard isDirty else { return }
        
        let renderMask = computeRenderMask()
        metalData = MetalDotData(dots: splatData, renderMask: renderMask)
        isDirty = false
    }
    
    private func setupReactiveBindings() {
        // GEOMETRY-AFFECTING CHANGES: These require metalData recomputation
        
        // Parameter changes that affect dot generation (when new splats are added)
        Publishers.CombineLatest4(centralDot.$radiusMin, centralDot.$radiusMax, largeDots.$count, largeDots.$radiusMin)
            .combineLatest(Publishers.CombineLatest4(largeDots.$radiusMax, largeDots.$maxDistance, mediumDots.$count, mediumDots.$radiusMin))
            .combineLatest(Publishers.CombineLatest4(mediumDots.$radiusMax, mediumDots.$maxDistance, smallDots.$count, smallDots.$radiusMin))
            .combineLatest(Publishers.CombineLatest(smallDots.$radiusMax, smallDots.$maxDistance))
            .debounce(for: .milliseconds(RenderingConstants.reactiveUpdateDebounceMs), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.updateMetalData() }
            .store(in: &cancellables)
        
        // Dot type visibility changes (affect renderMask but not metalData geometry)
        // Background pass dot type changes
        rendering.$backgroundCentralDot
            .combineLatest(rendering.$backgroundLargeDots, rendering.$backgroundMediumDots, rendering.$backgroundSmallDots)
            .combineLatest(rendering.$foregroundCentralDot)
            .combineLatest(rendering.$foregroundLargeDots, rendering.$foregroundMediumDots, rendering.$foregroundSmallDots)
            .debounce(for: .milliseconds(RenderingConstants.reactiveUpdateDebounceMs), scheduler: RunLoop.main)
            .sink { [weak self] _ in 
                // Only trigger UI update - renderMask changes are handled in MetalOverlayView
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // VISUAL-ONLY CHANGES: Only affect rendering appearance - no geometry recomputation needed
        
        // Rendering pass enabled/disabled (affects render pass list but not geometry)
        rendering.$backgroundPassEnabled
            .combineLatest(rendering.$foregroundPassEnabled)
            .debounce(for: .milliseconds(RenderingConstants.reactiveUpdateDebounceMs), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in 
                // Only trigger UI update, no metalData recomputation needed
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Color changes (pure visual - no geometry impact)
        rendering.$backgroundPassColor
            .combineLatest(rendering.$foregroundPassColor)
            .debounce(for: .milliseconds(RenderingConstants.reactiveUpdateDebounceMs), scheduler: RunLoop.main)
            .sink { [weak self] bgColor, fgColor in 
                print("[DEBUG] Color changed - BG: \(bgColor), FG: \(fgColor)")
                // Trigger UI update to re-evaluate renderPasses
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

struct SplatterView: View {
    @StateObject private var viewModel = SplatterViewModel()
    @State private var screenSize: CGSize = .zero
    
    var body: some View {
        // Simple overlay - always transparent and non-interactive
        ZStack {
            ForEach(viewModel.renderPasses, id: \.name) { renderPass in
                if renderPass.enabled {
                    MetalOverlayView(
                        dots: viewModel.metalData.dots,
                        splatColor: renderPass.color,
                        renderMask: renderPass.renderMask,
                        influenceThreshold: viewModel.rendering.influenceThreshold
                    )
                    .allowsHitTesting(false)
                    .blendMode(.multiply)
                    .opacity(Double(renderPass.opacity))
                    .zIndex(renderPass.zIndex)
                }
            }
        }
        .onAppear {
            screenSize = UIScreen.main.bounds.size
            print("[DEBUG] SplatterView appeared - performance logging enabled: \(RenderingConstants.enablePerformanceLogging)")
            PerformanceMonitor.startDisplayTracking()
            viewModel.updateMetalData() // Initial metal data setup
        }
        .onDisappear {
            PerformanceMonitor.stopDisplayTracking()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("SplatterAddSplat"))) { notification in
            if let location = notification.object as? CGPoint {
                viewModel.addSplat(at: location, screenWidth: screenSize.width, screenHeight: screenSize.height)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("SplatterClear"))) { _ in
            viewModel.clear()
        }
    }
}

// MARK: - Editor Layout

struct SplatterEditorView: View {
    @StateObject private var viewModel = SplatterViewModel()
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // Left panel: Parameter controls
                ParameterControlPanel(viewModel: viewModel)
                    .frame(width: 350)
                    .background(Color(.systemGray6))
                
                // Right panel: Content + splatter overlay
                ZStack {
                    // Background content
                    Color.white.ignoresSafeArea()
                    VStack {
                        Spacer()
                        Button("Clear Splats") {
                            viewModel.clear()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.black)
                        .foregroundColor(.white)
                        .font(.title2)
                        Spacer()
                        Text("3.00")
                            .font(.system(size: 36, weight: .regular, design: .default))
                            .foregroundColor(.black)
                            .padding(.bottom, 20)
                    }
                    
                    // Splatter overlay
                    ZStack {
                        ForEach(viewModel.renderPasses, id: \.name) { renderPass in
                            if renderPass.enabled {
                                MetalOverlayView(
                                    dots: viewModel.metalData.dots,
                                    splatColor: renderPass.color,
                                    renderMask: renderPass.renderMask,
                                    influenceThreshold: viewModel.rendering.influenceThreshold
                                )
                                .allowsHitTesting(false)
                                .blendMode(.multiply)
                                .opacity(Double(renderPass.opacity))
                                .zIndex(renderPass.zIndex)
                            }
                        }
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let adjustedLocation = CGPoint(
                                x: value.location.x,
                                y: value.location.y
                            )
                            viewModel.addSplat(at: adjustedLocation, screenWidth: geo.size.width - 350, screenHeight: geo.size.height)
                        }
                )
            }
        }
        .onAppear {
            print("[DEBUG] SplatterEditorView appeared")
            PerformanceMonitor.startDisplayTracking()
            viewModel.updateMetalData()
        }
        .onDisappear {
            PerformanceMonitor.stopDisplayTracking()
        }
    }
}

// MARK: - Parameter Control Panel

struct ParameterControlPanel: View {
    @ObservedObject var viewModel: SplatterViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header with clear button
                HStack {
                    Text("Ink Splatter Controls")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Button("Clear All") {
                        viewModel.clear()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding(.bottom, 8)
                
                // Color Controls
                GroupBox("Colors") {
                    VStack(spacing: 12) {
                        VStack {
                            HStack {
                                Toggle("Background Pass", isOn: $viewModel.rendering.backgroundPassEnabled)
                                Spacer()
                            }
                            if viewModel.rendering.backgroundPassEnabled {
                                VStack {
                                    if #available(iOS 14.0, *) {
                                        ColorPicker("Background Color", selection: $viewModel.rendering.backgroundPassColor)
                                    } else {
                                        HStack {
                                            Text("Background Color")
                                            Spacer()
                                            Rectangle()
                                                .fill(viewModel.rendering.backgroundPassColor)
                                                .frame(width: 30, height: 30)
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                                HStack {
                                    Text("Opacity: \(viewModel.rendering.backgroundPassOpacity, specifier: "%.2f")")
                                    Spacer()
                                }
                                Slider(value: $viewModel.rendering.backgroundPassOpacity, in: 0...1)
                                
                                // Background pass dot type controls
                                VStack(spacing: 8) {
                                    Text("Dot Types").font(.subheadline).foregroundColor(.secondary)
                                    HStack {
                                        Toggle("Central", isOn: $viewModel.rendering.backgroundCentralDot)
                                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                                        Toggle("Large", isOn: $viewModel.rendering.backgroundLargeDots)
                                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                                    }
                                    HStack {
                                        Toggle("Medium", isOn: $viewModel.rendering.backgroundMediumDots)
                                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                                        Toggle("Small", isOn: $viewModel.rendering.backgroundSmallDots)
                                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        Divider()
                        
                        VStack {
                            HStack {
                                Toggle("Foreground Pass", isOn: $viewModel.rendering.foregroundPassEnabled)
                                Spacer()
                            }
                            if viewModel.rendering.foregroundPassEnabled {
                                VStack {
                                    if #available(iOS 14.0, *) {
                                        ColorPicker("Foreground Color", selection: $viewModel.rendering.foregroundPassColor)
                                    } else {
                                        HStack {
                                            Text("Foreground Color")
                                            Spacer()
                                            Rectangle()
                                                .fill(viewModel.rendering.foregroundPassColor)
                                                .frame(width: 30, height: 30)
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                                HStack {
                                    Text("Opacity: \(viewModel.rendering.foregroundPassOpacity, specifier: "%.2f")")
                                    Spacer()
                                }
                                Slider(value: $viewModel.rendering.foregroundPassOpacity, in: 0...1)
                                
                                // Foreground pass dot type controls
                                VStack(spacing: 8) {
                                    Text("Dot Types").font(.subheadline).foregroundColor(.secondary)
                                    HStack {
                                        Toggle("Central", isOn: $viewModel.rendering.foregroundCentralDot)
                                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                                        Toggle("Large", isOn: $viewModel.rendering.foregroundLargeDots)
                                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                                    }
                                    HStack {
                                        Toggle("Medium", isOn: $viewModel.rendering.foregroundMediumDots)
                                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                                        Toggle("Small", isOn: $viewModel.rendering.foregroundSmallDots)
                                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                }
                
                // Central Dot Parameters
                GroupBox("Central Dot Parameters") {
                    VStack(spacing: 8) {
                        VStack(spacing: 4) {
                            HStack {
                                Text("Min Radius: \(viewModel.centralDot.radiusMin, specifier: "%.3f")")
                                Spacer()
                            }
                            Slider(value: $viewModel.centralDot.radiusMin, in: 0.01...0.5)
                            
                            HStack {
                                Text("Max Radius: \(viewModel.centralDot.radiusMax, specifier: "%.3f")")
                                Spacer()
                            }
                            Slider(value: $viewModel.centralDot.radiusMax, in: 0.01...0.5)
                        }
                    }
                }
                
                // Large Dots Parameters
                GroupBox("Large Dots Parameters") {
                    VStack(spacing: 8) {
                        VStack(spacing: 4) {
                            HStack {
                                Text("Count: \(viewModel.largeDots.count)")
                                Spacer()
                            }
                            Slider(value: Binding(
                                get: { Double(viewModel.largeDots.count) },
                                set: { viewModel.largeDots.count = Int($0) }
                            ), in: 0...100, step: 1)
                            
                            HStack {
                                Text("Min Radius: \(viewModel.largeDots.radiusMin, specifier: "%.3f")")
                                Spacer()
                            }
                            Slider(value: $viewModel.largeDots.radiusMin, in: 0.001...0.2)
                            
                            HStack {
                                Text("Max Radius: \(viewModel.largeDots.radiusMax, specifier: "%.3f")")
                                Spacer()
                            }
                            Slider(value: $viewModel.largeDots.radiusMax, in: 0.001...0.2)
                            
                            HStack {
                                Text("Max Distance: \(viewModel.largeDots.maxDistance, specifier: "%.3f")")
                                Spacer()
                            }
                            Slider(value: $viewModel.largeDots.maxDistance, in: 0.05...0.5)
                        }
                    }
                }
                
                // Medium Dots Parameters
                GroupBox("Medium Dots Parameters") {
                    VStack(spacing: 8) {
                        VStack(spacing: 4) {
                            HStack {
                                Text("Count: \(viewModel.mediumDots.count)")
                                Spacer()
                            }
                            Slider(value: Binding(
                                get: { Double(viewModel.mediumDots.count) },
                                set: { viewModel.mediumDots.count = Int($0) }
                            ), in: 0...150, step: 1)
                            
                            HStack {
                                Text("Min Radius: \(viewModel.mediumDots.radiusMin, specifier: "%.4f")")
                                Spacer()
                            }
                            Slider(value: $viewModel.mediumDots.radiusMin, in: 0.001...0.1)
                            
                            HStack {
                                Text("Max Radius: \(viewModel.mediumDots.radiusMax, specifier: "%.4f")")
                                Spacer()
                            }
                            Slider(value: $viewModel.mediumDots.radiusMax, in: 0.001...0.1)
                            
                            HStack {
                                Text("Max Distance: \(viewModel.mediumDots.maxDistance, specifier: "%.3f")")
                                Spacer()
                            }
                            Slider(value: $viewModel.mediumDots.maxDistance, in: 0.1...0.6)
                        }
                    }
                }
                
                // Small Dots Parameters
                GroupBox("Small Dots Parameters") {
                    VStack(spacing: 8) {
                        VStack(spacing: 4) {
                            HStack {
                                Text("Count: \(viewModel.smallDots.count)")
                                Spacer()
                            }
                            Slider(value: Binding(
                                get: { Double(viewModel.smallDots.count) },
                                set: { viewModel.smallDots.count = Int($0) }
                            ), in: 0...200, step: 1)
                            
                            HStack {
                                Text("Min Radius: \(viewModel.smallDots.radiusMin, specifier: "%.4f")")
                                Spacer()
                            }
                            Slider(value: $viewModel.smallDots.radiusMin, in: 0.0005...0.05)
                            
                            HStack {
                                Text("Max Radius: \(viewModel.smallDots.radiusMax, specifier: "%.4f")")
                                Spacer()
                            }
                            Slider(value: $viewModel.smallDots.radiusMax, in: 0.0005...0.05)
                            
                            HStack {
                                Text("Max Distance: \(viewModel.smallDots.maxDistance, specifier: "%.3f")")
                                Spacer()
                            }
                            Slider(value: $viewModel.smallDots.maxDistance, in: 0.2...0.8)
                        }
                    }
                }
                
                // Performance Controls
                GroupBox("Performance") {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Influence Threshold: \(viewModel.rendering.influenceThreshold, specifier: "%.4f")")
                            Spacer()
                        }
                        Slider(value: $viewModel.rendering.influenceThreshold, in: 0.0001...0.01, step: 0.0001)
                    }
                }
                
                // RNG Controls
                GroupBox("Random Generation") {
                    VStack(spacing: 8) {
                        Toggle("Use Seeded RNG", isOn: $viewModel.rendering.useSeededRNG)
                        if viewModel.rendering.useSeededRNG {
                            HStack {
                                Text("Seed: \(Int(viewModel.rendering.rngSeed))")
                                Spacer()
                                Button("Random Seed") {
                                    viewModel.rendering.rngSeed = UInt64.random(in: 1...99999)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Metal Rendering

struct MetalOverlayView: UIViewRepresentable {
    let dots: [MetalDot]
    let splatColor: SIMD3<Float>
    let renderMask: UInt32
    let influenceThreshold: Float
    
    func makeUIView(context: UIViewRepresentableContext<MetalOverlayView>) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.backgroundColor = UIColor.clear
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0)
        mtkView.isOpaque = false
        mtkView.framebufferOnly = true
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
        mtkView.delegate = context.coordinator
        mtkView.setNeedsDisplay()
        return mtkView
    }
    func updateUIView(_ uiView: MTKView, context: UIViewRepresentableContext<MetalOverlayView>) {
        let coordinator = context.coordinator
        
        // Check if color changed
        if coordinator.splatColor != splatColor {
            coordinator.updateColor(splatColor)
        }
        
        // Check if influence threshold changed
        if coordinator.influenceThreshold != influenceThreshold {
            coordinator.updateInfluenceThreshold(influenceThreshold)
        }
        
        _ = coordinator.stateManager.updateRenderMask(renderMask)
        _ = coordinator.stateManager.updateMetalDots(dots)
        uiView.setNeedsDisplay()
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(splatColor: splatColor, influenceThreshold: influenceThreshold)
    }
    class Coordinator: NSObject, MTKViewDelegate {
        var splatColor: SIMD3<Float>
        var influenceThreshold: Float
        let stateManager: MetalStateManager
        private let metalService: MetalRenderService
        
        init(splatColor: SIMD3<Float>, influenceThreshold: Float) {
            self.splatColor = splatColor
            self.influenceThreshold = influenceThreshold
            self.stateManager = MetalStateManager()
            self.metalService = MetalRenderService()
            super.init()
        }
        
        func updateColor(_ newColor: SIMD3<Float>) {
            self.splatColor = newColor
        }
        
        func updateInfluenceThreshold(_ newThreshold: Float) {
            self.influenceThreshold = newThreshold
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle size changes if needed
        }
        
        func draw(in view: MTKView) {
            guard let device = view.device,
                  let drawable = view.currentDrawable else { return }
            
            let renderStartTime = CFAbsoluteTimeGetCurrent()
            PerformanceMonitor.startRenderTiming()
            
            let aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
            
            _ = metalService.render(
                device: device,
                drawable: drawable,
                dots: stateManager.metalDots,
                splatColor: splatColor,
                renderMask: stateManager.renderMask,
                influenceThreshold: influenceThreshold,
                aspectRatio: aspectRatio
            )
            
            PerformanceMonitor.endRenderTiming()
            
            if RenderingConstants.enablePerformanceLogging {
                let renderTime = CFAbsoluteTimeGetCurrent() - renderStartTime
                print("[PERF] Metal render: \(String(format: "%.3f", renderTime * 1000))ms")
            }
        }
    }
}

// MARK: - Metal Services

/// Manages Metal rendering state with performance-optimized caching
class MetalStateManager {
    private(set) var metalDots: [MetalDot] = []
    private(set) var renderMask: UInt32 = 0
    private var dotsBuffer: MTLBuffer?
    private var isDotsDirty: Bool = true
    private var isMaskDirty: Bool = true
    
    func updateMetalDots(_ newDots: [MetalDot]) -> Bool {
        guard newDots != metalDots else { return false }
        metalDots = newDots
        isDotsDirty = true
        return true
    }
    
    func updateRenderMask(_ newMask: UInt32) -> Bool {
        guard newMask != renderMask else { return false }
        renderMask = newMask
        isMaskDirty = true
        return true
    }
    
    var needsBufferUpdate: Bool {
        isDotsDirty
    }
    
    func markBuffersClean() {
        isDotsDirty = false
        isMaskDirty = false
    }
}

/// High-performance Metal rendering service with shader optimization
class MetalRenderService {
    private var pipelineState: MTLRenderPipelineState?
    private var device: MTLDevice?
    
    private func setupPipeline(device: MTLDevice) -> Bool {
        guard self.device !== device else { return pipelineState != nil }
        self.device = device
        
        guard let library = try? device.makeLibrary(source: metalShaderSource, options: nil) else {
            print("Failed to create Metal library from shader source")
            return false
        }
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            return true
        } catch {
            print("Failed to create pipeline state: \(error)")
            return false
        }
    }
    
    func render(device: MTLDevice, drawable: CAMetalDrawable, dots: [MetalDot], splatColor: SIMD3<Float>, renderMask: UInt32, influenceThreshold: Float, aspectRatio: Float) -> Bool {
        guard setupPipeline(device: device),
              let pipelineState = pipelineState,
              let commandQueue = device.makeCommandQueue(),
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return false
        }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return false
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        let vertices: [Float] = [
            -1.0, -1.0, 0.0, 1.0,
             1.0, -1.0, 1.0, 1.0,
            -1.0,  1.0, 0.0, 0.0,
             1.0,  1.0, 1.0, 0.0
        ]
        
        let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.stride, options: [])
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Create dots buffer
        let dotsBuffer = device.makeBuffer(bytes: dots, length: max(1, dots.count) * MemoryLayout<MetalDot>.stride, options: [])
        renderEncoder.setFragmentBuffer(dotsBuffer, offset: 0, index: 0)
        
        // Fragment shader uniforms
        var uniforms = FragmentUniforms(
            splatColor: splatColor,
            dotCount: UInt32(dots.count),
            renderMask: renderMask,
            influenceThreshold: influenceThreshold,
            aspectRatio: aspectRatio
        )
        let uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<FragmentUniforms>.stride, options: [])
        renderEncoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 1)
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        return true
    }
}

// MARK: - Metal Shader Structures

struct FragmentUniforms {
    let splatColor: SIMD3<Float>
    let dotCount: UInt32
    let renderMask: UInt32
    let influenceThreshold: Float
    let aspectRatio: Float
}

// MARK: - Metal Shaders

let metalShaderSource = """
#include <metal_stdlib>
using namespace metal;

struct MetalDot {
    float2 position;
    float radius;
    int type;
};

struct FragmentUniforms {
    float3 splatColor;
    uint dotCount;
    uint renderMask;
    float influenceThreshold;
    float aspectRatio;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vertex_main(uint vertexID [[vertex_id]],
                            constant float4 *vertices [[buffer(0)]]) {
    VertexOut out;
    float4 vertexData = vertices[vertexID];
    out.position = float4(vertexData.xy, 0.0, 1.0);
    out.uv = vertexData.zw;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                             constant MetalDot *dots [[buffer(0)]],
                             constant FragmentUniforms &uniforms [[buffer(1)]]) {
    float2 fragCoord = in.uv;
    float totalField = 0.0;
    const float metalDistanceEpsilon = 1e-6;
    
    for (uint i = 0; i < uniforms.dotCount; i++) {
        MetalDot dot = dots[i];
        
        // Check if this dot type is enabled in the render mask
        uint dotTypeMask = 1u << uint(dot.type);
        if ((uniforms.renderMask & dotTypeMask) == 0) {
            continue;
        }
        
        float2 diff = fragCoord - dot.position;
        diff.x *= uniforms.aspectRatio; // Correct for aspect ratio
        float distSq = length_squared(diff);
        float radiusSq = dot.radius * dot.radius;
        
        // Spatial culling - skip dots with negligible influence
        float distance = sqrt(distSq);
        if (distance > dot.radius * 2.0) continue;
        
        // Smooth falloff from center to edge
        float normalizedDist = distance / dot.radius;
        float influence = 1.0 - smoothstep(0.0, 1.0, normalizedDist);
        
        totalField += influence;
    }
    
    float alpha = smoothstep(0.7, 1.0, totalField);
    return float4(uniforms.splatColor, alpha);
}
"""

