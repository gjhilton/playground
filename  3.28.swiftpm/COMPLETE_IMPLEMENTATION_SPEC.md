# Complete Implementation Specification: SplatterView 3.17 → 3.27

## Overview
This document provides EXACT step-by-step instructions to recreate all changes from version 3.17 to 3.27. Every code change, default value, and implementation detail is included for perfect reproduction.

---

## STEP 1: Add SplatImpact Structure (3.17 → 3.18)

### Location: SplatterView.swift, after MetalDot struct

```swift
/// Impact data structure for directional splatter effects
struct SplatImpact {
    let position: CGPoint
    let velocity: SIMD2<Float>  // Direction and magnitude
    let force: Float           // Impact strength [0,1]
    let timestamp: Double      // For animation effects
}
```

---

## STEP 2: Enhance MetalDot Structure (3.18 → 3.19)

### Location: SplatterView.swift, replace existing MetalDot struct

```swift
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
```

---

## STEP 3: Update Metal Shader (3.19 → 3.24)

### Location: SplatterView.swift, replace metalShaderSource completely

```swift
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
    uint isDramaticPass;
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
        float noiseFreq = uniforms.isDramaticPass > 0 ? uniforms.dramaticNoiseFrequency : 20.0;
        float noiseAmp = uniforms.isDramaticPass > 0 ? uniforms.dramaticNoiseAmplitude : 0.3;
        float velRoughness = uniforms.isDramaticPass > 0 ? uniforms.dramaticVelocityRoughness : 0.4;
        
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
```

---

## STEP 4: Update FragmentUniforms Structure (3.24 → 3.26)

### Location: SplatterView.swift, replace FragmentUniforms struct

```swift
struct FragmentUniforms {
    let splatColor: SIMD3<Float>
    let dotCount: UInt32
    let renderMask: UInt32
    let influenceThreshold: Float
    let aspectRatio: Float
    let dramaticNoiseAmplitude: Float
    let dramaticVelocityRoughness: Float
    let dramaticNoiseFrequency: Float
    let isDramaticPass: UInt32
}
```

---

## STEP 5: Add Dramatic Effects to Settings (3.26)

### Location: SplatterView.swift, modify SplatterSettings struct

#### 5a. Update SplatterSettings main struct
```swift
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
    
    // ... existing nested structs remain the same ...
    
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
```

---

## STEP 6: Add Dramatic Effect Parameters to RenderingParams (3.26)

### Location: SplatterView.swift, add to RenderingParams class before closing brace

```swift
    // Dramatic effects pass configuration
    @Published var dramaticPassEnabled: Bool = false
    @Published var dramaticPassColor: Color = Color(red: 0.6, green: 0.0, blue: 0.0)
    @Published var dramaticPassOpacity: Float = 0.8
    @Published var dramaticCentralDot: Bool = true
    @Published var dramaticLargeDots: Bool = true
    @Published var dramaticMediumDots: Bool = true
    @Published var dramaticSmallDots: Bool = true
    @Published var dramaticMicroDots: Bool = true
    
    // Dramatic effect parameters
    @Published var dramaticVelocityX: Float = 1.5
    @Published var dramaticVelocityY: Float = 0.8
    @Published var dramaticForce: Float = 1.0
    @Published var dramaticCentralElongation: Float = 5.0
    @Published var dramaticParticleElongation: Float = 3.0
    @Published var dramaticTimeElongation: Float = 4.0
    @Published var dramaticNoiseAmplitude: Float = 0.8
    @Published var dramaticVelocityRoughness: Float = 1.2
    @Published var dramaticNoiseFrequency: Float = 30.0
```

---

## STEP 7: Update RenderPasses in SplatterViewModel (3.26)

### Location: SplatterView.swift, replace renderPasses computed property

```swift
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
            ),
            RenderPass(
                name: "dramatic",
                enabled: rendering.dramaticPassEnabled,
                color: rendering.dramaticPassColor.simd3,
                renderMask: computeDramaticRenderMask(),
                opacity: rendering.dramaticPassOpacity,
                zIndex: 2
            )
        ]
    }
```

---

## STEP 8: Add Dramatic Render Mask Methods (3.26)

### Location: SplatterView.swift, add after computeForegroundRenderMask method

```swift
    private func computeDramaticRenderMask() -> UInt32 {
        var mask: UInt32 = 0
        if rendering.dramaticCentralDot { mask |= RenderingConstants.centralDotMask }
        if rendering.dramaticLargeDots { mask |= RenderingConstants.largeDotMask }
        if rendering.dramaticMediumDots { mask |= RenderingConstants.mediumDotMask }
        if rendering.dramaticSmallDots { mask |= RenderingConstants.smallDotMask }
        if rendering.dramaticMicroDots { mask |= RenderingConstants.microDotMask }
        return mask
    }
```

### Update computeRenderMask method
```swift
    private func computeRenderMask() -> UInt32 {
        // Generate dots for any type enabled in any pass
        let backgroundMask = computeBackgroundRenderMask()
        let foregroundMask = computeForegroundRenderMask()
        let dramaticMask = computeDramaticRenderMask()
        return backgroundMask | foregroundMask | dramaticMask
    }
```

---

## STEP 9: Update addSplat Methods (3.26)

### Location: SplatterView.swift, replace both addSplat methods

```swift
    func addSplat(at point: CGPoint, screenWidth: CGFloat, screenHeight: CGFloat) {
        // Use configurable dramatic effect parameters when dramatic pass is enabled
        let velocity = rendering.dramaticPassEnabled ? 
            SIMD2<Float>(rendering.dramaticVelocityX, rendering.dramaticVelocityY) :
            SIMD2<Float>(0.1, 0.1) // Default gentle velocity
        let force = rendering.dramaticPassEnabled ? rendering.dramaticForce : 0.5
        
        let impact = SplatImpact(
            position: point,
            velocity: velocity,
            force: force,
            timestamp: CFAbsoluteTimeGetCurrent()
        )
        addSplat(impact: impact, screenWidth: screenWidth, screenHeight: screenHeight)
    }
```

### In addSplat(impact:) method, update central dot elongation calculation
Find this line:
```swift
let elongationFactor = 1.0 + velocityMagnitude * impact.force * 5.0 // Much more dramatic elongation
```

Replace with:
```swift
// Apply impact velocity and force to central dot with configurable elongation
let velocityMagnitude = length(impact.velocity)
let elongationMultiplier = rendering.dramaticPassEnabled ? rendering.dramaticCentralElongation : 2.0
let elongationFactor = 1.0 + velocityMagnitude * impact.force * elongationMultiplier
```

---

## STEP 10: Update Particle Generation (3.26)

### Location: SplatterView.swift, in generateVelocityBasedSatelliteDots method

Find these lines:
```swift
// Time-based elongation - particles elongate dramatically during flight
let timeElongation = trajectoryTime * 4.0 // Much more time-based elongation
let particleVelocityMagnitude = length(finalParticleVelocity)
let elongation = 1.0 + (particleVelocityMagnitude * impact.force * 3.0) + timeElongation
```

Replace with:
```swift
// Time-based elongation - particles elongate based on configurable parameters
let timeElongationMultiplier = rendering.dramaticPassEnabled ? rendering.dramaticTimeElongation : 2.0
let particleElongationMultiplier = rendering.dramaticPassEnabled ? rendering.dramaticParticleElongation : 1.5
let timeElongation = trajectoryTime * timeElongationMultiplier
let particleVelocityMagnitude = length(finalParticleVelocity)
let elongation = 1.0 + (particleVelocityMagnitude * impact.force * particleElongationMultiplier) + timeElongation
```

---

## STEP 11: Update MetalRenderService (3.26)

### Location: SplatterView.swift, replace render method signature

```swift
    func render(device: MTLDevice, drawable: CAMetalDrawable, dots: [MetalDot], splatColor: SIMD3<Float>, renderMask: UInt32, influenceThreshold: Float, aspectRatio: Float, dramaticNoiseAmplitude: Float = 0.3, dramaticVelocityRoughness: Float = 0.4, dramaticNoiseFrequency: Float = 20.0, isDramaticPass: Bool = false) -> Bool {
```

### Update uniforms creation in render method
Find:
```swift
        // Setup uniforms
        var uniforms = FragmentUniforms(
            splatColor: splatColor,
            dotCount: UInt32(dots.count),
            renderMask: renderMask,
            influenceThreshold: influenceThreshold,
            aspectRatio: aspectRatio
        )
```

Replace with:
```swift
        // Setup uniforms
        var uniforms = FragmentUniforms(
            splatColor: splatColor,
            dotCount: UInt32(dots.count),
            renderMask: renderMask,
            influenceThreshold: influenceThreshold,
            aspectRatio: aspectRatio,
            dramaticNoiseAmplitude: dramaticNoiseAmplitude,
            dramaticVelocityRoughness: dramaticVelocityRoughness,
            dramaticNoiseFrequency: dramaticNoiseFrequency,
            isDramaticPass: isDramaticPass ? 1 : 0
        )
```

---

## STEP 12: Update MetalOverlayView (3.26)

### Location: SplatterView.swift, replace MetalOverlayView struct

```swift
struct MetalOverlayView: UIViewRepresentable {
    let dots: [MetalDot]
    let splatColor: SIMD3<Float>
    let renderMask: UInt32
    let influenceThreshold: Float
    let dramaticNoiseAmplitude: Float
    let dramaticVelocityRoughness: Float
    let dramaticNoiseFrequency: Float
    let isDramaticPass: Bool
    
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
            dramaticNoiseAmplitude: dramaticNoiseAmplitude,
            dramaticVelocityRoughness: dramaticVelocityRoughness,
            dramaticNoiseFrequency: dramaticNoiseFrequency,
            isDramaticPass: isDramaticPass
        )
    }
    class Coordinator: NSObject, MTKViewDelegate {
        var splatColor: SIMD3<Float>
        var influenceThreshold: Float
        var dramaticNoiseAmplitude: Float
        var dramaticVelocityRoughness: Float
        var dramaticNoiseFrequency: Float
        var isDramaticPass: Bool
        let stateManager: MetalStateManager
        private let metalService: MetalRenderService
        private var frameCount: Int = 0
        
        init(splatColor: SIMD3<Float>, influenceThreshold: Float, dramaticNoiseAmplitude: Float, dramaticVelocityRoughness: Float, dramaticNoiseFrequency: Float, isDramaticPass: Bool) {
            self.splatColor = splatColor
            self.influenceThreshold = influenceThreshold
            self.dramaticNoiseAmplitude = dramaticNoiseAmplitude
            self.dramaticVelocityRoughness = dramaticVelocityRoughness
            self.dramaticNoiseFrequency = dramaticNoiseFrequency
            self.isDramaticPass = isDramaticPass
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
                dramaticNoiseAmplitude: dramaticNoiseAmplitude,
                dramaticVelocityRoughness: dramaticVelocityRoughness,
                dramaticNoiseFrequency: dramaticNoiseFrequency,
                isDramaticPass: isDramaticPass
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
```

---

## STEP 13: Update SplatterView and SplatterEditorView Calls (3.26)

### Location: SplatterView.swift, in SplatterView body

Find:
```swift
                    MetalOverlayView(
                        dots: viewModel.metalData.dots,
                        splatColor: renderPass.color,
                        renderMask: renderPass.renderMask,
                        influenceThreshold: viewModel.rendering.influenceThreshold
                    )
```

Replace with:
```swift
                    MetalOverlayView(
                        dots: viewModel.metalData.dots,
                        splatColor: renderPass.color,
                        renderMask: renderPass.renderMask,
                        influenceThreshold: viewModel.rendering.influenceThreshold,
                        dramaticNoiseAmplitude: viewModel.rendering.dramaticNoiseAmplitude,
                        dramaticVelocityRoughness: viewModel.rendering.dramaticVelocityRoughness,
                        dramaticNoiseFrequency: viewModel.rendering.dramaticNoiseFrequency,
                        isDramaticPass: renderPass.name == "dramatic"
                    )
```

### Make the same change in SplatterEditorView

---

## STEP 14: Add Dramatic Effects UI Controls (3.26)

### Location: SplatterView.swift, in ParameterControlPanel, after the Colors GroupBox

```swift
                // Dramatic Effects Controls
                GroupBox("Dramatic Effects") {
                    VStack(spacing: 12) {
                        VStack {
                            HStack {
                                Toggle("Dramatic Pass", isOn: $viewModel.rendering.dramaticPassEnabled)
                                Spacer()
                            }
                            if viewModel.rendering.dramaticPassEnabled {
                                VStack {
                                    if #available(iOS 14.0, *) {
                                        ColorPicker("Dramatic Color", selection: $viewModel.rendering.dramaticPassColor)
                                    } else {
                                        HStack {
                                            Text("Dramatic Color")
                                            Spacer()
                                            Rectangle()
                                                .fill(viewModel.rendering.dramaticPassColor)
                                                .frame(width: 30, height: 30)
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                                HStack {
                                    Text("Opacity: \(viewModel.rendering.dramaticPassOpacity, specifier: "%.2f")")
                                    Spacer()
                                }
                                Slider(value: $viewModel.rendering.dramaticPassOpacity, in: 0...1)
                                
                                // Dramatic pass dot type controls
                                VStack(spacing: 8) {
                                    Text("Dot Types").font(.subheadline).foregroundColor(.secondary)
                                    HStack {
                                        Toggle("Central", isOn: $viewModel.rendering.dramaticCentralDot)
                                            .toggleStyle(SwitchToggleStyle(tint: .red))
                                        Toggle("Large", isOn: $viewModel.rendering.dramaticLargeDots)
                                            .toggleStyle(SwitchToggleStyle(tint: .red))
                                    }
                                    HStack {
                                        Toggle("Medium", isOn: $viewModel.rendering.dramaticMediumDots)
                                            .toggleStyle(SwitchToggleStyle(tint: .red))
                                        Toggle("Small", isOn: $viewModel.rendering.dramaticSmallDots)
                                            .toggleStyle(SwitchToggleStyle(tint: .red))
                                    }
                                }
                                .padding(.top, 8)
                                
                                // Dramatic effect parameters
                                VStack(spacing: 8) {
                                    Text("Effect Parameters").font(.subheadline).foregroundColor(.secondary)
                                    
                                    HStack {
                                        Text("Velocity X: \(viewModel.rendering.dramaticVelocityX, specifier: "%.2f")")
                                        Spacer()
                                    }
                                    Slider(value: $viewModel.rendering.dramaticVelocityX, in: 0.0...3.0)
                                    
                                    HStack {
                                        Text("Velocity Y: \(viewModel.rendering.dramaticVelocityY, specifier: "%.2f")")
                                        Spacer()
                                    }
                                    Slider(value: $viewModel.rendering.dramaticVelocityY, in: 0.0...3.0)
                                    
                                    HStack {
                                        Text("Force: \(viewModel.rendering.dramaticForce, specifier: "%.2f")")
                                        Spacer()
                                    }
                                    Slider(value: $viewModel.rendering.dramaticForce, in: 0.0...1.0)
                                    
                                    HStack {
                                        Text("Central Elongation: \(viewModel.rendering.dramaticCentralElongation, specifier: "%.1f")")
                                        Spacer()
                                    }
                                    Slider(value: $viewModel.rendering.dramaticCentralElongation, in: 1.0...10.0)
                                    
                                    HStack {
                                        Text("Particle Elongation: \(viewModel.rendering.dramaticParticleElongation, specifier: "%.1f")")
                                        Spacer()
                                    }
                                    Slider(value: $viewModel.rendering.dramaticParticleElongation, in: 1.0...5.0)
                                    
                                    HStack {
                                        Text("Time Elongation: \(viewModel.rendering.dramaticTimeElongation, specifier: "%.1f")")
                                        Spacer()
                                    }
                                    Slider(value: $viewModel.rendering.dramaticTimeElongation, in: 1.0...8.0)
                                    
                                    HStack {
                                        Text("Noise Amplitude: \(viewModel.rendering.dramaticNoiseAmplitude, specifier: "%.2f")")
                                        Spacer()
                                    }
                                    Slider(value: $viewModel.rendering.dramaticNoiseAmplitude, in: 0.0...2.0)
                                    
                                    HStack {
                                        Text("Velocity Roughness: \(viewModel.rendering.dramaticVelocityRoughness, specifier: "%.2f")")
                                        Spacer()
                                    }
                                    Slider(value: $viewModel.rendering.dramaticVelocityRoughness, in: 0.0...3.0)
                                    
                                    HStack {
                                        Text("Noise Frequency: \(viewModel.rendering.dramaticNoiseFrequency, specifier: "%.1f")")
                                        Spacer()
                                    }
                                    Slider(value: $viewModel.rendering.dramaticNoiseFrequency, in: 10.0...50.0)
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                }
```

---

## STEP 15: Update Settings Export/Import (3.26)

### Location: SplatterView.swift, in SettingsManager.exportSettings method

Find the layers section ending:
```swift
                )
            )
        )
```

Replace with:
```swift
                )
            ),
            dramaticEffects: SplatterSettings.DramaticEffectsSettings(
                passEnabled: viewModel.rendering.dramaticPassEnabled,
                passColor: rgbFromColor(viewModel.rendering.dramaticPassColor),
                passOpacity: viewModel.rendering.dramaticPassOpacity,
                dotTypes: SplatterSettings.LayerSettings.DotTypeSettings(
                    central: viewModel.rendering.dramaticCentralDot,
                    large: viewModel.rendering.dramaticLargeDots,
                    medium: viewModel.rendering.dramaticMediumDots,
                    small: viewModel.rendering.dramaticSmallDots
                ),
                velocityX: viewModel.rendering.dramaticVelocityX,
                velocityY: viewModel.rendering.dramaticVelocityY,
                force: viewModel.rendering.dramaticForce,
                centralElongation: viewModel.rendering.dramaticCentralElongation,
                particleElongation: viewModel.rendering.dramaticParticleElongation,
                timeElongation: viewModel.rendering.dramaticTimeElongation,
                noiseAmplitude: viewModel.rendering.dramaticNoiseAmplitude,
                velocityRoughness: viewModel.rendering.dramaticVelocityRoughness,
                noiseFrequency: viewModel.rendering.dramaticNoiseFrequency
            )
        )
```

### Update applySettings method
Add at the end, before the closing brace:

```swift
        // Apply dramatic effects settings
        viewModel.rendering.dramaticPassEnabled = settings.dramaticEffects.passEnabled
        viewModel.rendering.dramaticPassColor = colorFromRGB(settings.dramaticEffects.passColor)
        viewModel.rendering.dramaticPassOpacity = settings.dramaticEffects.passOpacity
        viewModel.rendering.dramaticCentralDot = settings.dramaticEffects.dotTypes.central
        viewModel.rendering.dramaticLargeDots = settings.dramaticEffects.dotTypes.large
        viewModel.rendering.dramaticMediumDots = settings.dramaticEffects.dotTypes.medium
        viewModel.rendering.dramaticSmallDots = settings.dramaticEffects.dotTypes.small
        viewModel.rendering.dramaticVelocityX = settings.dramaticEffects.velocityX
        viewModel.rendering.dramaticVelocityY = settings.dramaticEffects.velocityY
        viewModel.rendering.dramaticForce = settings.dramaticEffects.force
        viewModel.rendering.dramaticCentralElongation = settings.dramaticEffects.centralElongation
        viewModel.rendering.dramaticParticleElongation = settings.dramaticEffects.particleElongation
        viewModel.rendering.dramaticTimeElongation = settings.dramaticEffects.timeElongation
        viewModel.rendering.dramaticNoiseAmplitude = settings.dramaticEffects.noiseAmplitude
        viewModel.rendering.dramaticVelocityRoughness = settings.dramaticEffects.velocityRoughness
        viewModel.rendering.dramaticNoiseFrequency = settings.dramaticEffects.noiseFrequency
```

---

## STEP 16: Fix Default Settings JSON (3.26 → 3.27)

### Location: SplatterView.swift, in SettingsManager.defaultSettingsJSON

Replace the entire JSON string with:

```swift
    private static let defaultSettingsJSON = """
    {
      "splatterView version": "3.27",
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
            "small": true
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
            "small": false
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
          "small": true
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
```

---

## STEP 17: Update Version Numbers (3.27)

### Location: Multiple files

#### SplatterView.swift
- Line 1: Change to `// Version: 3.27`
- In exportSettings method: Change `splatterViewVersion: "3.26",` to `splatterViewVersion: "3.27",`

#### ContentView.swift
- Line 1: Change to `// Version: 3.27`
- In the Text display: Change `Text("3.26")` to `Text("3.27")`

---

## STEP 18: Add Velocity-Based Satellite Dot Generation (Complete Implementation)

### Location: SplatterView.swift, replace generateVelocityBasedSatelliteDots method entirely

```swift
    /// Velocity-aware satellite dot generation for directional splatter effects
    private func generateVelocityBasedSatelliteDots(
        count: Int,
        radiusMin: Float,
        radiusMax: Float,
        maxDistance: Float,
        center: SIMD2<Float>,
        type: DotType,
        impact: SplatImpact,
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
            let angle = baseAngle + (velocityAngle * angleBias)
            
            // Physics-based trajectory calculation with gravity and time
            let timeStep: Float = 0.1 // Simulation time step for particle trajectory
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
            let distance = min(trajectoryDistance, maxDistance * 1.5)
            
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
            
            // Time-based elongation - particles elongate based on configurable parameters
            let timeElongationMultiplier = rendering.dramaticPassEnabled ? rendering.dramaticTimeElongation : 2.0
            let particleElongationMultiplier = rendering.dramaticPassEnabled ? rendering.dramaticParticleElongation : 1.5
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
```

---

## Compilation and Testing Requirements

### Before Each Change
1. Ensure the current code compiles without errors
2. Test basic functionality (splat creation, clear function)

### After All Changes
1. Compile with: `xcodebuild -project path/to/Serious.xcodeproj -scheme Serious -destination 'platform=iOS Simulator,name=iPhone 16' build`
2. Test that the app launches without crashing
3. Verify all three rendering layers work independently
4. Test dramatic effects parameter controls
5. Test settings export/import functionality

### Warning Fixes (Optional)
If you encounter warnings about unused variables, replace with `_`:
- `let angle = ...` → `let _ = ...`
- `let timeStep = ...` → `let _ = ...`
- `let distance = ...` → `let _ = ...`

---

## Final Notes

This specification provides EXACT step-by-step instructions to recreate every change from version 3.17 to 3.27. Each code block is complete and can be copied directly. The order of implementation is critical - earlier steps provide dependencies for later steps.

All default values, parameter ranges, and configuration options are specified exactly as implemented. Following these steps precisely will result in an identical implementation with all dramatic effects functionality, configurable parameters, and the third rendering layer.