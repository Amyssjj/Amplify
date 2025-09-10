# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Amplify is an iOS native communication coaching app with a separate React design system for prototyping:

1. **iOS Native App**: SwiftUI-based production iOS app with comprehensive TDD implementation
2. **React Design System**: UI/UX prototype demonstrating intended visual design and interactions (NOT part of the main app)

The iOS app follows a "Capture, Cook, Comprehend" workflow where users record spontaneous stories based on photos, receive AI-enhanced versions, and get actionable feedback.

## Development Commands

### iOS Native Development

**Primary Development Environment**: Xcode with iOS Simulator
```bash
# Open the iOS project
cd /Users/jing/Documents/Amplify_App/Amplify/Amplify/Amplify

# Run all tests
xcodebuild test -scheme Amplify -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6'

# Run specific test class
xcodebuild test -scheme Amplify -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' -only-testing:AmplifyTests/AIInsightTests

# Build for testing
xcodebuild build-for-testing -scheme Amplify -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6'
```

**Testing Commands**:
```bash
# Run unit tests only
xcodebuild test -scheme Amplify -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' -only-testing:AmplifyTests

# Run UI tests only
xcodebuild test -scheme Amplify -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' -only-testing:AmplifyUITests

# Generate test coverage report (Note: xcrun xccov may have issues with result bundles)
xcodebuild test -scheme Amplify -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' -enableCodeCoverage YES

# Alternative: Get actual coverage by counting test methods vs app methods
# Test methods: find AmplifyTests -name "*.swift" -exec grep -l "func test" {} \; | xargs grep -c "func test" | paste -sd+ - | bc
# App methods: find Amplify -name "*.swift" -not -path "*/AmplifyTests/*" -exec grep -c "func " {} \; | paste -sd+ - | bc  
# Coverage = (test methods / app methods) * 100%

# Get test pass rate from xcodebuild test output or count passed/failed tests manually
```

### React Design System (UI Prototype Only)

**Location**: `Amplify/doc/Design_System/`
**Purpose**: Visual design reference and UI/UX validation - NOT part of the main app
```bash
# Navigate to design system prototype
cd Amplify/doc/Design_System

# Install dependencies
npm install

# Start prototype server for design reference
npm run dev

# Build prototype (for design review only)
npm run build
```

## Architecture Overview

### iOS Native Architecture

The iOS app follows a **screen-based SwiftUI architecture** with centralized state management:

**Core Components**:
- `App.swift` - Main app entry point with Google Sign-In configuration
- `AppStateManager.swift` - Central state coordinator using `@ObservableObject`
- Screen-based Views: `HomeView`, `RecordingView`, `ProcessingView`, `ResultsView`
- Service Layer: Domain-specific services with protocol-based interfaces

**State Management Pattern**:
```swift
@StateObject private var appState = AppStateManager()
@ObservedObject var photoService: PhotoLibraryService
@Published var currentScreen: AppScreen = .home
```

**Navigation Flow**:
```
Home (Photo + Record Button)
  → Recording (Live Transcription)
    → Processing (AI Enhancement)
      → Results (Audio Playback + Insights)
```

### Service Architecture

**Service Layer Design**:
- `PhotoLibraryService` - PhotoKit integration with Favorites album access
- `AudioRecordingService` - AVFoundation recording with real-time monitoring
- `SpeechRecognitionService` - Live speech recognition with confidence tracking
- `AIEnhancementService` - OpenAI integration for story enhancement
- `NetworkManager` - API client with authentication and error handling

**Dependency Injection Pattern**:
```swift
class AppStateManager: ObservableObject {
    private(set) var enhancementService: EnhancementService
    private(set) var audioPlayerService: AudioPlayerService
}
```

### React Design System (Prototype Architecture)

**Purpose**: Visual design reference showing intended UI/UX - NOT implemented in the iOS app

**Component Organization** (React/TypeScript prototype):
```
/components/
├── screens/          # Visual mockups of app states
├── modals/           # Design demos for overlays
├── shared/           # Reusable UI component demos
├── media/            # Audio/video interface mockups
├── results/          # Results screen design demos
└── ui/               # ShadCN component library
```

**Styling System** (for design reference):
- Tailwind v4 with design tokens
- iOS 16-inspired glassmorphism utilities
- Motion/React for animation prototypes
- Typography specifications (Work Sans primary, Inter fallback)

## Development Patterns

### iOS Development Patterns

**SwiftUI Patterns**:
```swift
// State management
@StateObject private var viewModel = ViewModel()
@Published var state: ViewState = .idle

// Navigation
@Published var currentScreen: AppScreen = .home
```

**Service Protocol Pattern**:
```swift
protocol PhotoLibraryServiceProtocol {
    func requestPermission() async -> PhotoLibraryPermissionStatus
    func getRandomPhoto() async throws -> PhotoData
}
```

**Error Handling Pattern**:
```swift
enum AppError: Error {
    case photoLibraryAccessDenied
    case recordingFailed
    case enhancementFailed
}
```

### Testing Patterns

**TDD Implementation**:
- 100% test coverage with 45+ unit test methods
- XCTest framework with comprehensive mocking
- Test-first development approach

**Testing Structure**:
```
AmplifyTests/
├── Model Tests (Recording, AIInsight, AppStateManager)
├── Service Tests (All service layer components)
├── Integration Tests (Cross-service workflows)
└── Mock Infrastructure (Reliable test doubles)
```

**Mock Pattern**:
```swift
class MockPhotoLibraryService: PhotoLibraryServiceProtocol {
    var shouldGrantPermission = true
    var mockPhotos: [PhotoData] = []
}
```

### API Integration Patterns

**Network Layer**:
```swift
struct APIConfiguration {
    static let baseURL = URL(string: "https://api.amplify.app")!
    static let version = "v1"
}
```

**Authentication Flow**:
```swift
// Google Sign-In integration
func signInWithGoogle(_ idToken: String) async throws -> User
```

**Enhancement Service Pattern**:
```swift
func enhanceRecording(_ recording: Recording, photoData: Data) async throws -> Recording
```

## Key Implementation Details

### Permissions Handling

The app requires three iOS permissions managed through AppStateManager:
- Photo Library access (for story prompts)
- Microphone access (for recording)
- Speech Recognition (for live transcription)

**Permission States**:
```swift
@Published var photoPermissionStatus: PhotoLibraryPermissionStatus = .notDetermined
@Published var microphonePermissionStatus: MicrophonePermissionStatus = .undetermined
@Published var speechPermissionStatus: SpeechRecognitionPermissionStatus = .notDetermined
```

### Animation System

**iOS Native Animations**:
- SwiftUI native animation system with spring physics
- Custom transition modifiers for screen changes
- Haptic feedback choreography (light/medium haptic timing)

**Design System Animations** (prototype only):
- Motion/React animation demos for design reference
- iOS 16 liquid spring animation prototypes
- Visual examples of intended animation behavior

### API Configuration

**Development vs Production**:
```swift
struct APIConfiguration {
    #if DEBUG
    static let baseURL = URL(string: "http://localhost:3000")!
    static let enableDebugLogging = true
    #else
    static let baseURL = URL(string: "https://api.amplify.app")!
    static let enableDebugLogging = false
    #endif
}
```

### Data Models

**Core Models**:
```swift
// Recording model with audio data and metadata
class Recording: ObservableObject, Identifiable
// AI insights with confidence scoring
struct AIInsight: Identifiable, Codable
// Photo data wrapper for UIImage
struct PhotoData: Identifiable
```

## File Structure Guide

### iOS Native Structure
```
Amplify/Amplify/Amplify/
├── App.swift                    # App entry point
├── Views/                       # SwiftUI screen views
├── Models/                      # Core data models + API models
├── Services/                    # Business logic services
├── Supporting Files/            # Utilities and extensions
└── Configuration/               # API and app configuration
```

### Generated API Code
```
wip/generated/AmplifyAPI/        # Auto-generated from OpenAPI spec
├── Classes/OpenAPIs/Models/     # API response models
├── Classes/OpenAPIs/APIs/       # API client interfaces
└── Tests/                       # Generated model validation tests
```

### React Design System (Prototype Only)
```
Amplify/doc/Design_System/
├── src/components/              # UI/UX design demos (NOT app code)
├── src/styles/                  # Design tokens and style references
└── vite.config.ts              # Prototype build configuration
```

## Common Tasks

### Adding New Screens
1. Create SwiftUI view in `Views/` directory
2. Add new case to `AppScreen` enum in `AppStateManager.swift`
3. Update navigation logic in AppStateManager
4. Add corresponding tests in `AmplifyTests/`

### Adding New Services
1. Create protocol in `Services/` directory
2. Implement service class conforming to protocol
3. Add to AppStateManager initialization if needed
4. Create comprehensive test suite with mocks
5. Update dependency injection as needed

### API Integration
1. Update OpenAPI specification
2. Regenerate API client models using code generation tools
3. Update service implementations to use new models
4. Add integration tests for new endpoints
5. Update error handling for new API responses

### Testing New Features
1. Write tests first (TDD approach)
2. Create mocks for external dependencies
3. Test happy path and error conditions
4. Add UI tests for user-facing features
5. Verify test coverage remains at 100%

## Production Considerations

The iOS app is production-ready with:
- Comprehensive error handling with user-friendly messages
- Offline support with graceful degradation
- Full accessibility support (VoiceOver, Dynamic Type)
- Performance optimizations (lazy loading, memory management)
- Proper iOS permission handling with clear rationale

The Design System serves as a UI/UX validation tool and should not be deployed independently.
