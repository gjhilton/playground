# SplatterView - Metal-based Ink Splatter Effect

A high-performance SwiftUI view that creates realistic ink splatter effects using Metal shaders and GPU acceleration.

## Version Management

**CRITICAL REQUIREMENT**: All version numbers must be updated together on every change:

1. **SplatterView.swift line 1**: `// Version: X.XX` 
2. **SplatterView.swift line 328**: `splatterViewVersion: "X.XX"` (in JSON export)
3. **ContentView.swift display text**: `Text("X.XX")` (visible version number)

These three locations must always stay synchronized and increment with each modification.

## Required Steps for Every Code Change

**MANDATORY CHECKLIST** - All steps must be completed for every modification:

1. **Update Version Numbers** (all 3 locations):
   - `SplatterView.swift` line 1: `// Version: X.XX`
   - `SplatterView.swift` line 328: `splatterViewVersion: "X.XX"`
   - `ContentView.swift` display text: `Text("X.XX")`

2. **Update README.md**:
   - Update "Current Version" section
   - Add entry to "Version History" with description of changes

3. **Version History Entry Format**:
   ```
   ### X.XX
   - Brief description of changes made
   - Additional bullet points for multiple changes
   ```

## Current Version: 3.19

## Features

- Metal-accelerated GPU rendering for smooth performance
- Multi-layered ink splatter effects with realistic blending
- Configurable dot parameters (size, density, distribution)
- Interactive splat placement via touch/click
- JSON settings export/import for configuration persistence
- Performance monitoring and optimization
- iPad Swift Playground compatible

## Architecture

- **MetalRenderService**: Core Metal rendering pipeline
- **SplatterViewModel**: State management and data coordination  
- **MetalOverlayView**: UIViewRepresentable wrapper for MTKView
- **Buffer Management**: Direct Metal buffer allocation (pooling disabled for stability)

## Next Steps - Blood Splatter Implementation

The following incremental improvements will be implemented to achieve realistic blood splatter effects based on reference images:

### Phase 1: Enhanced Metal Shader (Next)
1. **Update Metal shader to handle velocity-based rendering**:
   - Modify fragment shader to use velocity and elongation fields
   - Add directional stretching based on velocity magnitude
   - Implement edge feathering for organic shapes
   - Test compilation after shader changes

### Phase 2: Velocity-Based Particle Generation
2. **Enhance splat generation with SplatImpact integration**:
   - Update addSplat methods to use SplatImpact struct
   - Generate velocity vectors based on impact force and direction
   - Calculate elongation factors from velocity magnitude
   - Create directional particle distribution patterns

### Phase 3: Multi-Scale Particle System
3. **Implement multi-scale rendering system**:
   - Primary impact zone (large elongated droplets)
   - Secondary scatter particles (medium directional drops)
   - Micro-particle trails (small chaos particles)
   - Velocity-based distribution scaling

### Phase 4: Organic Edge Effects
4. **Add realistic edge distortion**:
   - Noise-based edge perturbation in shader
   - Velocity-dependent edge roughness
   - Multiple texture sampling for organic feel
   - Performance optimization for real-time rendering

### Phase 5: Advanced Physics Integration
5. **Implement realistic physics simulation**:
   - Gravity effects on particle trajectories
   - Surface tension simulation for droplet formation
   - Collision detection for realistic splashing
   - Time-based animation effects

Each phase will be implemented incrementally with Xcode project compilation testing after every change to ensure stability and compatibility.

## Version History

### 3.19
- Enhanced MetalDot structure with velocity and elongation fields
- Added velocity vector for directional effects
- Added elongation factor for non-circular shapes
- Updated initializers with default values for backward compatibility

### 3.18
- Added SplatImpact struct for directional splatter effects
- Defined velocity, force, and timestamp properties
- Established foundation for velocity-based particle system

### 3.17
- Added mandatory checklist for every code change to README.md
- Documented required steps: version updates + README maintenance
- Established version history entry format standards

### 3.16
- Added README.md with version management requirements documentation
- Established protocol for consistent version tracking across all files