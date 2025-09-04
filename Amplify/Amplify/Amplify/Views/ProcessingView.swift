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
    @State private var rotationAngle: Double = 0
    @State private var processingStarted = false
    
    // Concentric rings animation states
    @State private var outerRingScale: CGFloat = 1.0
    @State private var outerRingOpacity: Double = 0.4
    @State private var innerRingScale: CGFloat = 0.9
    @State private var coreScale: CGFloat = 1.0
    @State private var coreShadowRadius: CGFloat = 4
    @State private var orbitalScales: [CGFloat] = [0.5, 0.5, 0.5]
    
    // Text animation states
    @State private var subtitleOpacity: Double = 0.7
    @State private var descriptionOpacity: Double = 0.0
    
    // Progress dots animation states
    @State private var dotScales: [CGFloat] = [1.0, 1.0, 1.0]
    @State private var dotOpacities: [Double] = [0.4, 0.4, 0.4]
    
    // Floating particles
    @State private var particlePositions: [CGPoint] = []
    @State private var particleOffsets: [CGFloat] = []
    @State private var particleScales: [CGFloat] = []
    
    private let animationMessages = [
        "Analyzing your story structure...",
        "Enhancing vocabulary choices...",
        "Identifying storytelling opportunities...",
        "Generating personalized insights...",
        "Polishing your narrative..."
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient - matching original design
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.05),
                        Color.white,
                        Color.purple.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Floating particles background
                floatingParticlesBackground(geometry: geometry)
                
                // Main content
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Main processing animation
                    processingAnimationSection
                    
                    // Enhanced text content
                    enhancedTextContent
                    
                    // Progress dots
                    progressDots
                    
                    Spacer()
                    Spacer()
                }
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
            // Title - matching original design
            Text("Cooking now...")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .accessibilityIdentifier("CookingNow")
            
            // Concentric rings animation system - matching original design
            ZStack {
                // Outer ring - scales and changes border color
                Circle()
                    .stroke(
                        Color.blue.opacity(outerRingOpacity),
                        lineWidth: 2
                    )
                    .frame(width: 128, height: 128)
                    .scaleEffect(outerRingScale)
                    .rotationEffect(.degrees(rotationAngle))
                
                // Inner ring - counter-rotates and scales
                Circle()
                    .stroke(
                        Color.purple.opacity(0.6),
                        lineWidth: 2
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(innerRingScale)
                    .rotationEffect(.degrees(-rotationAngle * 0.75))
                
                // Core - pulsing gradient center
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .scaleEffect(coreScale)
                    .shadow(color: .blue.opacity(0.5), radius: coreShadowRadius, x: 0, y: 0)
                
                // Orbital elements
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 12, height: 12)
                        .offset(x: 80)
                        .rotationEffect(.degrees(rotationAngle * Double(1 + index) + Double(index * 120)))
                        .scaleEffect(orbitalScales[index])
                }
            }
            .accessibilityIdentifier("ProcessingAnimation")
            .accessibilityLabel("AI processing animation")
        }
    }
    
    // MARK: - Enhanced Text Content
    
    private var enhancedTextContent: some View {
        VStack(spacing: 16) {
            // Subtitle
            Text("Transforming your story")
                .font(.title2)
                .foregroundColor(.gray)
                .opacity(subtitleOpacity)
            
            // Description
            Text("Our AI is analyzing your words and adding magic ✨")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(descriptionOpacity)
        }
        .padding(.top, 32)
    }
    
    // MARK: - Progress Dots
    
    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotScales[index])
                    .opacity(dotOpacities[index])
            }
        }
        .padding(.top, 32)
    }
    
    // MARK: - Floating Particles
    
    private func floatingParticlesBackground(geometry: GeometryProxy) -> some View {
        ZStack {
            ForEach(0..<20) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 8, height: 8)
                    .position(
                        x: particlePositions[index].x * geometry.size.width,
                        y: particlePositions[index].y * geometry.size.height
                    )
                    .offset(y: particleOffsets[index])
                    .opacity(0.6)
                    .scaleEffect(particleScales[index])
            }
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
        // Initialize particle positions
        initializeParticles()
        
        // Outer ring animations - spring-based scaling and opacity
        withAnimation(.spring(response: 2.0, dampingFraction: 0.6).repeatForever(autoreverses: true)) {
            outerRingScale = 1.1
            outerRingOpacity = 0.6
        }
        
        // Inner ring scaling animation
        withAnimation(.spring(response: 3.0, dampingFraction: 0.6).repeatForever(autoreverses: true)) {
            innerRingScale = 1.1
        }
        
        // Core pulsing animation
        withAnimation(.spring(response: 2.0, dampingFraction: 0.6).repeatForever(autoreverses: true)) {
            coreScale = 1.3
            coreShadowRadius = 8
        }
        
        // Rotation animation - linear for smooth spinning
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // Orbital elements scaling
        for index in 0..<3 {
            withAnimation(
                .spring(response: 2.0, dampingFraction: 0.6)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.5)
            ) {
                orbitalScales[index] = 1.0
            }
        }
        
        // Text animations
        withAnimation(.spring(response: 2.0, dampingFraction: 0.8).repeatForever(autoreverses: true)) {
            subtitleOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0)) {
            descriptionOpacity = 1.0
        }
        
        // Progress dots animation
        for index in 0..<3 {
            withAnimation(
                .spring(response: 1.5, dampingFraction: 0.6)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.3)
            ) {
                dotScales[index] = 1.5
                dotOpacities[index] = 1.0
            }
        }
        
        // Floating particles animation
        animateParticles()
    }
    
    private func initializeParticles() {
        particlePositions = (0..<20).map { _ in
            CGPoint(
                x: Double.random(in: 0...1),
                y: Double.random(in: 0...1)
            )
        }
        particleOffsets = Array(repeating: 0, count: 20)
        particleScales = Array(repeating: 0.5, count: 20)
    }
    
    private func animateParticles() {
        for index in 0..<20 {
            let randomDelay = Double.random(in: 0...2)
            let randomDuration = Double.random(in: 3...5)
            
            withAnimation(
                .spring(response: randomDuration, dampingFraction: 0.6)
                .repeatForever(autoreverses: true)
                .delay(randomDelay)
            ) {
                particleOffsets[index] = CGFloat.random(in: -20...(-40))
                particleScales[index] = CGFloat.random(in: 0.5...1.0)
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
                
            case .failure(let error):
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