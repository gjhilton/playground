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

## Current Version: 3.17

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

## Version History

### 3.17
- Added mandatory checklist for every code change to README.md
- Documented required steps: version updates + README maintenance
- Established version history entry format standards

### 3.16
- Added README.md with version management requirements documentation
- Established protocol for consistent version tracking across all files