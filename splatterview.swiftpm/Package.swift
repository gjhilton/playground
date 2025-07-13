import SwiftUI
import UIKit
import MetalKit
import simd
import Combine

// MARK: - Version Management

/// Single source of truth for version number - UPDATE THIS FOR EVERY CHANGE
struct SplatterViewVersion {
    static let current: String = "3.50"
}

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

// MARK: - Layer Template System

/// Physics parameters for a single layer
struct LayerPhysicsParams {
    var velocityX: Float
    var velocityY: Float
    var force: Float
    var centralElongation: Float
    var particleElongation: Float
    var timeElongation: Float
    var noiseAmplitude: Float
    var velocityRoughness: Float
    var noiseFrequency: Float
    
    static let backgroundDefaults = LayerPhysicsParams(
        velocityX: 0.1, velocityY: 0.1, force: 0.5,
        centralElongation: 2.0, particleElongation: 1.5, timeElongation: 2.0,
        noiseAmplitude: 0.3, velocityRoughness: 0.4, noiseFrequency: 20.0
    )
    
    static let foregroundDefaults = LayerPhysicsParams(
        velocityX: 0.2, velocityY: 0.15, force: 0.7,
        centralElongation: 2.5, particleElongation: 1.8, timeElongation: 2.5,
        noiseAmplitude: 0.4, velocityRoughness: 0.6, noiseFrequency: 25.0
    )
    
    static let dramaticDefaults = LayerPhysicsParams(
        velocityX: 1.5, velocityY: 0.8, force: 1.0,
        centralElongation: 5.0, particleElongation: 3.0, timeElongation: 4.0,
        noiseAmplitude: 0.8, velocityRoughness: 1.2, noiseFrequency: 30.0
    )
}

/// Rendering configuration for a single layer
struct LayerRenderingParams {
    var enabled: Bool
    var color: Color
    var opacity: Float
    var centralDot: Bool
    var largeDots: Bool
    var mediumDots: Bool
    var smallDots: Bool
    var microDots: Bool
    
    static let backgroundDefaults = LayerRenderingParams(
        enabled: true, color: Color(red: 0.8, green: 0.1, blue: 0.1), opacity: 1.0,
        centralDot: true, largeDots: true, mediumDots: true, smallDots: true, microDots: true
    )
    
    static let foregroundDefaults = LayerRenderingParams(
        enabled: true, color: Color(red: 0.3, green: 0.5, blue: 0.8), opacity: 0.6,
        centralDot: false, largeDots: true, mediumDots: true, smallDots: false, microDots: true
    )
    
    static let dramaticDefaults = LayerRenderingParams(
        enabled: false, color: Color(red: 0.6, green: 0.0, blue: 0.0), opacity: 0.8,
        centralDot: true, largeDots: true, mediumDots: true, smallDots: true, microDots: true
    )
}

/// Dot generation parameters for a single layer
struct LayerDotParams {
    var centralRadiusMin: Float
    var centralRadiusMax: Float
    var largeCount: Int
    var largeRadiusMin: Float
    var largeRadiusMax: Float
    var largeMaxDistance: Float
    var mediumCount: Int
    var mediumRadiusMin: Float
    var mediumRadiusMax: Float
    var mediumMaxDistance: Float
    var smallCount: Int
    var smallRadiusMin: Float
    var smallRadiusMax: Float
    var smallMaxDistance: Float
    var microCount: Int
    var microRadiusMin: Float
    var microRadiusMax: Float
    var microMaxDistance: Float
    
    static let backgroundDefaults = LayerDotParams(
        centralRadiusMin: 0.15, centralRadiusMax: 0.3,
        largeCount: 25, largeRadiusMin: 0.02, largeRadiusMax: 0.08, largeMaxDistance: 0.15,
        mediumCount: 40, mediumRadiusMin: 0.005, mediumRadiusMax: 0.025, mediumMaxDistance: 0.2,
        smallCount: 80, smallRadiusMin: 0.001, smallRadiusMax: 0.008, smallMaxDistance: 0.35,
        microCount: 120, microRadiusMin: 0.0005, microRadiusMax: 0.003, microMaxDistance: 0.6
    )
    
    static let foregroundDefaults = LayerDotParams(
        centralRadiusMin: 0.1, centralRadiusMax: 0.2,
        largeCount: 15, largeRadiusMin: 0.015, largeRadiusMax: 0.06, largeMaxDistance: 0.12,
        mediumCount: 25, mediumRadiusMin: 0.004, mediumRadiusMax: 0.02, mediumMaxDistance: 0.15,
        smallCount: 50, smallRadiusMin: 0.0008, smallRadiusMax: 0.006, smallMaxDistance: 0.25,
        microCount: 80, microRadiusMin: 0.0004, microRadiusMax: 0.0025, microMaxDistance: 0.4
    )
    
    static let dramaticDefaults = LayerDotParams(
        centralRadiusMin: 0.2, centralRadiusMax: 0.4,
        largeCount: 35, largeRadiusMin: 0.025, largeRadiusMax: 0.1, largeMaxDistance: 0.2,
        mediumCount: 60, mediumRadiusMin: 0.006, mediumRadiusMax: 0.03, mediumMaxDistance: 0.25,
        smallCount: 100, smallRadiusMin: 0.0012, smallRadiusMax: 0.01, smallMaxDistance: 0.4,
        microCount: 150, microRadiusMin: 0.0006, microRadiusMax: 0.004, microMaxDistance: 0.7
    )
}

/// Complete layer template - combines physics, rendering, and dot parameters
struct LayerTemplate {
    let name: String
    let displayName: String
    var physics: LayerPhysicsParams
    var rendering: LayerRenderingParams
    var dots: LayerDotParams
    var zIndex: Double
    
    static func createDefaultLayers() -> [LayerTemplate] {
        return [
            LayerTemplate(
                name: "layer1", displayName: "Layer 1",
                physics: .backgroundDefaults, rendering: .backgroundDefaults,
                dots: .backgroundDefaults, zIndex: 0
            )
        ]
    }
    
    static func createNewLayer(index: Int) -> LayerTemplate {
        // Cycle through different default presets for variety
        let presetIndex = (index - 1) % 3
        let (physics, rendering, dots): (LayerPhysicsParams, LayerRenderingParams, LayerDotParams)
        
        switch presetIndex {
        case 0:
            (physics, rendering, dots) = (.backgroundDefaults, .backgroundDefaults, .backgroundDefaults)
        case 1:
            (physics, rendering, dots) = (.foregroundDefaults, .foregroundDefaults, .foregroundDefaults)
        default:
            (physics, rendering, dots) = (.dramaticDefaults, .dramaticDefaults, .dramaticDefaults)
        }
        
        return LayerTemplate(
            name: "layer\(index)", 
            displayName: "Layer \(index)",
            physics: physics, 
            rendering: rendering,
            dots: dots, 
            zIndex: Double(index - 1)
        )
    }
}

// MARK: - JSON Configuration

/// JSON-serializable settings structure for export/import
struct SplatterSettings: Codable {
    let splatterViewVersion: String
    let rendering: RenderingSettings
    let randomisation: RandomisationSettings
    let dots: DotParameters
    let layers: LayerSettings
    let dramaticEffects: DramaticEffectsSettings
    
    private enum CodingKeys: String, CodingKey {
        case splatterViewVersion = "splatterView version"
        case rendering
        case randomisation
        case dots
        case layers
        case dramaticEffects
    }
    
    struct RenderingSettings: Codable {
        let influenceThreshold: Float
    }
    
    struct RandomisationSettings: Codable {
        let useSeededRNG: Bool
        let rngSeed: UInt64
    }
    
    struct DotParameters: Codable {
        let central: CentralParams
        let large: LargeParams
        let medium: MediumParams
        let small: SmallParams
        
        struct CentralParams: Codable {
            let radiusMin: Float
            let radiusMax: Float
        }
        
        struct LargeParams: Codable {
            let count: Int
            let radiusMin: Float
            let radiusMax: Float
            let maxDistance: Float
        }
        
        struct MediumParams: Codable {
            let count: Int
            let radiusMin: Float
            let radiusMax: Float
            let maxDistance: Float
        }
        
        struct SmallParams: Codable {
            let count: Int
            let radiusMin: Float
            let radiusMax: Float
            let maxDistance: Float
        }
    }
    
    struct LayerSettings: Codable {
        let background: PassSettings
        let foreground: PassSettings
        
        struct PassSettings: Codable {
            let enabled: Bool
            let color: ColorRGB
            let opacity: Float
            let dotTypes: DotTypeSettings
        }
        
        struct ColorRGB: Codable {
            let r: Double
            let g: Double
            let b: Double
        }
        
        struct DotTypeSettings: Codable {
            let central: Bool
            let large: Bool
            let medium: Bool
            let small: Bool
            let micro: Bool
        }
    }
    
    struct DramaticEffectsSettings: Codable {
        let passEnabled: Bool
        let passColor: LayerSettings.ColorRGB
        let passOpacity: Float
        let dotTypes: LayerSettings.DotTypeSettings
        let velocityX: Float
        let velocityY: Float
        let force: Float
        let centralElongation: Float
        let particleElongation: Float
        let timeElongation: Float
        let noiseAmplitude: Float
        let velocityRoughness: Float
        let noiseFrequency: Float
    }
}

// MARK: - Settings Manager

/// Centralized settings management for JSON import/export and default initialization
class SettingsManager {
    /// Default settings JSON - update this with exported settings to change defaults
    private static let defaultSettingsJSON = """
    {
      "splatterView version": "\(SplatterViewVersion.current)",
      "rendering": {
        "influenceThreshold": 0.001
      },
      "randomisation": {
        "rngSeed": 12345,
        "useSeededRNG": false
      },
      "dots": {
        "central": {
          "radiusMax": 0.3,
          "radiusMin": 0.15
        },
        "large": {
          "count": 25,
          "maxDistance": 0.15,
          "radiusMax": 0.08,
          "radiusMin": 0.02
        },
        "medium": {
          "count": 40,
          "maxDistance": 0.2,
          "radiusMax": 0.025,
          "radiusMin": 0.005
        },
        "small": {
          "count": 80,
          "maxDistance": 0.35,
          "radiusMax": 0.008,
          "radiusMin": 0.001
        }
      },
      "layers": {
        "background": {
          "color": {
            "b": 0.1,
            "g": 0.1,
            "r": 0.8
          },
          "dotTypes": {
            "central": true,
            "large": true,
            "medium": true,
            "small": true,
            "micro": true
          },
          "enabled": true,
          "opacity": 1
        },
        "foreground": {
          "color": {
            "b": 0.8,
            "g": 0.5,
            "r": 0.3
          },
          "dotTypes": {
            "central": false,
            "large": true,
            "medium": true,
            "small": false,
            "micro": true
          },
          "enabled": true,
          "opacity": 0.6
        }
      },
      "dramaticEffects": {
        "passEnabled": false,
        "passColor": {
          "r": 0.6,
          "g": 0.0,
          "b": 0.0
        },
        "passOpacity": 0.8,
        "dotTypes": {
          "central": true,
          "large": true,
          "medium": true,
          "small": true,
          "micro": true
        },
        "velocityX": 1.5,
        "velocityY": 0.8,
        "force": 1.0,
        "centralElongation": 5.0,
        "particleElongation": 3.0,
        "timeElongation": 4.0,
        "noiseAmplitude": 0.8,
        "velocityRoughness": 1.2,
        "noiseFrequency": 30.0
      }
    }
    """
    
    private static let _defaultSettings: SplatterSettings = {
        guard let data = defaultSettingsJSON.data(using: .utf8),
              let settings = try? JSONDecoder().decode(SplatterSettings.self, from: data) else {
            fatalError("Invalid default settings JSON")
        }
        return settings
    }()
    
    static var defaultSettings: SplatterSettings {
        return _defaultSettings
    }
    
    // MARK: - Factory Methods
    
    static func createRenderingParams() -> RenderingParams {
        let params = RenderingParams()
        let settings = defaultSettings
        
        params.influenceThreshold = settings.rendering.influenceThreshold
        params.useSeededRNG = settings.randomisation.useSeededRNG
        params.rngSeed = settings.randomisation.rngSeed
        
        // Initialize with default layers - params.layers is already set by LayerTemplate.createDefaultLayers()
        // The layers array is the single source of truth now
        
        return params
    }
    
    // MARK: - Import/Export
    
    static func exportSettings(from viewModel: SplatterViewModel) -> String {
        return "{\"message\": \"Export functionality needs updating for new layer system\"}"
    }
    
    static func importSettings(json: String, to viewModel: SplatterViewModel) -> Bool {
        guard let data = json.data(using: .utf8) else { return false }
        
        do {
            let settings = try JSONDecoder().decode(SplatterSettings.self, from: data)
            applySettings(settings, to: viewModel)
            return true
        } catch {
            print("JSON import error: \(error)")
            return false
        }
    }
    
    private static func applySettings(_ settings: SplatterSettings, to viewModel: SplatterViewModel) {
        // Apply basic settings only for now
        viewModel.rendering.influenceThreshold = settings.rendering.influenceThreshold
        viewModel.rendering.useSeededRNG = settings.randomisation.useSeededRNG
        viewModel.rendering.rngSeed = settings.randomisation.rngSeed
    }
    
    // MARK: - Utility Methods
    
    private static func colorFromRGB(_ rgb: SplatterSettings.LayerSettings.ColorRGB) -> Color {
        Color(red: rgb.r, green: rgb.g, blue: rgb.b)
    }
    
    private static func rgbFromColor(_ color: Color) -> SplatterSettings.LayerSettings.ColorRGB {
        let simd = color.simd3
        return SplatterSettings.LayerSettings.ColorRGB(
            r: Double(simd.x),
            g: Double(simd.y), 
            b: Double(simd.z)
        )
    }
}

// MARK: - Data Structures

/// Metal-compatible dot structure for efficient GPU transfer
/// Uses SIMD types for optimal alignment and cache coherence
struct MetalDot: Equatable, Hashable {
    var position: SIMD2<Float> // (x, y) in Metal coordinate space [0,1]
    var radius: Float // Normalized radius [0,1]
    var type: Int32 // Dot type enum raw value [0-3]
    var velocity: SIMD2<Float> // Velocity vector for directional effects
    var elongation: Float // Stretch factor [1.0 = circular, >1.0 = elongated]
    
    init(position: SIMD2<Float>, radius: Float, type: DotType, velocity: SIMD2<Float> = SIMD2<Float>(0, 0), elongation: Float = 1.0) {
        self.position = position
        self.radius = radius
        self.type = type.rawValue
        self.velocity = velocity
        self.elongation = elongation
    }
    
    // Legacy initializer for backward compatibility
    init(position: SIMD2<Float>, radius: Float, type: Int32) {
        self.position = position
        self.radius = radius
        self.type = type
        self.velocity = SIMD2<Float>(0, 0)
        self.elongation = 1.0
    }
}

/// Impact data structure for directional splatter effects
struct SplatImpact {
    let position: CGPoint
    let velocity: SIMD2<Float>  // Direction and magnitude
    let force: Float           // Impact strength [0,1]
    let timestamp: Double      // For animation effects
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


/// High-performance rendering configuration
class RenderingParams: ObservableObject {
    @Published var influenceThreshold: Float = 0.001
    @Published var useSeededRNG: Bool = false
    @Published var rngSeed: UInt64 = 12345
    
    // Generic layer system - UI directly binds to this
    @Published var layers: [LayerTemplate] = LayerTemplate.createDefaultLayers()
    
    // Helper methods for layer access
    func getLayer(named name: String) -> LayerTemplate? {
        return layers.first { $0.name == name }
    }
    
    // Layer management methods
    func addLayer() {
        let newIndex = layers.count + 1
        let newLayer = LayerTemplate.createNewLayer(index: newIndex)
        layers.append(newLayer)
        
        // Notify any observers that layers have changed
        objectWillChange.send()
    }
    
    func removeLayer(at index: Int) {
        guard layers.count > 1 && index >= 0 && index < layers.count else {
            print("Cannot remove layer: must have at least one layer")
            return
        }
        
        let removedLayerName = layers[index].name
        layers.remove(at: index)
        
        // Update zIndex values to maintain proper ordering
        for i in 0..<layers.count {
            layers[i].zIndex = Double(i)
        }
        
        // Signal that layer data needs cleanup
        NotificationCenter.default.post(
            name: .layerRemoved, 
            object: removedLayerName
        )
        
        objectWillChange.send()
    }
    
    func duplicateLayer(at index: Int) {
        guard index >= 0 && index < layers.count else { return }
        let originalLayer = layers[index]
        let newIndex = layers.count + 1
        
        let duplicatedLayer = LayerTemplate(
            name: "layer\(newIndex)",
            displayName: "Layer \(newIndex)",
            physics: originalLayer.physics,
            rendering: originalLayer.rendering,
            dots: originalLayer.dots,
            zIndex: Double(newIndex - 1)
        )
        
        layers.append(duplicatedLayer)
        objectWillChange.send()
    }
    
    func moveLayer(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0 && sourceIndex < layers.count,
              destinationIndex >= 0 && destinationIndex < layers.count else { return }
        
        let movedLayer = layers.remove(at: sourceIndex)
        layers.insert(movedLayer, at: destinationIndex)
        
        // Update zIndex values to maintain proper ordering
        for i in 0..<layers.count {
            layers[i].zIndex = Double(i)
        }
    }
}

// MARK: - Performance Monitoring

/// Performance metrics tracking for Metal rendering optimization with buffer pool monitoring
class PerformanceMonitor: ObservableObject {
    @Published var frameTime: TimeInterval = 0.0
    @Published var renderTime: TimeInterval = 0.0
    @Published var droppedFrames: Int = 0
    @Published var metalUtilization: Double = 0.0
    @Published var bufferPoolHitRate: Double = 0.0
    @Published var bufferPoolMemoryUsage: Int = 0
    @Published var memoryPressureLevel: MemoryPressureLevel = .normal
    
    private static var shared = PerformanceMonitor()
    private var displayLink: CADisplayLink?
    private var lastFrameTime: CFAbsoluteTime = 0
    private var frameCount: Int = 0
    private var renderStartTime: CFAbsoluteTime = 0
    private weak var renderService: MetalRenderService?
    
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
            if frameTime > RenderingConstants.frameDropThreshold {
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
    
    static func setRenderService(_ service: MetalRenderService) {
        shared.renderService = service
    }
    
    static func updateBufferPoolMetrics() {
        guard let metrics = shared.renderService?.getBufferPoolMetrics() else { return }
        
        DispatchQueue.main.async {
            shared.bufferPoolHitRate = metrics.hitRate
            shared.bufferPoolMemoryUsage = metrics.memoryFootprint
            
            // Simple memory pressure detection based on pool usage
            let memoryMB = metrics.memoryFootprint / (1024 * 1024)
            if memoryMB > 100 {
                shared.memoryPressureLevel = .critical
                shared.renderService?.handleMemoryPressure(.critical)
            } else if memoryMB > 50 {
                shared.memoryPressureLevel = .warning
                shared.renderService?.handleMemoryPressure(.warning)
            } else {
                shared.memoryPressureLevel = .normal
            }
        }
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
    static let frameDropThreshold: Double = 1.0/50.0 // Dropped if slower than 50fps
    
    // Metal rendering masks for selective dot rendering
    static let centralDotMask: UInt32 = 1 << 0
    static let largeDotMask: UInt32 = 1 << 1
    static let mediumDotMask: UInt32 = 1 << 2
    static let smallDotMask: UInt32 = 1 << 3
    static let microDotMask: UInt32 = 1 << 4
    
    // Shader rendering constants
    static let spatialCullingMultiplier: Float = 2.0 // Skip dots beyond radius * multiplier
    static let alphaThresholdLow: Float = 0.7 // Lower bound for alpha smoothstep
    static let alphaThresholdHigh: Float = 1.0 // Upper bound for alpha smoothstep
    
    // Safety limits
    static let maxSplatCount: Int = 10000 // Maximum number of splats to prevent memory issues
    static let maxDotsPerSplat: Int = 500 // Maximum total dots per splat
}

/// Type-safe dot type enumeration for Metal rendering
enum DotType: Int32, CaseIterable {
    case central = 0
    case large = 1
    case medium = 2
    case small = 3
    case micro = 4
    
    var mask: UInt32 {
        switch self {
        case .central: return RenderingConstants.centralDotMask
        case .large: return RenderingConstants.largeDotMask
        case .medium: return RenderingConstants.mediumDotMask
        case .small: return RenderingConstants.smallDotMask
        case .micro: return RenderingConstants.microDotMask
        }
    }
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

// MARK: - Notifications

extension Notification.Name {
    static let layerRemoved = Notification.Name("layerRemoved")
}

// MARK: - View Model

/// Primary view model coordinating splat state and Metal rendering data
/// Implements reactive parameter binding with performance-optimized update batching
class SplatterViewModel: ObservableObject {
    // Generic layer system - each layer has its own dot storage
    private var layerDots: [String: [MetalDot]] = [:]
    @Published var layerMetalData: [String: MetalDotData] = [:]
    
    // Parameter groups with reactive bindings - initialized from SettingsManager
    @Published var rendering = SettingsManager.createRenderingParams()
    
    // Cached computation state
    private var isDirty: Bool = true
    private var cancellables = Set<AnyCancellable>()
    
    var renderPasses: [RenderPass] {
        return rendering.layers.map { layer in
            RenderPass(
                name: layer.name,
                enabled: layer.rendering.enabled,
                color: layer.rendering.color.simd3,
                renderMask: computeRenderMask(for: layer),
                opacity: layer.rendering.opacity,
                zIndex: layer.zIndex
            )
        }
    }
    
    init() {
        setupReactiveBindings()
        setupLayerNotifications()
    }
    
    private func setupLayerNotifications() {
        NotificationCenter.default.addObserver(
            forName: .layerRemoved,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let removedLayerName = notification.object as? String {
                self?.layerDots.removeValue(forKey: removedLayerName)
                self?.isDirty = true
                self?.updateMetalData()
            }
        }
    }
    
    private func computeRenderMask(for layer: LayerTemplate) -> UInt32 {
        var mask: UInt32 = 0
        if layer.rendering.centralDot { mask |= RenderingConstants.centralDotMask }
        if layer.rendering.largeDots { mask |= RenderingConstants.largeDotMask }
        if layer.rendering.mediumDots { mask |= RenderingConstants.mediumDotMask }
        if layer.rendering.smallDots { mask |= RenderingConstants.smallDotMask }
        if layer.rendering.microDots { mask |= RenderingConstants.microDotMask }
        return mask
    }
    
    private func computeRenderMask() -> UInt32 {
        // Generate dots for any type enabled in any layer
        return rendering.layers.reduce(0) { combinedMask, layer in
            combinedMask | computeRenderMask(for: layer)
        }
    }
    
    func addSplat(at point: CGPoint, screenWidth: CGFloat, screenHeight: CGFloat) {
        // Single shared RNG instance for all layers
        let rng: RandomGenerator = rendering.useSeededRNG 
            ? SeededRandomGenerator(seed: rendering.rngSeed)
            : DefaultRandomGenerator()
        
        let timestamp = CFAbsoluteTimeGetCurrent()
        
        // Generic loop - works for any number of layers
        for layer in rendering.layers where layer.rendering.enabled {
            let impact = SplatImpact(
                position: point,
                velocity: SIMD2<Float>(layer.physics.velocityX, layer.physics.velocityY),
                force: layer.physics.force,
                timestamp: timestamp
            )
            
            // Generate dots using the same code for all layers
            let newDots = generateLayerSplat(
                impact: impact,
                layer: layer,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                rng: rng
            )
            
            // Store in layer's own dot array
            if layerDots[layer.name] == nil {
                layerDots[layer.name] = []
            }
            layerDots[layer.name]!.append(contentsOf: newDots)
        }
        
        isDirty = true
        updateMetalData()
    }
    
    /// Generic layer splat generation - same code used for all layers
    private func generateLayerSplat(
        impact: SplatImpact,
        layer: LayerTemplate,
        screenWidth: CGFloat,
        screenHeight: CGFloat,
        rng: RandomGenerator
    ) -> [MetalDot] {
        // Safety check: Prevent memory overflow
        let currentDotsCount = layerDots.values.reduce(0) { $0 + $1.count }
        if currentDotsCount >= RenderingConstants.maxSplatCount {
            print("Warning: Maximum splat count reached (\(RenderingConstants.maxSplatCount)). Ignoring new splat.")
            return []
        }
        
        let normalizedX = Float(impact.position.x / screenWidth)
        let normalizedY = Float(impact.position.y / screenHeight)
        let center = SIMD2<Float>(normalizedX, normalizedY)
        
        var newDots: [MetalDot] = []
        var totalNewDots = 0
        
        // Pre-calculate total dots to ensure we don't exceed limits
        if layer.rendering.centralDot { totalNewDots += 1 }
        if layer.rendering.largeDots { totalNewDots += layer.dots.largeCount }
        if layer.rendering.mediumDots { totalNewDots += layer.dots.mediumCount }
        if layer.rendering.smallDots { totalNewDots += layer.dots.smallCount }
        if layer.rendering.microDots { totalNewDots += layer.dots.microCount }
        
        if totalNewDots > RenderingConstants.maxDotsPerSplat {
            print("Warning: Splat would create \(totalNewDots) dots, exceeding limit of \(RenderingConstants.maxDotsPerSplat). Ignoring.")
            return []
        }
        
        // Central dot with velocity-based elongation
        if layer.rendering.centralDot {
            let minRadius = min(layer.dots.centralRadiusMin, layer.dots.centralRadiusMax)
            let maxRadius = max(layer.dots.centralRadiusMin, layer.dots.centralRadiusMax)
            let radius = rng.float(in: minRadius...maxRadius)
            
            // Apply impact velocity and force to central dot with layer-specific elongation
            let velocityMagnitude = length(impact.velocity)
            let elongationFactor = 1.0 + velocityMagnitude * impact.force * layer.physics.centralElongation
            
            newDots.append(MetalDot(
                position: center, 
                radius: radius, 
                type: .central,
                velocity: impact.velocity,
                elongation: elongationFactor
            ))
        }
        
        // Generate satellite dots using velocity-aware helper method
        if layer.rendering.largeDots {
            newDots.append(contentsOf: generateVelocityBasedSatelliteDots(
                count: layer.dots.largeCount,
                radiusMin: layer.dots.largeRadiusMin,
                radiusMax: layer.dots.largeRadiusMax,
                maxDistance: layer.dots.largeMaxDistance,
                center: center,
                type: .large,
                impact: impact,
                layer: layer,
                rng: rng
            ))
        }
        
        if layer.rendering.mediumDots {
            newDots.append(contentsOf: generateVelocityBasedSatelliteDots(
                count: layer.dots.mediumCount,
                radiusMin: layer.dots.mediumRadiusMin,
                radiusMax: layer.dots.mediumRadiusMax,
                maxDistance: layer.dots.mediumMaxDistance,
                center: center,
                type: .medium,
                impact: impact,
                layer: layer,
                rng: rng
            ))
        }
        
        if layer.rendering.smallDots {
            newDots.append(contentsOf: generateVelocityBasedSatelliteDots(
                count: layer.dots.smallCount,
                radiusMin: layer.dots.smallRadiusMin,
                radiusMax: layer.dots.smallRadiusMax,
                maxDistance: layer.dots.smallMaxDistance,
                center: center,
                type: .small,
                impact: impact,
                layer: layer,
                rng: rng
            ))
        }
        
        if layer.rendering.microDots {
            newDots.append(contentsOf: generateVelocityBasedSatelliteDots(
                count: layer.dots.microCount,
                radiusMin: layer.dots.microRadiusMin,
                radiusMax: layer.dots.microRadiusMax,
                maxDistance: layer.dots.microMaxDistance,
                center: center,
                type: .micro,
                impact: impact,
                layer: layer,
                rng: rng
            ))
        }
        
        return newDots
    }
    
    
    /// Helper method to generate satellite dots with consistent logic
    private func generateSatelliteDots(
        count: Int,
        radiusMin: Float,
        radiusMax: Float,
        maxDistance: Float,
        center: SIMD2<Float>,
        type: DotType,
        rng: RandomGenerator
    ) -> [MetalDot] {
        var dots: [MetalDot] = []
        
        for _ in 0..<count {
            let angle = rng.float(in: 0...(2 * Float.pi))
            let distance = rng.float(in: 0...maxDistance)
            let minRadius = min(radiusMin, radiusMax)
            let maxRadius = max(radiusMin, radiusMax)
            let radius = rng.float(in: minRadius...maxRadius)
            
            let offsetX = cos(angle) * distance
            let offsetY = sin(angle) * distance
            let position = SIMD2<Float>(center.x + offsetX, center.y + offsetY)
            
            dots.append(MetalDot(position: position, radius: radius, type: type))
        }
        
        return dots
    }
    
    /// Velocity-aware satellite dot generation for directional splatter effects
    private func generateVelocityBasedSatelliteDots(
        count: Int,
        radiusMin: Float,
        radiusMax: Float,
        maxDistance: Float,
        center: SIMD2<Float>,
        type: DotType,
        impact: SplatImpact,
        layer: LayerTemplate,
        rng: RandomGenerator
    ) -> [MetalDot] {
        var dots: [MetalDot] = []
        
        let velocityMagnitude = length(impact.velocity)
        let velocityDirection = velocityMagnitude > 0.001 ? normalize(impact.velocity) : SIMD2<Float>(0, 0)
        
        for _ in 0..<count {
            // Bias distribution in velocity direction
            let baseAngle = rng.float(in: 0...(2 * Float.pi))
            let velocityAngle = atan2(velocityDirection.y, velocityDirection.x)
            let angleBias = impact.force * 0.5 // Stronger impacts create more directional bias
            let _ = baseAngle + (velocityAngle * angleBias) // angle calculation
            
            // Physics-based trajectory calculation with gravity and time
            let _: Float = 0.1 // timeStep for particle trajectory
            let gravity = SIMD2<Float>(0, 0.3) // Downward gravity effect
            
            // Initial particle velocity with random variation
            let baseParticleVelocity = impact.velocity * rng.float(in: 0.5...1.2)
            let particleVelocity = baseParticleVelocity + SIMD2<Float>(
                rng.float(in: -0.2...0.2), 
                rng.float(in: -0.1...0.1)
            )
            
            // Calculate trajectory with gravity over time
            let trajectoryTime = rng.float(in: 0.1...0.5) // Random flight time
            let gravityEffect = gravity * trajectoryTime * trajectoryTime * 0.5
            let finalPosition = center + particleVelocity * trajectoryTime + gravityEffect
            
            // Clamp to maximum distance for safety
            let trajectoryVector = finalPosition - center
            let trajectoryDistance = length(trajectoryVector)
            let _ = min(trajectoryDistance, maxDistance * 1.5) // distance calculation
            
            // Surface tension effects on particle size
            let minRadius = min(radiusMin, radiusMax)
            let maxRadius = max(radiusMin, radiusMax)
            let baseRadius = rng.float(in: minRadius...maxRadius)
            
            // Surface tension affects smaller particles more (makes them rounder)
            let surfaceTensionFactor = 1.0 - (baseRadius / maxRadius) * 0.3
            let radius = baseRadius * (1.0 + surfaceTensionFactor * 0.2)
            
            // Use physics-calculated position instead of simple angle-distance
            let position = SIMD2<Float>(
                min(max(finalPosition.x, 0.0), 1.0), // Clamp to screen bounds
                min(max(finalPosition.y, 0.0), 1.0)
            )
            
            // Final particle velocity after physics simulation
            let finalParticleVelocity = particleVelocity + gravityEffect * 2.0 // Gravity affects velocity too
            
            // Time-based elongation - particles elongate based on layer-specific parameters
            let timeElongationMultiplier = layer.physics.timeElongation
            let particleElongationMultiplier = layer.physics.particleElongation
            
            let timeElongation = trajectoryTime * timeElongationMultiplier
            let particleVelocityMagnitude = length(finalParticleVelocity)
            let elongation = 1.0 + (particleVelocityMagnitude * impact.force * particleElongationMultiplier) + timeElongation
            
            dots.append(MetalDot(
                position: position,
                radius: radius,
                type: type,
                velocity: finalParticleVelocity,
                elongation: elongation
            ))
        }
        
        return dots
    }
    
    func clear() {
        layerDots.removeAll()
        isDirty = true
        updateMetalData()
    }
    
    func updateMetalData() {
        guard isDirty else { return }
        
        // Create separate MetalDotData for each layer
        var newLayerMetalData: [String: MetalDotData] = [:]
        
        for layer in rendering.layers {
            let layerDots = self.layerDots[layer.name] ?? []
            let renderMask = computeRenderMask(for: layer)
            newLayerMetalData[layer.name] = MetalDotData(dots: layerDots, renderMask: renderMask)
        }
        
        layerMetalData = newLayerMetalData
        isDirty = false
    }
    
    // MARK: - Settings Export/Import (delegated to SettingsManager)
    
    func exportSettingsAsJSON() -> String {
        return SettingsManager.exportSettings(from: self)
    }
    
    func loadFromJSON(_ json: String) -> Bool {
        return SettingsManager.importSettings(json: json, to: self)
    }
    
    private func setupReactiveBindings() {
        // GEOMETRY-AFFECTING CHANGES: These require metalData recomputation
        
        // Layer changes - trigger update when any layer properties change
        rendering.$layers
            .debounce(for: .milliseconds(RenderingConstants.reactiveUpdateDebounceMs), scheduler: RunLoop.main)
            .sink { [weak self] _ in 
                self?.updateMetalData()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        
        
        // VISUAL-ONLY CHANGES: Only affect rendering appearance - no geometry recomputation needed
        
        
    }
    
    // MARK: - Layer-specific parameter helpers
    
    func getNoiseAmplitude(for layerName: String) -> Float {
        return rendering.getLayer(named: layerName)?.physics.noiseAmplitude ?? 0.3
    }
    
    func getVelocityRoughness(for layerName: String) -> Float {
        return rendering.getLayer(named: layerName)?.physics.velocityRoughness ?? 0.4
    }
    
    func getNoiseFrequency(for layerName: String) -> Float {
        return rendering.getLayer(named: layerName)?.physics.noiseFrequency ?? 20.0
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
                        dots: viewModel.layerMetalData[renderPass.name]?.dots ?? [],
                        splatColor: renderPass.color,
                        renderMask: renderPass.renderMask,
                        influenceThreshold: viewModel.rendering.influenceThreshold,
                        noiseAmplitude: viewModel.getNoiseAmplitude(for: renderPass.name),
                        velocityRoughness: viewModel.getVelocityRoughness(for: renderPass.name),
                        noiseFrequency: viewModel.getNoiseFrequency(for: renderPass.name),
                        layerName: renderPass.name
                    )
                    .allowsHitTesting(false)
                    .blendMode(.multiply)
                    .opacity(Double(renderPass.opacity))
                    .zIndex(renderPass.zIndex)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        Text(SplatterViewVersion.current)
                            .font(.system(size: 36, weight: .regular, design: .default))
                            .foregroundColor(.black)
                            .padding(.bottom, 20)
                    }
                    
                    // Splatter overlay
                    ZStack {
                        ForEach(viewModel.renderPasses, id: \.name) { renderPass in
                            if renderPass.enabled {
                                MetalOverlayView(
                                    dots: viewModel.layerMetalData[renderPass.name]?.dots ?? [],
                                    splatColor: renderPass.color,
                                    renderMask: renderPass.renderMask,
                                    influenceThreshold: viewModel.rendering.influenceThreshold,
                                    noiseAmplitude: viewModel.getNoiseAmplitude(for: renderPass.name),
                                    velocityRoughness: viewModel.getVelocityRoughness(for: renderPass.name),
                                    noiseFrequency: viewModel.getNoiseFrequency(for: renderPass.name),
                                    layerName: renderPass.name
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
    
    // Helper function to get tint color for layer toggles
    private func getLayerTintColor(for layerName: String) -> Color {
        switch layerName.lowercased() {
        case "background":
            return .blue
        case "foreground":
            return .orange
        case "dramatic":
            return .red
        default:
            return .indigo
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Toolbar Section
                Section {
                    ToolbarRow(viewModel: viewModel)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                // MARK: - Layers Section
                Section {
                    ForEach(Array(viewModel.rendering.layers.enumerated()), id: \.1.name) { index, layer in
                        LayerCard(viewModel: viewModel, layerIndex: index, layer: layer)
                    }
                } header: {
                    LayerSectionHeader(viewModel: viewModel)
                }
                
                // MARK: - Global Settings Section
                Section {
                    RandomSettingsCard(viewModel: viewModel)
                } header: {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.secondary)
                        Text("Global Settings")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
            }
            .navigationTitle("Controls")
            .navigationBarTitleDisplayMode(.large)
            .listStyle(InsetGroupedListStyle())
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Toolbar Row
struct ToolbarRow: View {
    @ObservedObject var viewModel: SplatterViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.clear()
            } label: {
                Label("Clear All", systemImage: "trash.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.regular)
            
            Divider()
            
            HStack(spacing: 8) {
                Button {
                    let json = viewModel.exportSettingsAsJSON()
                    UIPasteboard.general.string = json
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .help("Export Settings")
                
                Button {
                    if let json = UIPasteboard.general.string {
                        let success = viewModel.loadFromJSON(json)
                        if !success {
                            print("Failed to import settings from clipboard")
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .help("Import Settings")
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Layer Section Header
struct LayerSectionHeader: View {
    @ObservedObject var viewModel: SplatterViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "rectangle.stack.fill")
                .foregroundColor(.secondary)
            Text("Layers")
            
            Spacer()
            
            Text("\(viewModel.rendering.layers.count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .clipShape(Capsule())
            
            Button {
                viewModel.rendering.addLayer()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .tint(.green)
        }
        .font(.subheadline)
        .fontWeight(.semibold)
    }
}

// MARK: - Layer Card
struct LayerCard: View {
    @ObservedObject var viewModel: SplatterViewModel
    let layerIndex: Int
    let layer: LayerTemplate
    @State private var showingDetails = false
    
    private func getLayerTintColor(for layerName: String) -> Color {
        switch layerName.lowercased() {
        case "background": return .blue
        case "foreground": return .orange
        case "dramatic": return .red
        default: return .indigo
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Layer Header
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingDetails.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Layer status indicator
                    Circle()
                        .fill(layer.rendering.enabled ? getLayerTintColor(for: layer.name) : Color.secondary.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Image(systemName: layer.rendering.enabled ? "checkmark" : "")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(layer.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if layer.rendering.enabled {
                            Text("Opacity \(Int(layer.rendering.opacity * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Disabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Quick toggle
                    Toggle("", isOn: Binding(
                        get: { viewModel.rendering.layers[layerIndex].rendering.enabled },
                        set: { viewModel.rendering.layers[layerIndex].rendering.enabled = $0 }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: getLayerTintColor(for: layer.name)))
                    .scaleEffect(0.8)
                    
                    Image(systemName: showingDetails ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.2), value: showingDetails)
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
            
            // Expanded Details
            if showingDetails {
                Divider()
                    .padding(.vertical, 8)
                
                LayerDetailsView(viewModel: viewModel, layerIndex: layerIndex, layer: layer)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(getLayerTintColor(for: layer.name).opacity(layer.rendering.enabled ? 0.3 : 0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Layer Details View
struct LayerDetailsView: View {
    @ObservedObject var viewModel: SplatterViewModel
    let layerIndex: Int
    let layer: LayerTemplate
    @State private var expandedGroups: Set<String> = []
    
    private func getLayerTintColor(for layerName: String) -> Color {
        switch layerName.lowercased() {
        case "background": return .blue
        case "foreground": return .orange
        case "dramatic": return .red
        default: return .indigo
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Layer Actions
            HStack(spacing: 12) {
                Button {
                    viewModel.rendering.duplicateLayer(at: layerIndex)
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .controlSize(.small)
                
                if viewModel.rendering.layers.count > 1 {
                    Button {
                        viewModel.rendering.removeLayer(at: layerIndex)
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .controlSize(.small)
                }
                
                Spacer()
            }
            
            if layer.rendering.enabled {
                // Basic Properties
                BasicPropertiesGroup(viewModel: viewModel, layerIndex: layerIndex, layer: layer)
                
                // Expandable Sections
                ExpandableSection(
                    title: "Dot Types",
                    icon: "circle.grid.3x3.fill",
                    isExpanded: expandedGroups.contains("dotTypes")
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if expandedGroups.contains("dotTypes") {
                            expandedGroups.remove("dotTypes")
                        } else {
                            expandedGroups.insert("dotTypes")
                        }
                    }
                } content: {
                    DotTypesGroup(viewModel: viewModel, layerIndex: layerIndex, layer: layer)
                }
                
                ExpandableSection(
                    title: "Physics",
                    icon: "waveform.path",
                    isExpanded: expandedGroups.contains("physics")
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if expandedGroups.contains("physics") {
                            expandedGroups.remove("physics")
                        } else {
                            expandedGroups.insert("physics")
                        }
                    }
                } content: {
                    PhysicsGroup(viewModel: viewModel, layerIndex: layerIndex, layer: layer)
                }
                
                ExpandableSection(
                    title: "Dot Parameters",
                    icon: "slider.horizontal.3",
                    isExpanded: expandedGroups.contains("dotParams")
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if expandedGroups.contains("dotParams") {
                            expandedGroups.remove("dotParams")
                        } else {
                            expandedGroups.insert("dotParams")
                        }
                    }
                } content: {
                    DotParametersGroup(viewModel: viewModel, layerIndex: layerIndex, layer: layer)
                }
            }
        }
    }
}

// MARK: - Expandable Section
struct ExpandableSection<Content: View>: View {
    let title: String
    let icon: String
    let isExpanded: Bool
    let onToggle: () -> Void
    let content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
            
            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
        .padding(.horizontal, 4)
    }
}

// MARK: - Basic Properties Group
struct BasicPropertiesGroup: View {
    @ObservedObject var viewModel: SplatterViewModel
    let layerIndex: Int
    let layer: LayerTemplate
    
    var body: some View {
        VStack(spacing: 12) {
            // Color Picker
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                if #available(iOS 14.0, *) {
                    ColorPicker("Color", selection: Binding(
                        get: { viewModel.rendering.layers[layerIndex].rendering.color },
                        set: { viewModel.rendering.layers[layerIndex].rendering.color = $0 }
                    ))
                    .labelsHidden()
                } else {
                    Text("Color")
                    Spacer()
                    Circle()
                        .fill(layer.rendering.color)
                        .frame(width: 24, height: 24)
                }
            }
            
            // Opacity Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "opacity")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text("Opacity")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(layer.rendering.opacity * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                
                Slider(value: Binding(
                    get: { viewModel.rendering.layers[layerIndex].rendering.opacity },
                    set: { viewModel.rendering.layers[layerIndex].rendering.opacity = $0 }
                ), in: 0...1)
                .tint(.primary)
            }
        }
    }
}

// MARK: - Dot Types Group
struct DotTypesGroup: View {
    @ObservedObject var viewModel: SplatterViewModel
    let layerIndex: Int
    let layer: LayerTemplate
    
    private func getLayerTintColor(for layerName: String) -> Color {
        switch layerName.lowercased() {
        case "background": return .blue
        case "foreground": return .orange
        case "dramatic": return .red
        default: return .indigo
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                DotTypeToggle(
                    title: "Central",
                    icon: "circle.fill",
                    isOn: Binding(
                        get: { viewModel.rendering.layers[layerIndex].rendering.centralDot },
                        set: { viewModel.rendering.layers[layerIndex].rendering.centralDot = $0 }
                    ),
                    tint: getLayerTintColor(for: layer.name)
                )
                
                DotTypeToggle(
                    title: "Large",
                    icon: "largecircle.fill.circle",
                    isOn: Binding(
                        get: { viewModel.rendering.layers[layerIndex].rendering.largeDots },
                        set: { viewModel.rendering.layers[layerIndex].rendering.largeDots = $0 }
                    ),
                    tint: getLayerTintColor(for: layer.name)
                )
                
                DotTypeToggle(
                    title: "Medium",
                    icon: "circle.circle",
                    isOn: Binding(
                        get: { viewModel.rendering.layers[layerIndex].rendering.mediumDots },
                        set: { viewModel.rendering.layers[layerIndex].rendering.mediumDots = $0 }
                    ),
                    tint: getLayerTintColor(for: layer.name)
                )
                
                DotTypeToggle(
                    title: "Small",
                    icon: "smallcircle.fill.circle",
                    isOn: Binding(
                        get: { viewModel.rendering.layers[layerIndex].rendering.smallDots },
                        set: { viewModel.rendering.layers[layerIndex].rendering.smallDots = $0 }
                    ),
                    tint: getLayerTintColor(for: layer.name)
                )
                
                DotTypeToggle(
                    title: "Micro",
                    icon: "circle.dotted",
                    isOn: Binding(
                        get: { viewModel.rendering.layers[layerIndex].rendering.microDots },
                        set: { viewModel.rendering.layers[layerIndex].rendering.microDots = $0 }
                    ),
                    tint: getLayerTintColor(for: layer.name)
                )
            }
        }
        .padding(12)
    }
}

// MARK: - Dot Type Toggle
struct DotTypeToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    let tint: Color
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.toggle()
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isOn ? tint : .secondary)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isOn ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isOn ? tint.opacity(0.15) : Color(.quaternarySystemFill))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isOn ? tint.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Physics Group
struct PhysicsGroup: View {
    @ObservedObject var viewModel: SplatterViewModel
    let layerIndex: Int
    let layer: LayerTemplate
    
    var body: some View {
        VStack(spacing: 12) {
            ParameterSlider(
                title: "Velocity X",
                icon: "arrow.right",
                value: Binding(
                    get: { viewModel.rendering.layers[layerIndex].physics.velocityX },
                    set: { viewModel.rendering.layers[layerIndex].physics.velocityX = $0 }
                ),
                range: 0.0...3.0,
                format: "%.2f"
            )
            
            ParameterSlider(
                title: "Velocity Y",
                icon: "arrow.down",
                value: Binding(
                    get: { viewModel.rendering.layers[layerIndex].physics.velocityY },
                    set: { viewModel.rendering.layers[layerIndex].physics.velocityY = $0 }
                ),
                range: 0.0...3.0,
                format: "%.2f"
            )
            
            ParameterSlider(
                title: "Force",
                icon: "bolt.fill",
                value: Binding(
                    get: { viewModel.rendering.layers[layerIndex].physics.force },
                    set: { viewModel.rendering.layers[layerIndex].physics.force = $0 }
                ),
                range: 0.0...1.0,
                format: "%.2f"
            )
            
            Divider()
            
            ParameterSlider(
                title: "Central Elongation",
                icon: "oval",
                value: Binding(
                    get: { viewModel.rendering.layers[layerIndex].physics.centralElongation },
                    set: { viewModel.rendering.layers[layerIndex].physics.centralElongation = $0 }
                ),
                range: 1.0...10.0,
                format: "%.1f"
            )
            
            ParameterSlider(
                title: "Particle Elongation",
                icon: "oval.fill",
                value: Binding(
                    get: { viewModel.rendering.layers[layerIndex].physics.particleElongation },
                    set: { viewModel.rendering.layers[layerIndex].physics.particleElongation = $0 }
                ),
                range: 1.0...5.0,
                format: "%.1f"
            )
            
            ParameterSlider(
                title: "Time Elongation",
                icon: "clock.fill",
                value: Binding(
                    get: { viewModel.rendering.layers[layerIndex].physics.timeElongation },
                    set: { viewModel.rendering.layers[layerIndex].physics.timeElongation = $0 }
                ),
                range: 1.0...8.0,
                format: "%.1f"
            )
            
            Divider()
            
            ParameterSlider(
                title: "Noise Amplitude",
                icon: "waveform",
                value: Binding(
                    get: { viewModel.rendering.layers[layerIndex].physics.noiseAmplitude },
                    set: { viewModel.rendering.layers[layerIndex].physics.noiseAmplitude = $0 }
                ),
                range: 0.0...2.0,
                format: "%.2f"
            )
            
            ParameterSlider(
                title: "Velocity Roughness",
                icon: "waveform.path",
                value: Binding(
                    get: { viewModel.rendering.layers[layerIndex].physics.velocityRoughness },
                    set: { viewModel.rendering.layers[layerIndex].physics.velocityRoughness = $0 }
                ),
                range: 0.0...2.0,
                format: "%.2f"
            )
            
            ParameterSlider(
                title: "Noise Frequency",
                icon: "waveform.path.ecg",
                value: Binding(
                    get: { viewModel.rendering.layers[layerIndex].physics.noiseFrequency },
                    set: { viewModel.rendering.layers[layerIndex].physics.noiseFrequency = $0 }
                ),
                range: 1.0...30.0,
                format: "%.1f"
            )
        }
        .padding(12)
    }
}

// MARK: - Parameter Slider
struct ParameterSlider: View {
    let title: String
    let icon: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let format: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(String(format: format, value))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    .frame(minWidth: 40, alignment: .trailing)
            }
            
            Slider(value: $value, in: range)
                .tint(.primary)
        }
    }
}

// MARK: - Random Settings Card
struct RandomSettingsCard: View {
    @ObservedObject var viewModel: SplatterViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shuffle")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Toggle("Use Seeded RNG", isOn: $viewModel.rendering.useSeededRNG)
                    .toggleStyle(SwitchToggleStyle())
            }
            
            if viewModel.rendering.useSeededRNG {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        Text("Seed: \(viewModel.rendering.rngSeed)")
                            .font(.subheadline)
                            .monospacedDigit()
                        
                        Spacer()
                        
                        Button {
                            viewModel.rendering.rngSeed = UInt64.random(in: 1...99999)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.blue)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Dot Parameters Group
struct DotParametersGroup: View {
    @ObservedObject var viewModel: SplatterViewModel
    let layerIndex: Int
    let layer: LayerTemplate
    
    var body: some View {
        VStack(spacing: 16) {
            // Central Dot Parameters
            DotTypeParameterSection(
                title: "Central Dot",
                icon: "circle.fill",
                content: {
                    VStack(spacing: 8) {
                        ParameterSlider(
                            title: "Min Size",
                            icon: "minus.circle",
                            value: Binding(
                                get: { viewModel.rendering.layers[layerIndex].dots.centralRadiusMin },
                                set: { viewModel.rendering.layers[layerIndex].dots.centralRadiusMin = $0 }
                            ),
                            range: 0.001...0.1,
                            format: "%.3f"
                        )
                        
                        ParameterSlider(
                            title: "Max Size",
                            icon: "plus.circle",
                            value: Binding(
                                get: { viewModel.rendering.layers[layerIndex].dots.centralRadiusMax },
                                set: { viewModel.rendering.layers[layerIndex].dots.centralRadiusMax = $0 }
                            ),
                            range: 0.001...0.1,
                            format: "%.3f"
                        )
                    }
                }
            )
            
            // Large Dots Parameters
            DotTypeParameterSection(
                title: "Large Dots",
                icon: "largecircle.fill.circle",
                content: {
                    VStack(spacing: 8) {
                        ParameterSlider(
                            title: "Count",
                            icon: "number",
                            value: Binding(
                                get: { Float(viewModel.rendering.layers[layerIndex].dots.largeCount) },
                                set: { viewModel.rendering.layers[layerIndex].dots.largeCount = Int($0) }
                            ),
                            range: 0...50,
                            format: "%.0f"
                        )
                        
                        ParameterSlider(
                            title: "Min Size",
                            icon: "minus.circle",
                            value: Binding(
                                get: { viewModel.rendering.layers[layerIndex].dots.largeRadiusMin },
                                set: { viewModel.rendering.layers[layerIndex].dots.largeRadiusMin = $0 }
                            ),
                            range: 0.001...0.05,
                            format: "%.3f"
                        )
                        
                        ParameterSlider(
                            title: "Max Size",
                            icon: "plus.circle",
                            value: Binding(
                                get: { viewModel.rendering.layers[layerIndex].dots.largeRadiusMax },
                                set: { viewModel.rendering.layers[layerIndex].dots.largeRadiusMax = $0 }
                            ),
                            range: 0.001...0.1,
                            format: "%.3f"
                        )
                        
                        ParameterSlider(
                            title: "Max Distance",
                            icon: "arrow.up.and.down.and.arrow.left.and.right",
                            value: Binding(
                                get: { viewModel.rendering.layers[layerIndex].dots.largeMaxDistance },
                                set: { viewModel.rendering.layers[layerIndex].dots.largeMaxDistance = $0 }
                            ),
                            range: 0.01...0.5,
                            format: "%.3f"
                        )
                    }
                }
            )
            
            // Medium Dots Parameters
            DotTypeParameterSection(
                title: "Medium Dots",
                icon: "circle.circle",
                content: {
                    VStack(spacing: 8) {
                        ParameterSlider(
                            title: "Count",
                            icon: "number",
                            value: Binding(
                                get: { Float(viewModel.rendering.layers[layerIndex].dots.mediumCount) },
                                set: { viewModel.rendering.layers[layerIndex].dots.mediumCount = Int($0) }
                            ),
                            range: 0...100,
                            format: "%.0f"
                        )
                        
                        ParameterSlider(
                            title: "Min Size",
                            icon: "minus.circle",
                            value: Binding(
                                get: { viewModel.rendering.layers[layerIndex].dots.mediumRadiusMin },
                                set: { viewModel.rendering.layers[layerIndex].dots.mediumRadiusMin = $0 }
                            ),
                            range: 0.001...0.03,
                            format: "%.3f"
                        )
                        
                        ParameterSlider(
                            title: "Max Size",
                            icon: "plus.circle",
                            value: Binding(
                                get: { viewModel.rendering.layers[layerIndex].dots.mediumRadiusMax },
                                set: { viewModel.rendering.layers[layerIndex].dots.mediumRadiusMax = $0 }
                            ),
                            range: 0.001...0.05,
                            format: "%.3f"
                        )
                        
                        ParameterSlider(
                            title: "Max Distance",
                            icon: "arrow.up.and.down.and.arrow.left.and.right",
                            value: Binding(
                                get: { viewModel.rendering.layers[layerIndex].dots.mediumMaxDistance },
                                set: { viewModel.rendering.layers[layerIndex].dots.mediumMaxDistance = $0 }
                            ),
                            range: 0.01...0.4,
                            format: "%.3f"
                        )
                    }
                }
            )
            
            // Small Dots Parameters
            DotTypeParameterSection(
                title: "Small Dots",
                icon: "smallcircle.fill.circle",
                content: {
                    VStack(spacing: 8) {
                        ParameterSlider(
                            title: "Count",
                            icon: "number",
                            value: Binding(
                                get: { Float(viewModel.rendering.layers[layerIndex].dots.smallCount) },
                                set: { viewModel.rendering.layers[layerIndex].dots.smallCount = Int($0) }
                            ),
                            range: 0...200,
                            format: "%.0f"
                        )
                        
                        ParameterSlider(
                            title: "Min Size",
                            icon: "minus.circle",
                            value: Binding(
                                get: { viewModel.rendering.layers[layerIndex].dots.smallRadiusMin },
                                set: { viewModel.rendering.layers[layerIndex].dots.smallRadiusMin = $0 }
                            ),
                            range: 0.0001...0.02,
                            format: "%.4f"
                        )
                        
                        ParameterSlider(
                            title: "Max Size",
                            icon: "plus.circle",
                            value: Binding(
                                get: { viewModel.rendering.layers[layerIndex].dots.smallRadiusMax },
                                set: { viewModel.rendering.layers[layerIndex].dots.smallRadiusMax = $0 }
                            ),
                            range: 0.0001...0.03,
                            format: "%.4f"
                        )
                        
                        ParameterSlider(
                            title: "Max Distance",
                            icon: "arrow.up.and.down.and.arrow.left.and.right",
                            value: Binding(
                                get: { viewModel.rendering.layers[layerIndex].dots.smallMaxDistance },
                                set: { viewModel.rendering.layers[layerIndex].dots.smallMaxDistance = $0 }
                            ),
                            range: 0.01...0.3,
                            format: "%.3f"
                        )
                    }
                }
            )
            
            // Micro Dots Parameters
            DotTypeParameterSection(
                title: "Micro Dots",
                icon: "circle.dotted",
                content: {
                    VStack(spacing: 8) {
                        ParameterSlider(
                            title: "Count",
                            icon: "number",
                            value: Binding(
                                get: { Float(viewModel.rendering.layers[layerIndex].dots.microCount) },
                                set: { viewModel.rendering.layers[layerIndex].dots.microCount = Int($0) }
                            ),
                            range: 0...300,
                            format: "%.0f"
                        )
                        
                        ParameterSlider(
                            title: "Min Size",
                            icon: "minus.circle",
                            value: Binding(
                                get: { viewModel.rendering.layers[layerIndex].dots.microRadiusMin },
                                set: { viewModel.rendering.layers[layerIndex].dots.microRadiusMin = $0 }
                            ),
                            range: 0.00001...0.01,
                            format: "%.5f"
                        )
                        
                        ParameterSlider(
                            title: "Max Size",
                            icon: "plus.circle",
                            value: Binding(
                                get: { viewModel.rendering.layers[layerIndex].dots.microRadiusMax },
                                set: { viewModel.rendering.layers[layerIndex].dots.microRadiusMax = $0 }
                            ),
                            range: 0.00001...0.02,
                            format: "%.5f"
                        )
                        
                        ParameterSlider(
                            title: "Max Distance",
                            icon: "arrow.up.and.down.and.arrow.left.and.right",
                            value: Binding(
                                get: { viewModel.rendering.layers[layerIndex].dots.microMaxDistance },
                                set: { viewModel.rendering.layers[layerIndex].dots.microMaxDistance = $0 }
                            ),
                            range: 0.01...0.2,
                            format: "%.3f"
                        )
                    }
                }
            )
        }
        .padding(12)
    }
}

// MARK: - Dot Type Parameter Section
struct DotTypeParameterSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            content()
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.quaternarySystemFill))
        )
    }
}

// MARK: - Metal Rendering

struct MetalOverlayView: UIViewRepresentable {
    let dots: [MetalDot]
    let splatColor: SIMD3<Float>
    let renderMask: UInt32
    let influenceThreshold: Float
    let noiseAmplitude: Float
    let velocityRoughness: Float
    let noiseFrequency: Float
    let layerName: String
    
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
        Coordinator(
            splatColor: splatColor, 
            influenceThreshold: influenceThreshold,
            noiseAmplitude: noiseAmplitude,
            velocityRoughness: velocityRoughness,
            noiseFrequency: noiseFrequency,
            layerName: layerName
        )
    }
    class Coordinator: NSObject, MTKViewDelegate {
        var splatColor: SIMD3<Float>
        var influenceThreshold: Float
        var noiseAmplitude: Float
        var velocityRoughness: Float
        var noiseFrequency: Float
        var layerName: String
        let stateManager: MetalStateManager
        private let metalService: MetalRenderService
        private var frameCount: Int = 0
        
        init(splatColor: SIMD3<Float>, influenceThreshold: Float, noiseAmplitude: Float, velocityRoughness: Float, noiseFrequency: Float, layerName: String) {
            self.splatColor = splatColor
            self.influenceThreshold = influenceThreshold
            self.noiseAmplitude = noiseAmplitude
            self.velocityRoughness = velocityRoughness
            self.noiseFrequency = noiseFrequency
            self.layerName = layerName
            self.stateManager = MetalStateManager()
            self.metalService = MetalRenderService()
            super.init()
            
            // Register render service with performance monitor
            PerformanceMonitor.setRenderService(metalService)
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
                aspectRatio: aspectRatio,
                dramaticNoiseAmplitude: noiseAmplitude,
                dramaticVelocityRoughness: velocityRoughness,
                dramaticNoiseFrequency: noiseFrequency,
                layerName: layerName
            )
            
            PerformanceMonitor.endRenderTiming()
            
            // Update buffer pool metrics every few frames
            if frameCount % 60 == 0 { // Update metrics every 60 frames (~1 second at 60fps)
                PerformanceMonitor.updateBufferPoolMetrics()
            }
            frameCount += 1
            
            if RenderingConstants.enablePerformanceLogging {
                let renderTime = CFAbsoluteTimeGetCurrent() - renderStartTime
                print("[PERF] Metal render: \(String(format: "%.3f", renderTime * 1000))ms")
            }
        }
    }
}

// MARK: - Metal Buffer Pooling

/// Buffer usage types for optimized pool management
enum BufferUsage {
    case vertex          // Fixed-size vertex data
    case dots           // Variable-size dot data  
    case uniforms       // Small uniform structures
    case temporary      // Short-lived buffers
    
    var options: MTLResourceOptions {
        switch self {
        case .vertex:
            return [.storageModeShared]
        case .dots:
            return [.storageModeShared]
        case .uniforms:
            return [.storageModeShared, .cpuCacheModeWriteCombined]
        case .temporary:
            return [.storageModePrivate]
        }
    }
    
    var maxPoolSize: Int {
        switch self {
        case .vertex: return 5      // Few, reused frequently
        case .dots: return 10       // Variable sizes
        case .uniforms: return 15   // Many, small, frequent
        case .temporary: return 3   // Short-lived
        }
    }
}

/// RAII wrapper that automatically returns buffer to pool
class PooledBuffer {
    let buffer: MTLBuffer
    private weak var pool: MetalBufferPool?
    private var isReturned = false
    
    init(buffer: MTLBuffer, pool: MetalBufferPool) {
        self.buffer = buffer
        self.pool = pool
    }
    
    deinit {
        returnToPool()
    }
    
    func returnToPool() {
        guard !isReturned, let pool = pool else { return }
        isReturned = true
        pool.returnBuffer(self)
    }
}

/// High-performance Metal buffer pool with size-based bucketing
class MetalBufferPool {
    private let device: MTLDevice
    private var buckets: [BufferBucket] = []
    private let maxPoolSize: Int
    private let alignment: Int = 256 // Metal prefers 256-byte alignment
    private let queue = DispatchQueue(label: "com.splatterview.buffer-pool", qos: .userInteractive)
    
    // Metrics tracking
    private var totalAllocations: Int = 0
    private var poolHits: Int = 0
    private var poolMisses: Int = 0
    
    init(device: MTLDevice, maxPoolSize: Int = 20) {
        self.device = device
        self.maxPoolSize = maxPoolSize
        // Initialize buckets array first
        self.buckets = []
        // Setup buckets with error handling
        do {
            try setupBucketsWithErrorHandling()
        } catch {
            print("Warning: Buffer pool initialization failed, falling back to direct allocation")
        }
    }
    
    /// Buffer bucket for specific size ranges
    private class BufferBucket {
        let sizeRange: ClosedRange<Int>
        let usage: BufferUsage
        private var availableBuffers: [MTLBuffer] = []
        private var usedBuffers: Set<ObjectIdentifier> = []
        private let maxCount: Int
        
        init(sizeRange: ClosedRange<Int>, usage: BufferUsage) {
            self.sizeRange = sizeRange
            self.usage = usage
            self.maxCount = usage.maxPoolSize
        }
        
        func borrow() -> MTLBuffer? {
            return availableBuffers.popLast()
        }
        
        func `return`(_ buffer: MTLBuffer) -> Bool {
            let id = ObjectIdentifier(buffer)
            
            if availableBuffers.count < maxCount {
                availableBuffers.append(buffer)
                usedBuffers.insert(id)
                return true
            }
            return false // Pool full, let buffer deallocate
        }
        
        func canAccommodate(size: Int) -> Bool {
            sizeRange.contains(size)
        }
        
        func reduceCapacity(by factor: Double) {
            let targetSize = Int(Double(maxCount) * (1.0 - factor))
            while availableBuffers.count > targetSize {
                _ = availableBuffers.popLast()
            }
        }
        
        var currentSize: Int { availableBuffers.count }
        var memoryFootprint: Int { 
            availableBuffers.reduce(0) { $0 + $1.length }
        }
    }
    
    private func setupBucketsWithErrorHandling() throws {
        buckets = [
            // Vertex buffers (typically small, fixed size)
            BufferBucket(sizeRange: 0...1024, usage: .vertex),
            
            // Small dot counts (1-100 dots)
            BufferBucket(sizeRange: 1025...4096, usage: .dots),
            
            // Medium dot counts (100-500 dots) 
            BufferBucket(sizeRange: 4097...16384, usage: .dots),
            
            // Large dot counts (500-2000 dots) - reduced for playground
            BufferBucket(sizeRange: 16385...32768, usage: .dots),
            
            // Uniform buffers (small, frequent)
            BufferBucket(sizeRange: 0...512, usage: .uniforms)
        ]
    }
    
    func borrowBuffer(size: Int, usage: BufferUsage) -> PooledBuffer? {
        return queue.sync {
            let alignedSize = alignSize(size)
            totalAllocations += 1
            
            // Find appropriate bucket
            guard let bucket = findBucket(for: alignedSize, usage: usage) else {
                poolMisses += 1
                return createNewBuffer(size: alignedSize, usage: usage)
            }
            
            // Try to get existing buffer
            if let buffer = bucket.borrow() {
                poolHits += 1
                return PooledBuffer(buffer: buffer, pool: self)
            }
            
            // Create new buffer for this bucket
            poolMisses += 1
            return createNewBuffer(size: alignedSize, usage: usage)
        }
    }
    
    func returnBuffer(_ pooledBuffer: PooledBuffer) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let buffer = pooledBuffer.buffer
            let size = buffer.length
            
            // Find appropriate bucket and return
            if let bucket = self.findBucket(for: size, usage: self.inferUsage(buffer)) {
                _ = bucket.return(buffer)
            }
        }
    }
    
    private func alignSize(_ size: Int) -> Int {
        return ((size + alignment - 1) / alignment) * alignment
    }
    
    private func findBucket(for size: Int, usage: BufferUsage) -> BufferBucket? {
        return buckets.first { bucket in
            bucket.canAccommodate(size: size) && bucket.usage == usage
        }
    }
    
    private func createNewBuffer(size: Int, usage: BufferUsage) -> PooledBuffer? {
        guard let buffer = device.makeBuffer(length: size, options: usage.options) else {
            return nil
        }
        return PooledBuffer(buffer: buffer, pool: self)
    }
    
    private func inferUsage(_ buffer: MTLBuffer) -> BufferUsage {
        // Simple heuristic based on buffer size
        let size = buffer.length
        switch size {
        case 0...512: return .uniforms
        case 513...1024: return .vertex
        default: return .dots
        }
    }
    
    // MARK: - Pool Management
    
    func prewarmBuffers() {
        // Conservative prewarming for playground environment
        let commonSizes = [256, 1024]  // Only smallest common sizes
        
        for size in commonSizes {
            for usage in [BufferUsage.uniforms] {  // Only uniforms for minimal impact
                if let buffer = borrowBuffer(size: size, usage: usage) {
                    buffer.returnToPool()
                }
            }
        }
    }
    
    func clearAllPools() {
        queue.sync {
            buckets.forEach { bucket in
                bucket.reduceCapacity(by: 1.0) // Clear completely
            }
        }
    }
    
    func adaptToMemoryPressure(_ level: MemoryPressureLevel) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            switch level {
            case .normal:
                break // Full pool size
            case .warning:
                self.buckets.forEach { $0.reduceCapacity(by: 0.5) }
            case .critical:
                self.clearAllPools()
            }
        }
    }
    
    // MARK: - Metrics
    
    struct BufferPoolMetrics {
        let hitRate: Double
        let totalAllocations: Int
        let currentPoolSize: Int
        let memoryFootprint: Int
        let bucketsStatus: [(range: String, count: Int, memory: Int)]
    }
    
    func getMetrics() -> BufferPoolMetrics {
        return queue.sync {
            let hitRate = totalAllocations > 0 ? Double(poolHits) / Double(totalAllocations) : 0.0
            let currentPoolSize = buckets.reduce(0) { $0 + $1.currentSize }
            let memoryFootprint = buckets.reduce(0) { $0 + $1.memoryFootprint }
            
            let bucketsStatus = buckets.map { bucket in
                (
                    range: "\(bucket.sizeRange.lowerBound)-\(bucket.sizeRange.upperBound)",
                    count: bucket.currentSize,
                    memory: bucket.memoryFootprint
                )
            }
            
            return BufferPoolMetrics(
                hitRate: hitRate,
                totalAllocations: totalAllocations,
                currentPoolSize: currentPoolSize,
                memoryFootprint: memoryFootprint,
                bucketsStatus: bucketsStatus
            )
        }
    }
}

enum MemoryPressureLevel {
    case normal, warning, critical
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

/// High-performance Metal rendering service with shader optimization and buffer pooling
class MetalRenderService {
    private var pipelineState: MTLRenderPipelineState?
    private var device: MTLDevice?
    private var bufferPool: MetalBufferPool?
    
    // Cache for frequently reused buffers
    private var cachedVertexBuffer: PooledBuffer?
    private var fallbackVertexBuffer: MTLBuffer?  // Direct allocation fallback
    
    private func setupPipeline(device: MTLDevice) -> Bool {
        guard self.device !== device else { return pipelineState != nil }
        self.device = device
        
        // Temporarily disable buffer pooling for crash diagnosis
        // bufferPool = MetalBufferPool(device: device, maxPoolSize: 10)
        
        // Pre-create and cache vertex buffer (it's always the same)
        let vertices: [Float] = [
            -1.0, -1.0, 0.0, 1.0,
             1.0, -1.0, 1.0, 1.0,
            -1.0,  1.0, 0.0, 0.0,
             1.0,  1.0, 1.0, 0.0
        ]
        
        let vertexDataSize = vertices.count * MemoryLayout<Float>.stride
        
        // Use direct allocation only for crash diagnosis
        if let directBuffer = device.makeBuffer(bytes: vertices, length: vertexDataSize, options: [.storageModeShared]) {
            fallbackVertexBuffer = directBuffer
        }
        
        // Skip prewarming in playground environment to reduce memory pressure
        
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
    
    func render(device: MTLDevice, drawable: CAMetalDrawable, dots: [MetalDot], splatColor: SIMD3<Float>, renderMask: UInt32, influenceThreshold: Float, aspectRatio: Float, dramaticNoiseAmplitude: Float = 0.3, dramaticVelocityRoughness: Float = 0.4, dramaticNoiseFrequency: Float = 20.0, layerName: String = "") -> Bool {
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
        
        // Use direct vertex buffer only
        if let fallbackBuffer = fallbackVertexBuffer {
            renderEncoder.setVertexBuffer(fallbackBuffer, offset: 0, index: 0)
        } else {
            print("Warning: No vertex buffer available")
            return false
        }
        
        // Use direct allocation for dots buffer
        let dotsDataSize = max(1, dots.count) * MemoryLayout<MetalDot>.stride
        guard let dotsBuffer = device.makeBuffer(length: dotsDataSize, options: [.storageModeShared]) else {
            renderEncoder.endEncoding()
            print("Error: Failed to create dots buffer")
            return false
        }
        
        // Copy dot data efficiently
        if !dots.isEmpty {
            dotsBuffer.contents().copyMemory(
                from: dots,
                byteCount: dotsDataSize
            )
        }
        renderEncoder.setFragmentBuffer(dotsBuffer, offset: 0, index: 0)
        
        // Use direct allocation for uniforms buffer
        let uniformsDataSize = MemoryLayout<FragmentUniforms>.stride
        guard let uniformsBuffer = device.makeBuffer(length: uniformsDataSize, options: [.storageModeShared, .cpuCacheModeWriteCombined]) else {
            renderEncoder.endEncoding()
            print("Error: Failed to create uniforms buffer")
            return false
        }
        
        // Setup uniforms
        var uniforms = FragmentUniforms(
            splatColor: splatColor,
            dotCount: UInt32(dots.count),
            renderMask: renderMask,
            influenceThreshold: influenceThreshold,
            aspectRatio: aspectRatio,
            dramaticNoiseAmplitude: dramaticNoiseAmplitude,
            dramaticVelocityRoughness: dramaticVelocityRoughness,
            dramaticNoiseFrequency: dramaticNoiseFrequency
        )
        
        uniformsBuffer.contents().copyMemory(
            from: &uniforms,
            byteCount: MemoryLayout<FragmentUniforms>.stride
        )
        renderEncoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 1)
        
        // Render
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        // Buffer pooling disabled for crash diagnosis
        
        return true
    }
    
    // MARK: - Buffer Pool Monitoring
    
    private var lastMetricsLog: CFAbsoluteTime = 0
    private let metricsLogInterval: CFAbsoluteTime = 5.0 // Log every 5 seconds
    
    private func logPoolMetrics() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        guard currentTime - lastMetricsLog > metricsLogInterval else { return }
        lastMetricsLog = currentTime
        
        if let metrics = bufferPool?.getMetrics() {
            print("[BUFFER POOL] Hit rate: \(String(format: "%.1f", metrics.hitRate * 100))%, Allocations: \(metrics.totalAllocations), Pool size: \(metrics.currentPoolSize), Memory: \(metrics.memoryFootprint / 1024)KB")
        }
    }
    
    // MARK: - Memory Pressure Handling
    
    func handleMemoryPressure(_ level: MemoryPressureLevel) {
        bufferPool?.adaptToMemoryPressure(level)
    }
    
    func getBufferPoolMetrics() -> MetalBufferPool.BufferPoolMetrics? {
        return bufferPool?.getMetrics()
    }
}

// MARK: - Metal Shader Structures

struct FragmentUniforms {
    let splatColor: SIMD3<Float>
    let dotCount: UInt32
    let renderMask: UInt32
    let influenceThreshold: Float
    let aspectRatio: Float
    let dramaticNoiseAmplitude: Float
    let dramaticVelocityRoughness: Float
    let dramaticNoiseFrequency: Float
}

// MARK: - Metal Shaders

let metalShaderSource = """
#include <metal_stdlib>
using namespace metal;

struct MetalDot {
    float2 position;
    float radius;
    int type;
    float2 velocity;
    float elongation;
};

struct FragmentUniforms {
    float3 splatColor;
    uint dotCount;
    uint renderMask;
    float influenceThreshold;
    float aspectRatio;
    float dramaticNoiseAmplitude;
    float dramaticVelocityRoughness;
    float dramaticNoiseFrequency;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// Noise functions for organic edge distortion
float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(frequency * p);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

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
    
    for (uint i = 0; i < uniforms.dotCount; i++) {
        MetalDot dot = dots[i];
        
        // Check if this dot type is enabled in the render mask
        uint dotTypeMask = 1u << uint(dot.type);
        if ((uniforms.renderMask & dotTypeMask) == 0) {
            continue;
        }
        
        float2 diff = fragCoord - dot.position;
        diff.x *= uniforms.aspectRatio; // Correct for aspect ratio
        
        // Apply velocity-based directional transformation
        float2 transformedDiff = diff;
        if (length(dot.velocity) > 0.001) {
            // Create rotation matrix to align with velocity direction
            float2 velNorm = normalize(dot.velocity);
            float2x2 rotMatrix = float2x2(velNorm.x, velNorm.y, -velNorm.y, velNorm.x);
            transformedDiff = rotMatrix * diff;
            
            // Apply elongation in velocity direction (y-axis after rotation)
            transformedDiff.y /= dot.elongation;
        }
        
        float distance = length(transformedDiff);
        
        // Spatial culling - skip dots with negligible influence
        float effectiveRadius = dot.radius * max(1.0, dot.elongation);
        if (distance > effectiveRadius * 2.0) continue;
        
        // Smooth falloff with noise-based edge distortion
        float normalizedDist = distance / effectiveRadius;
        
        // Add organic edge distortion using configurable noise parameters
        float noiseFreq = uniforms.dramaticNoiseFrequency;
        float noiseAmp = uniforms.dramaticNoiseAmplitude;
        float velRoughness = uniforms.dramaticVelocityRoughness;
        
        float2 noiseCoord = fragCoord * noiseFreq + dot.velocity * 10.0;
        float edgeNoise = fbm(noiseCoord) * noiseAmp;
        float velocityRoughness = length(dot.velocity) * velRoughness;
        float distortedDist = normalizedDist + edgeNoise * velocityRoughness;
        
        float edgeFeather = 0.8 + 0.2 * length(dot.velocity); // More feathering for high velocity
        float influence = 1.0 - smoothstep(0.0, edgeFeather, distortedDist);
        
        totalField += influence;
    }
    
    // Use constants for alpha thresholds
    float alpha = smoothstep(0.7, 1.0, totalField);
    return float4(uniforms.splatColor, alpha);
}
"""

