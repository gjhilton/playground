# SplatterView Changes Since Version 3.17

## Overview
This document provides a comprehensive overview of all changes made to the SplatterView project from version 3.17 to 3.27. The primary focus has been implementing realistic blood splatter effects with configurable dramatic parameters and a new third rendering layer.

## Version History Summary

**3.17 → 3.18**: Added SplatImpact struct for directional effects
**3.18 → 3.19**: Enhanced MetalDot with velocity and elongation fields  
**3.19 → 3.24**: Implemented 5-phase blood splatter enhancement plan
**3.24 → 3.25**: Made effects dramatically more visible
**3.25 → 3.26**: Added configurable parameters and third rendering layer
**3.26 → 3.27**: Fixed startup crash with complete default settings

---

## Major Feature Additions

### 1. Dramatic Effects Rendering Layer (Version 3.26)

#### New Third Rendering Pass
Added a completely separate "dramatic" rendering layer alongside the existing background and foreground passes.

**Code Example - RenderPasses Array:**
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
            name: "dramatic",           // NEW LAYER
            enabled: rendering.dramaticPassEnabled,
            color: rendering.dramaticPassColor.simd3,
            renderMask: computeDramaticRenderMask(),
            opacity: rendering.dramaticPassOpacity,
            zIndex: 2                  // Renders on top
        )
    ]
}
```

#### Layer Controls Added
The dramatic layer has independent controls for:
- **Enable/Disable Toggle**: `dramaticPassEnabled`
- **Color Selection**: `dramaticPassColor` (defaults to dark red)
- **Opacity Control**: `dramaticPassOpacity` (0.0-1.0, defaults to 0.8)
- **Dot Type Selection**: Individual toggles for Central, Large, Medium, Small dots

### 2. Configurable Dramatic Effect Parameters (Version 3.26)

#### New Parameter System
Added 9 new configurable parameters that control the intensity and behavior of dramatic effects:

**Code Example - RenderingParams Extension:**
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
@Published var dramaticVelocityX: Float = 1.5      // Impact velocity X component
@Published var dramaticVelocityY: Float = 0.8      // Impact velocity Y component  
@Published var dramaticForce: Float = 1.0          // Impact force (0.0-1.0)
@Published var dramaticCentralElongation: Float = 5.0    // Central dot stretch factor
@Published var dramaticParticleElongation: Float = 3.0   // Particle stretch factor
@Published var dramaticTimeElongation: Float = 4.0       // Time-based elongation
@Published var dramaticNoiseAmplitude: Float = 0.8       // Edge distortion strength
@Published var dramaticVelocityRoughness: Float = 1.2    // Velocity-based roughness
@Published var dramaticNoiseFrequency: Float = 30.0      // Noise texture frequency
```

#### Parameter Usage in Splat Generation
**Code Example - Dynamic Parameter Application:**
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

#### Configurable Elongation Effects
**Code Example - Central Dot Elongation:**
```swift
// Apply impact velocity and force to central dot with configurable elongation
let velocityMagnitude = length(impact.velocity)
let elongationMultiplier = rendering.dramaticPassEnabled ? 
    rendering.dramaticCentralElongation : 2.0
let elongationFactor = 1.0 + velocityMagnitude * impact.force * elongationMultiplier
```

**Code Example - Particle Elongation:**
```swift
// Time-based elongation - particles elongate based on configurable parameters
let timeElongationMultiplier = rendering.dramaticPassEnabled ? 
    rendering.dramaticTimeElongation : 2.0
let particleElongationMultiplier = rendering.dramaticPassEnabled ? 
    rendering.dramaticParticleElongation : 1.5
let timeElongation = trajectoryTime * timeElongationMultiplier
let particleVelocityMagnitude = length(finalParticleVelocity)
let elongation = 1.0 + (particleVelocityMagnitude * impact.force * particleElongationMultiplier) + timeElongation
```

### 3. Enhanced Metal Shader System (Version 3.24-3.25)

#### New FragmentUniforms Structure
**Code Example - Extended Uniforms:**
```swift
struct FragmentUniforms {
    let splatColor: SIMD3<Float>
    let dotCount: UInt32
    let renderMask: UInt32
    let influenceThreshold: Float
    let aspectRatio: Float
    let dramaticNoiseAmplitude: Float      // NEW
    let dramaticVelocityRoughness: Float   // NEW
    let dramaticNoiseFrequency: Float      // NEW
    let isDramaticPass: UInt32             // NEW
}
```

#### Configurable Metal Shader Effects
**Code Example - Dynamic Shader Parameters:**
```metal
// Add organic edge distortion using configurable noise parameters
float noiseFreq = uniforms.isDramaticPass > 0 ? uniforms.dramaticNoiseFrequency : 20.0;
float noiseAmp = uniforms.isDramaticPass > 0 ? uniforms.dramaticNoiseAmplitude : 0.3;
float velRoughness = uniforms.isDramaticPass > 0 ? uniforms.dramaticVelocityRoughness : 0.4;

float2 noiseCoord = fragCoord * noiseFreq + dot.velocity * 10.0;
float edgeNoise = fbm(noiseCoord) * noiseAmp;
float velocityRoughness = length(dot.velocity) * velRoughness;
```

**Effect Comparison:**
- **Normal Layer**: noise frequency 20.0, amplitude 0.3, roughness 0.4
- **Dramatic Layer**: noise frequency 30.0, amplitude 0.8, roughness 1.2 (configurable)

### 4. Velocity-Based Physics System (Version 3.19-3.24)

#### Enhanced MetalDot Structure
**Code Example - Extended Dot Properties:**
```swift
struct MetalDot: Equatable, Hashable {
    var position: SIMD2<Float>     // (x, y) in Metal coordinate space [0,1]
    var radius: Float              // Normalized radius [0,1]
    var type: Int32               // Dot type enum raw value [0-3]
    var velocity: SIMD2<Float>    // NEW: Velocity vector for directional effects
    var elongation: Float         // NEW: Stretch factor [1.0 = circular, >1.0 = elongated]
    
    init(position: SIMD2<Float>, radius: Float, type: DotType, 
         velocity: SIMD2<Float> = SIMD2<Float>(0, 0), elongation: Float = 1.0) {
        self.position = position
        self.radius = radius
        self.type = type.rawValue
        self.velocity = velocity      // NEW
        self.elongation = elongation  // NEW
    }
}
```

#### SplatImpact System
**Code Example - Impact Data Structure:**
```swift
struct SplatImpact {
    let position: CGPoint
    let velocity: SIMD2<Float>  // Direction and magnitude
    let force: Float           // Impact strength [0,1]
    let timestamp: Double      // For animation effects
}
```

#### Physics-Based Particle Generation
**Code Example - Trajectory Calculation:**
```swift
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
```

### 5. Enhanced UI Controls (Version 3.26)

#### New Dramatic Effects Panel
**Code Example - UI Controls Section:**
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
                // Color picker
                ColorPicker("Dramatic Color", selection: $viewModel.rendering.dramaticPassColor)
                
                // Opacity slider
                HStack {
                    Text("Opacity: \(viewModel.rendering.dramaticPassOpacity, specifier: "%.2f")")
                    Spacer()
                }
                Slider(value: $viewModel.rendering.dramaticPassOpacity, in: 0...1)
                
                // Effect parameters with real-time sliders
                HStack {
                    Text("Velocity X: \(viewModel.rendering.dramaticVelocityX, specifier: "%.2f")")
                    Spacer()
                }
                Slider(value: $viewModel.rendering.dramaticVelocityX, in: 0.0...3.0)
                
                // ... 8 more parameter sliders
            }
        }
    }
}
```

#### Red-Tinted Toggles for Visual Distinction
**Code Example - Color-Coded Controls:**
```swift
HStack {
    Toggle("Central", isOn: $viewModel.rendering.dramaticCentralDot)
        .toggleStyle(SwitchToggleStyle(tint: .red))      // Red for dramatic
    Toggle("Large", isOn: $viewModel.rendering.dramaticLargeDots)
        .toggleStyle(SwitchToggleStyle(tint: .red))
}
```

### 6. Settings Export/Import System (Version 3.26-3.27)

#### Extended Settings Structure
**Code Example - New Settings Schema:**
```swift
struct SplatterSettings: Codable {
    let splatterViewVersion: String
    let rendering: RenderingSettings
    let randomisation: RandomisationSettings
    let dots: DotParameters
    let layers: LayerSettings
    let dramaticEffects: DramaticEffectsSettings  // NEW
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
```

#### Complete Default Settings (Version 3.27)
**Code Example - Crash-Fixed JSON:**
```json
{
  "splatterView version": "3.27",
  "rendering": { "influenceThreshold": 0.001 },
  "randomisation": { "rngSeed": 12345, "useSeededRNG": false },
  "dots": { /* dot parameters */ },
  "layers": { /* layer settings */ },
  "dramaticEffects": {
    "passEnabled": false,
    "passColor": { "r": 0.6, "g": 0.0, "b": 0.0 },
    "passOpacity": 0.8,
    "dotTypes": {
      "central": true, "large": true, "medium": true, "small": true
    },
    "velocityX": 1.5, "velocityY": 0.8, "force": 1.0,
    "centralElongation": 5.0, "particleElongation": 3.0, "timeElongation": 4.0,
    "noiseAmplitude": 0.8, "velocityRoughness": 1.2, "noiseFrequency": 30.0
  }
}
```

---

## Technical Implementation Details

### Metal Rendering Pipeline Changes

#### Enhanced Render Method Signature
**Before (3.17):**
```swift
func render(device: MTLDevice, drawable: CAMetalDrawable, dots: [MetalDot], 
           splatColor: SIMD3<Float>, renderMask: UInt32, influenceThreshold: Float, 
           aspectRatio: Float) -> Bool
```

**After (3.26):**
```swift
func render(device: MTLDevice, drawable: CAMetalDrawable, dots: [MetalDot], 
           splatColor: SIMD3<Float>, renderMask: UInt32, influenceThreshold: Float, 
           aspectRatio: Float, dramaticNoiseAmplitude: Float = 0.3, 
           dramaticVelocityRoughness: Float = 0.4, dramaticNoiseFrequency: Float = 20.0, 
           isDramaticPass: Bool = false) -> Bool
```

#### MetalOverlayView Parameter Expansion
**Code Example - Enhanced View Properties:**
```swift
struct MetalOverlayView: UIViewRepresentable {
    let dots: [MetalDot]
    let splatColor: SIMD3<Float>
    let renderMask: UInt32
    let influenceThreshold: Float
    let dramaticNoiseAmplitude: Float     // NEW
    let dramaticVelocityRoughness: Float  // NEW  
    let dramaticNoiseFrequency: Float     // NEW
    let isDramaticPass: Bool              // NEW
}
```

### Performance Optimizations

#### Render Mask Computation
**Code Example - Three-Layer Mask System:**
```swift
private func computeRenderMask() -> UInt32 {
    // Generate dots for any type enabled in any pass
    let backgroundMask = computeBackgroundRenderMask()
    let foregroundMask = computeForegroundRenderMask() 
    let dramaticMask = computeDramaticRenderMask()     // NEW
    return backgroundMask | foregroundMask | dramaticMask
}

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

---

## Visual Effect Comparison

### Before (Version 3.17)
- Single rendering pass with basic circular dots
- Fixed splatter patterns
- No velocity-based effects
- No elongation or directional streaking

### After (Version 3.27)
- **Three independent rendering layers** (background, foreground, dramatic)
- **Velocity-based directional splattering** with physics simulation
- **Dynamic elongation effects** based on impact force and flight time
- **Configurable noise distortion** for organic edge effects
- **Real-time parameter adjustment** through comprehensive UI
- **Physics-based particle trajectories** with gravity and surface tension
- **Multi-scale particle systems** (central, large, medium, small, micro)

### Parameter Ranges and Effects

| Parameter | Range | Effect |
|-----------|--------|---------|
| Velocity X/Y | 0.0-3.0 | Controls initial impact direction and magnitude |
| Force | 0.0-1.0 | Impact strength affecting all elongation effects |
| Central Elongation | 1.0-10.0 | Stretch factor for main splat blob |
| Particle Elongation | 1.0-5.0 | Stretch factor for satellite particles |
| Time Elongation | 1.0-8.0 | Time-based elongation during particle flight |
| Noise Amplitude | 0.0-2.0 | Strength of organic edge distortion |
| Velocity Roughness | 0.0-3.0 | Velocity-dependent edge irregularity |
| Noise Frequency | 10.0-50.0 | Texture frequency for edge distortion |

---

## Usage Instructions

### Enabling Dramatic Effects
1. Open the parameter controls panel (editor mode enabled)
2. Scroll to "Dramatic Effects" section
3. Toggle "Dramatic Pass" to enable
4. Adjust color, opacity, and effect parameters as desired
5. Enable/disable specific dot types for the dramatic layer
6. Create splats to see the dramatic effects overlay

### Parameter Tuning Guidelines
- **For subtle effects**: Keep parameters below default values
- **For extreme effects**: Push velocity (2.0+), elongation (7.0+), noise amplitude (1.5+)
- **For blood-like effects**: Use dark red color, high elongation, moderate noise
- **For ink-like effects**: Use black/blue colors, lower elongation, higher velocity

### Export/Import Settings
- Use "Export Settings" to save current configuration to clipboard
- Use "Import Settings" to load configuration from clipboard
- Settings include all dramatic effect parameters for complete reproduction

---

## Version 3.27 Crash Fix

### Issue
The app crashed on launch because the default settings JSON was missing the new `dramaticEffects` section required by the updated settings structure.

### Solution
Added complete `dramaticEffects` section to default settings JSON with safe default values:
- Dramatic pass disabled by default (`passEnabled: false`)
- Conservative parameter values that won't overwhelm users
- Complete dot type configuration to prevent decode failures

This ensures backwards compatibility while providing full access to the new dramatic effects system.