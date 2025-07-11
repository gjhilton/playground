# Animated Text Swift Playground

A refactored Swift playground demonstrating animated text effects with improved architecture, maintainability, and extensibility. Now includes a complete motion graphics system with keyframe-based animations for creating complex splash screen sequences.

## Architecture Overview

The playground has been refactored to follow clean architecture principles with clear separation of concerns and now includes a powerful motion graphics system:

### Core Components

#### 1. **AnimatedTextView** (`AnimatedTextView.swift`)
- Main view component for displaying animated text
- Delegates animation logic to `TextAnimationController`
- Uses `TextRenderer` protocol for text rendering
- Configurable via `TextAnimationConfiguration`
- **NEW**: Supports scale, rotation, and keyframe-based animations
- **NEW**: CALayer integration for motion graphics workflows

#### 2. **TextAnimationController**
- Handles all animation timing and state management
- Uses CADisplayLink for smooth 60fps animations
- Communicates updates via delegate pattern
- **NEW**: Progress-based animation control
- **NEW**: Keyframe support with easing functions

#### 3. **TextRenderer Protocol**
- Abstract interface for text rendering
- Allows different text styles and effects
- Implementations: `DefaultTextRenderer`, `BoldTextRenderer`, `ColoredTextRenderer`

#### 4. **MotionGraphicsScene** (`MotionGraphicsScene.swift`) - **NEW**
- Orchestrates multiple animated text elements
- Keyframe-based animation system
- Scene-level timing and coordination
- Builder pattern for easy scene creation
- Support for complex multi-element sequences

### Key Improvements

#### **Motion Graphics Capabilities**
- **Keyframe Animation**: Precise control over animation timing and easing
- **Multi-Element Scenes**: Coordinate multiple text elements in complex sequences
- **CALayer Integration**: Direct integration with Core Animation for advanced workflows
- **Scene Management**: Complete scene lifecycle management with play/pause/stop
- **Progress Control**: Fine-grained control over animation progress

#### **Separation of Concerns**
- Animation logic separated from view logic
- Text rendering abstracted through protocols
- Configuration separated from implementation
- Scene management isolated from individual elements

#### **Extensibility**
- Easy to add new animation configurations
- Simple to create custom text renderers
- Factory pattern for creating different text view types
- Scene presets for common animation sequences
- Protocol-based design allows easy mocking and testing

#### **Maintainability**
- Clear, single-responsibility classes
- Well-defined interfaces and protocols
- Consistent naming conventions
- Comprehensive documentation

#### **Idiomatic Swift**
- Protocol-oriented design
- Value types for configuration
- Proper use of access control
- SwiftUI integration with ObservableObject

## Usage Examples

### Basic Animated Text
```swift
let textView = AnimatedTextView(
    text: "Hello World",
    fontSize: 24,
    position: CGPoint(x: 400, y: 200)
)
textView.play()
```

### Keyframe-Based Animation
```swift
let textView = AnimatedTextView(
    text: "Animated Text",
    fontSize: 28,
    position: CGPoint(x: 400, y: 200),
    configuration: .dramatic
)

// Set specific keyframes
textView.setKeyframe(at: 0.3, duration: 1.0)
textView.setKeyframe(at: 0.7, duration: 0.5)
```

### Motion Graphics Scene
```swift
let scene = MotionGraphicsSceneBuilder()
    .setConfiguration(SceneConfiguration(
        duration: 10.0,
        backgroundColor: .white,
        size: CGSize(width: 800, height: 600)
    ))
    .addSimpleElement(
        id: "title",
        text: "Main Title",
        fontSize: 32,
        position: CGPoint(x: 400, y: 200),
        startTime: 0,
        duration: 5.0
    )
    .addKeyframedElement(
        id: "subtitle",
        text: "Subtitle",
        fontSize: 20,
        position: CGPoint(x: 400, y: 250),
        keyframes: [
            Keyframe.easeIn(at: 0, progress: 0),
            Keyframe.easeOut(at: 2, progress: 1.0)
        ],
        startTime: 2.0,
        duration: 3.0
    )
    .build()

scene.play()
```

### Using Scene Presets
```swift
// Movie intro style
let movieScene = MotionGraphicsSceneBuilder.createMovieIntro().build()

// Product launch style
let productScene = MotionGraphicsSceneBuilder.createProductLaunch().build()

// Minimalist style
let minimalScene = MotionGraphicsSceneBuilder.createMinimalistIntro().build()
```

### Custom Animation Configuration
```swift
let config = TextAnimationConfiguration.custom(
    trackingRange: 0...30,
    opacityRange: 0...1,
    scaleRange: 0.8...1.2,
    rotationRange: -0.1...0.1
)

let textView = AnimatedTextView(
    text: "Custom Animation",
    fontSize: 28,
    position: CGPoint(x: 400, y: 200),
    configuration: config
)
```

### CALayer Integration
```swift
let textView = AnimatedTextView(text: "Layer Text", fontSize: 24, position: .zero)
let parentLayer = CALayer()
textView.addToLayer(parentLayer)

// Use in custom CALayer hierarchies
let sceneLayer = CALayer()
sceneLayer.addSublayer(parentLayer)
```

## Available Configurations

### Animation Configurations
- `.default` - Standard animation (10-20 tracking, 5s duration)
- `.fast` - Quick animation (5-15 tracking, 2s duration)
- `.slow` - Slow animation (15-30 tracking, 8s duration)
- `.dramatic` - Dramatic effect with scale and rotation
- `.bounce` - Bounce effect with scale animation
- `.spin` - Rotation animation (0 to 2π)

### Text Renderers
- `DefaultTextRenderer` - Standard system font
- `BoldTextRenderer` - Bold system font
- `ColoredTextRenderer` - Custom color text

### Scene Presets
- `createMovieIntro()` - Hollywood-style movie intro
- `createProductLaunch()` - Product announcement style
- `createMinimalistIntro()` - Clean, minimal design

### Keyframe Easing
- `Keyframe.easeIn()` - Ease-in timing function
- `Keyframe.easeOut()` - Ease-out timing function
- `Keyframe.easeInOut()` - Ease-in-out timing function
- `Keyframe.linear()` - Linear timing function

## Motion Graphics Features

### **Keyframe System**
- Precise timing control with CFTimeInterval
- Progress-based animation (0.0 to 1.0)
- Easing functions for smooth transitions
- Support for complex animation curves

### **Scene Management**
- Multi-element coordination
- Scene-level timing and duration
- Play/pause/stop controls
- Progress scrubbing support

### **CALayer Integration**
- Direct CALayer manipulation
- Integration with existing Core Animation workflows
- Support for complex layer hierarchies
- Keyframe animation compatibility

### **Builder Pattern**
- Fluent API for scene creation
- Chainable configuration methods
- Preset scenes for common use cases
- Easy customization and extension

## Visual Effect Preservation

The refactoring maintains the original visual effect:
- Kerning animation expands from center anchor point
- Smooth opacity fade-in
- Synchronized timing between text elements
- Exact same visual appearance as the original

## Future Extensibility

The architecture supports easy addition of:
- **Audio Synchronization**: Sync animations with audio tracks
- **Video Integration**: Combine with video playback
- **3D Transformations**: Add depth and perspective
- **Particle Systems**: Integrate with particle effects
- **Advanced Easing**: Custom easing functions and curves
- **Export Capabilities**: Export animations as video files
- **Real-time Collaboration**: Multi-user editing capabilities

## Testing

The protocol-based design makes testing straightforward:
- Mock `TextRenderer` for unit tests
- Mock `AnimationControllerDelegate` for animation tests
- Mock `MotionGraphicsSceneDelegate` for scene tests
- Isolated components can be tested independently
- Configuration objects are value types and easily testable

## Performance Considerations

- **CADisplayLink**: 60fps smooth animations
- **CALayer**: Hardware-accelerated rendering
- **Memory Management**: Proper cleanup and disposal
- **Efficient Updates**: Only update when necessary
- **Background Threading**: Non-blocking animation updates 