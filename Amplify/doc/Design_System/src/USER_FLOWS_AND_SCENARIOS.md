# Amplify - User Flows & Scenarios Documentation

## App Overview
**Amplify** is a mobile AI communication coach app that helps people practice and improve their storytelling through a "Capture, Cook, Comprehend" design philosophy. Users record stories about random photos from their library, then receive AI-powered feedback and insights to become more compelling communicators.

---

## Core Design Philosophy: "Capture, Cook, Comprehend"

### 🎯 **Capture**
Users record authentic, spontaneous stories triggered by random photo prompts to practice natural storytelling.

### 👨‍🍳 **Cook** 
AI processes the recording, analyzing speech patterns, story structure, and communication techniques to generate insights.

### 🧠 **Comprehend**
Users review their performance through interactive transcripts, AI insights, and actionable feedback to improve their communication skills.

---

## Primary User Flow

### **Main Success Path: Complete Storytelling Session**

#### **State 1: Home Screen (`'home'`)**
```
User lands on home screen
├── Sees current random photo in PhotoCard component  (5 random photoes are from users iphone photo library Favoraites)
├── Views large "Record" button (RecordButton component)
├── Can swipe photocard to view next photo
└── Taps "Record" to begin session
```

**User Actions:**
- **Tap Record Button** → Transitions to Recording Screen
- **Swipe photocard** → Get new random photo from SAMPLE_PHOTOS array

**App State Changes:**
- `currentState: 'home' → 'recording'`
- `currentPhoto` may change with swipe action

#### **State 2: Recording Screen (`'recording'`)**
```
User enters full-screen recording mode
├── Sees the selected photo prominently displayed
├── Views recording interface with live transcription
├── Taps record button to stop recording
├── Sees real-time speech-to-text feedback
└── Completes recording and confirms
```

**User Actions:**
- **Start Recording** → Begin audio capture with live transcription
- **View Live Transcription** → See real-time speech-to-text in LiveTranscription component
- **Stop Recording** → End audio capture
- **Confirm Recording** → Proceed to processing
- **Back Navigation** → Return to home (cancels recording)

**App State Changes:**
- Recording starts/stops based on user interaction
- Live transcription updates in real-time
- `onFinishRecording(transcript, duration)` triggers processing

#### **State 3: Processing Screen (`'processing'`)**
```
User waits for AI analysis (3-second simulated delay)
├── Sees "Cooking now..." animation
├── Views progress indicators
├── Experiences anticipation-building UI
└── Automatically transitions to results
```

**User Experience:**
- **Visual Feedback** → Animated cooking/processing metaphor
- **Wait Time** → Until the backend AI model provide responses
- **Automatic Transition** → No user action required

**App State Changes:**
- `currentState: 'recording' → 'processing' → 'results'`
- Recording data processed into structured insights
- Mock AI generates story analysis and improvement suggestions

#### **State 4: Results Screen (`'results'`)**
```
User reviews their performance
├── Sees MiniMediaPlayer with playback controls
├── Views SwipeableCards with Transcript/Insights toggle
├── Watches real-time word highlighting during playback
├── Swipes between Transcription and Insights cards
├── Taps cards to expand to full-screen modals
└── Can return to home for new session
```

**User Actions:**
- **Play/Pause Audio** → Control playback via MiniMediaPlayer
- **Seek Timeline** → Jump to specific moments in recording
- **Swipe Cards** → Toggle between Transcription and Sharp Insights
- **Tap Page Dots** → Navigate between card views
- **Expand Transcript** → View ExpandedTranscription modal with improved text
- **Expand Insights** → View ExpandedInsights modal with detailed analysis
- **Back to Home** → Start new storytelling session

**App Features:**
- **Real-time Highlighting** → Words highlight in sync with audio playback
- **AI-Enhanced Transcript** → Shows original + improved word suggestions
- **Comprehensive Insights** → STAR Method, Hero's Journey, vocabulary analysis
- **Performance Metrics** → Pacing, emotional resonance, engagement scores

---

## Secondary User Flows

### **Flow 2A: Quick Photo Browsing**
```
User wants different inspiration
├── From Home Screen
├── Swipe Photos
├── Finds inspiring Photos
└── Proceeds with recording
```

### **Flow 2B: Recording Interruption & Recovery**
```
User starts recording but gets interrupted
├── Begins recording session
├── Phone call/notification interrupts
├── Returns to app (may reset to home)
├── Needs to restart recording process
└── Completes session on second attempt
```

### **Flow 2C: Detailed Analysis Deep Dive**
```
User wants comprehensive feedback review
├── Completes main recording flow
├── Plays audio multiple times with different focus
├── Expands transcript to study word improvements
├── Expands insights to review all 8 analysis frameworks
├── Takes notes on suggested improvements
└── Plans practice for next session
```

### **Flow 2D: Quick Practice Sessions**
```
User does rapid-fire practice rounds
├── Completes full session quickly
├── Immediately returns to home
├── Gets new photo and records again
├── Builds fluency through repetition
└── Tracks improvement over multiple sessions
```

---

## User Scenarios by Context

### **Scenario 1: New User First Experience**
**Context:** First-time app user, unfamiliar with storytelling practice

**Journey:**
1. **Discovery** → Opens app, ask permission for photo library and microphone access.
2. **Curiosity** → Wonders what to say about the mountain landscape image
3. **Hesitation** → Unsure about recording quality, feels self-conscious
4. **First Attempt** → Records 30-second basic description: "This is a mountain..."
5. **Surprise** → Sees AI processing animation, feels engaged
6. **Revelation** → Discovers transcript shows "breathtaking" instead of "nice"
7. **Learning** → Reviews insights about STAR method and vivid imagery
8. **Motivation** → Excited to try again with new techniques


---

## Edge Cases & Error Scenarios

### **Edge Case 1: Recording Permission Denied**
**Flow:**
```
User taps record → System denies microphone access or photo access → 
App shows permission request → User grants → Recording begins
```

### **Edge Case 2: Short Recording (Under 10 seconds)**
**Flow:**
```
User records very brief statement → Processing still occurs → 
Limited insights generated → App encourages longer recordings
```

### **Edge Case 3: Background App Interruption**
**Flow:**
```
User recording → Phone call interrupts → App backgrounds → 
Returns to app → Recording lost → Restart from home screen
```

### **Edge Case 4: No Speech Detected**
**Flow:**
```
User records silence/background noise → Transcription empty → 
Processing generates generic encouragement → 
Suggests speaking more clearly
```

### **Edge Case 5: Network Issues During Processing**
**Flow:**
```
Recording completes → Processing begins → Network fails → 
Fallback to cached insights → Limited analysis available
```

---

## Technical User Flow Implementation

### **State Management Flow**
```typescript
// App.tsx state transitions
currentState: 'home' 
├── handleStartRecording() → 'recording'
├── handleFinishRecording() → 'processing' 
├── setTimeout(3000) → 'results'
└── handleBackToHome() → 'home'

// Data flow
currentPhoto: string (from SAMPLE_PHOTOS)
currentRecording: Recording | null
currentPlayTime: number (0-duration)
isPlaying: boolean
```

### **Component Interaction Flow**
```
HomeScreen → RecordingScreen → ProcessingScreen → ResultsScreen
     ↑                                                    ↓
     ←←←←←←←←←←←←← handleBackToHome() ←←←←←←←←←←←←←←←←←
     
ResultsScreen ↔ ExpandedTranscription (modal overlay)
              ↔ ExpandedInsights (modal overlay)
```

### **Data Processing Flow**
```
Raw Recording Input:
├── transcript: string (speech-to-text)
├── duration: number (seconds)
└── photoUrl: string (current image)

AI Processing (Simulated):
├── getPolishedTranscript() → word improvements
├── generateInsights() → 8 analysis frameworks
└── createRecording() → structured data object

Output Features:
├── Real-time word highlighting during playback
├── Enhanced transcript with vocabulary improvements
├── Multiple storytelling framework analyses
└── Actionable improvement suggestions
```

---

## Success Metrics & User Goals

### **Primary Success Indicators**
- **Session Completion Rate** → Users complete full Capture→Cook→Comprehend cycle
- **Engagement Time** → Users spend time reviewing insights and transcript
- **Return Usage** → Users initiate multiple sessions per app visit
- **Modal Interaction** → Users expand transcript/insights for deeper analysis

### **User Value Delivered**
- **Immediate Feedback** → Real-time transcription during recording
- **Skill Development** → Concrete suggestions for improvement
- **Confidence Building** → Positive reinforcement with growth areas
- **Practical Application** → Frameworks usable in real communication scenarios

### **Long-term User Outcomes**
- **Communication Confidence** → Reduced anxiety about public speaking
- **Storytelling Skills** → Better narrative structure and engagement
- **Vocabulary Enhancement** → Expanded descriptive language use
- **Professional Growth** → Improved presentation and pitching abilities

---

## Design Principles Reflected in User Flow

### **iOS 16 Liquid Glass Design**
- **Visual Hierarchy** → Clear progression through app states
- **Smooth Transitions** → Seamless navigation between screens
- **Glassmorphism Effects** → Enhanced depth and premium feel
- **Intuitive Interactions** → Natural swipe and tap gestures

### **"Capture, Cook, Comprehend" Philosophy**
- **Capture** → Simple, stress-free recording experience
- **Cook** → Anticipation-building processing animation
- **Comprehend** → Rich, actionable insights presentation

### **Performance Optimizations**
- **Memoized Components** → Prevents unnecessary re-renders during playback
- **Efficient State Management** → Clean separation of concerns
- **Smooth Animations** → Motion components optimized for mobile performance

This comprehensive user flow documentation serves as a blueprint for understanding how users interact with Amplify across different contexts, skill levels, and goals, ensuring the app delivers meaningful value in developing communication skills.