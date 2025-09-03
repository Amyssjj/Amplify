# Amplify - Hierarchical Architecture

## 📱 Application Overview
Amplify is a mobile AI communication coach app that helps users practice storytelling through a "Capture, Cook, Comprehend" workflow.

## 🏗 Architecture Principles

### 🔄 User Flow Hierarchy
The application follows a clear linear user journey:
```
Home → Recording → Processing → Results
                        ↓
                   Expanded Views (Modals)
```

### 📁 Component Organization
Components are organized by **feature and responsibility** rather than type:

```
/components/
├── index.ts                    # Centralized exports
├── screens/                    # Main application states
│   ├── HomeScreen.tsx         # Entry point with photo and record button
│   ├── RecordingScreen.tsx    # Live recording with transcription
│   ├── ProcessingScreen.tsx   # AI processing animation
│   └── ResultsScreen.tsx      # Story playback and insights
├── modals/                    # Full-screen overlays
│   ├── ExpandedTranscription.tsx  # Full-screen transcript view
│   └── ExpandedInsights.tsx      # Full-screen insights view
├── shared/                    # Reusable UI components
│   ├── PhotoCard.tsx          # Interactive photo display
│   └── RecordButton.tsx       # Recording control button
├── media/                     # Audio/video features
│   └── MiniMediaPlayer.tsx    # Compact audio player
├── results/                   # Results-specific features
│   └── SwipeableCards.tsx     # Transcript/insights cards
├── figma/                     # System components
│   └── ImageWithFallback.tsx  # Protected system component
└── ui/                        # ShadCN component library
    └── [shadcn components]
```

## 🎯 Design Patterns

### 🧩 Component Composition
- **Screen Components**: Handle application state and navigation
- **Feature Components**: Encapsulate specific functionality
- **Shared Components**: Reusable across multiple screens
- **Modal Components**: Full-screen overlays with consistent patterns

### 📊 State Management
- **App Level**: Navigation state, current recording, playback state
- **Screen Level**: Local UI state and user interactions
- **Component Level**: Internal component state only

### 🎨 Styling Architecture
- **Design System**: Consistent tokens via Tailwind v4 and globals.css
- **Glassmorphism**: iOS 16 liquid glass utilities (`glass-card`, `glass-button`)
- **Motion**: Motion/React for fluid iOS-style animations
- **Typography**: Work Sans primary, Inter fallback, consistent sizing

## 🚀 Performance Optimizations

### ⚡ React Optimizations
- **Memoization**: `memo()` for expensive components
- **Callback Memoization**: `useCallback()` for stable references
- **Value Memoization**: `useMemo()` for expensive calculations
- **Conditional Rendering**: Smart component mounting/unmounting

### 🎭 Animation Performance
- **Transform-based animations**: GPU-accelerated transformations
- **Reduced re-renders**: Isolated animation components
- **Spring physics**: Natural motion with Motion/React
- **Staggered animations**: Smooth progressive reveals

## 📱 User Experience Architecture

### 🌊 Interaction Flow
1. **Home**: Photo inspiration + record button
2. **Recording**: Live transcription + 30s timer
3. **Processing**: AI analysis with engaging animation
4. **Results**: Audio playback + swipeable insights/transcript

### 🎪 Modal Pattern
- **Consistent Structure**: Header + content + close button
- **iOS Liquid Springs**: Smooth scale + opacity transitions
- **Backdrop Blur**: Contextual background blurring
- **Gesture Support**: Tap-outside-to-close

### 📊 Data Flow
```
User Input → Recording → AI Processing → Insights Generation → Results Display
```

## 🛡 Code Quality Standards

### 📝 TypeScript
- **Strict Types**: Full TypeScript coverage
- **Interface Definitions**: Clear component props
- **Type Safety**: No `any` types in production code

### 🧹 Clean Code
- **Single Responsibility**: Each component has one clear purpose
- **Descriptive Naming**: Self-documenting function and variable names
- **Small Functions**: Focused, testable function units
- **Consistent Formatting**: Automated with Prettier

### ♻️ Maintainability
- **Feature Organization**: Related components grouped together
- **Clear Dependencies**: Explicit imports and exports
- **Documentation**: Inline comments for complex logic
- **Version Control**: Meaningful commit messages

## 🎨 Design System Integration

### 🎭 Animation Philosophy
- **Liquid Motion**: iOS 16-inspired fluid animations
- **Purposeful Timing**: Animations enhance UX, don't distract
- **Performance First**: GPU-accelerated transformations
- **Progressive Enhancement**: Graceful fallbacks

### 🖼 Visual Hierarchy
- **Color Palette**: Vibrant highlights (`#68D2E8`, `#FDDE55`, `#E6FF94`, `#B4E380`, `#B4EBE6`)
- **Typography Scale**: Consistent sizing without explicit Tailwind classes
- **Spacing System**: Harmonious padding and margin relationships
- **Glass Effects**: Consistent glassmorphism implementation

## 🔧 Technical Decisions

### 📦 Library Choices
- **Motion/React**: Modern animation library (formerly Framer Motion)
- **Tailwind v4**: Utility-first CSS with design tokens
- **Lucide React**: Consistent icon library
- **ShadCN/UI**: High-quality component primitives

### 🏗 Architecture Benefits
1. **Scalability**: Easy to add new screens or features
2. **Maintainability**: Clear separation of concerns
3. **Reusability**: Shared components across screens
4. **Performance**: Optimized rendering and animations
5. **Developer Experience**: Clear file organization and imports

## 📈 Future Extensibility

### 🔮 Planned Enhancements
- **Authentication**: User accounts and story history
- **Social Features**: Story sharing and community feedback
- **Advanced AI**: More sophisticated storytelling analysis
- **Offline Support**: Local storage and sync capabilities

### 🧩 Extension Points
- **New Screen Types**: Easy to add to `/screens/` directory
- **Additional Modals**: Consistent pattern in `/modals/`
- **Feature Modules**: Logical grouping in feature directories
- **UI Components**: Shared components in `/shared/`

This architecture ensures the Amplify app remains maintainable, performant, and aligned with iOS design principles while providing a clear path for future development.