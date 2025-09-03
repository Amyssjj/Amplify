//
//  ProcessingView.swift
//  Amplify
//
//  AI processing animation screen - "Cook" phase
//

import SwiftUI

struct ProcessingView: View {
    @ObservedObject var appState: AppStateManager
    @ObservedObject var aiService: AIEnhancementService
    
    @State private var animationPhase = 0
    @State private var floatingOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var processingStarted = false
    
    private let animationMessages = [
        "Analyzing your story structure...",
        "Enhancing vocabulary choices...",
        "Identifying storytelling opportunities...",
        "Generating personalized insights...",
        "Polishing your narrative..."
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // Main processing animation
                processingAnimationSection
                
                // Progress and message
                progressSection
                
                Spacer()
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startProcessing()
        }
    }
    
    // MARK: - Processing Animation
    
    private var processingAnimationSection: some View {
        VStack(spacing: 40) {
            // Title
            Text("Cooking Your Story")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .accessibilityIdentifier("CookingYourStory")
            
            // Animated cooking pot/brain icon
            ZStack {
                // Outer ring
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(rotationAngle))
                
                // Inner elements
                ZStack {
                    // Brain/chef hat icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                        .offset(y: floatingOffset)
                    
                    // Sparkles
                    ForEach(0..<6) { index in
                        Image(systemName: "sparkle")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                            .offset(
                                x: cos(Double(index) * 60 * .pi / 180) * 60,
                                y: sin(Double(index) * 60 * .pi / 180) * 60
                            )
                            .opacity(animationPhase == index % 3 ? 1.0 : 0.3)
                            .scaleEffect(animationPhase == index % 3 ? 1.2 : 0.8)
                    }
                }
            }
            .accessibilityIdentifier("ProcessingAnimation")
            .accessibilityLabel("AI processing animation")
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 24) {
            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: aiService.processingProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 2)
                    .frame(height: 8)
                    .padding(.horizontal, 60)
                
                Text("\(Int(aiService.processingProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Current processing message
            Text(currentMessage)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .frame(height: 50)
                .padding(.horizontal, 40)
                .animation(.easeInOut(duration: 0.5), value: animationPhase)
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentMessage: String {
        guard animationPhase < animationMessages.count else {
            return "Finalizing your enhanced story..."
        }
        return animationMessages[animationPhase]
    }
    
    // MARK: - Actions
    
    private func startProcessing() {
        guard !processingStarted else { return }
        processingStarted = true
        
        // Start animations
        startAnimations()
        
        // Start AI processing
        Task {
            await processStoryWithAI()
        }
    }
    
    private func startAnimations() {
        // Floating animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            floatingOffset = -10
        }
        
        // Rotation animation
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // Phase animation (message cycling)
        let timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.5)) {
                    animationPhase = (animationPhase + 1) % animationMessages.count
                }
            }
        }
        
        // Stop timer when processing is complete - check periodically
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { checkTimer in
            if aiService.processingProgress >= 1.0 {
                timer.invalidate()
                checkTimer.invalidate()
            }
        }
    }
    
    private func processStoryWithAI() async {
        guard let recording = appState.currentRecording else {
            await MainActor.run {
                appState.handleError(.aiProcessingFailed)
            }
            return
        }
        
        // Simulate processing progress
        await simulateProgress()
        
        // Enhance the story
        let result = await aiService.enhanceStory(
            transcript: recording.transcript,
            duration: recording.duration
        )
        
        await MainActor.run {
            switch result {
            case .success(let enhancement):
                // Update recording with enhanced content
                recording.setEnhancedTranscript(enhancement.enhancedTranscript)
                recording.setWordHighlights(enhancement.wordHighlights)
                
                // Transition to results
                Task {
                    await appState.transitionToResults(with: enhancement.insights)
                }
                
            case .failure(_):
                switch error {
                case .networkError:
                    appState.handleError(.networkError)
                case .apiKeyMissing, .authenticationFailed:
                    appState.handleError(.aiProcessingFailed)
                case .rateLimitExceeded:
                    appState.handleError(.aiProcessingFailed)
                default:
                    appState.handleError(.aiProcessingFailed)
                }
            }
        }
    }
    
    private func simulateProgress() async {
        let totalSteps = 20
        for step in 1...totalSteps {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            await MainActor.run {
                appState.setProcessing(true, progress: Double(step) / Double(totalSteps))
            }
        }
    }
}

#if DEBUG
struct ProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessingView(
            appState: AppStateManager(),
            aiService: AIEnhancementService()
        )
        .previewDevice("iPhone 15 Pro")
    }
}
#endif