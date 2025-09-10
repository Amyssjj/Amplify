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

    @State private var showingSignInSheet = false

    @State private var animationPhase = 0
    @State private var rotationAngle: Double = 0
    @State private var processingStarted = false

    // Concentric rings animation states
    @State private var outerRingScale: CGFloat = 1.0
    @State private var outerRingOpacity: Double = 0.4
    @State private var innerRingScale: CGFloat = 0.9
    @State private var coreScale: CGFloat = 1.0
    @State private var coreShadowRadius: CGFloat = 4
    @State private var orbitalScales: [CGFloat] = Array(repeating: 0.5, count: 3)

    // Text animation states
    @State private var subtitleOpacity: Double = 0.7
    @State private var descriptionOpacity: Double = 0.0

    // Progress dots animation states
    @State private var dotScales: [CGFloat] = Array(repeating: 1.0, count: 3)
    @State private var dotOpacities: [Double] = Array(repeating: 0.4, count: 3)

    // Floating particles - properly initialized
    @State private var particlePositions: [CGPoint] = Array(repeating: CGPoint.zero, count: 20)
    @State private var particleOffsets: [CGFloat] = Array(repeating: 0, count: 20)
    @State private var particleScales: [CGFloat] = Array(repeating: 0.5, count: 20)

    private let animationMessages = [
        "Analyzing your story structure...",
        "Enhancing vocabulary choices...",
        "Identifying storytelling opportunities...",
        "Generating personalized insights...",
        "Polishing your narrative...",
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Using unified ContentView background - no local backgrounds

                // Floating particles background
                floatingParticlesBackground(geometry: geometry)

                // Main content
                VStack(spacing: 0) {
                    Spacer()

                    // Main processing animation
                    processingAnimationSection

                    // Dots now inline with title - removed separate section

                    Spacer()
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            checkAuthenticationAndStartProcessing()
        }
        .sheet(isPresented: $showingSignInSheet) {
            GoogleSignInView(appState: appState) {
                showingSignInSheet = false
                // Resume processing after successful authentication
                startProcessing()
            }
        }
        .onChange(of: appState.isAuthenticated) { oldValue, newValue in
            // Resume processing if user signs in while on processing screen
            if newValue && !processingStarted {
                startProcessing()
            }
        }
    }

    // MARK: - Processing Animation

    private var processingAnimationSection: some View {
        VStack(spacing: 40) {
            // Title with inline breathing dots
            HStack(spacing: 12) {
                Text("Cooking")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .accessibilityIdentifier("Cooking")

                // Breathing dots right after "Cooking"
                HStack(spacing: 8) {
                    ForEach(0..<min(3, dotScales.count), id: \.self) { index in
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 6, height: 6)
                            .scaleEffect(dotScales.indices.contains(index) ? dotScales[index] : 1.0)
                            .opacity(
                                dotOpacities.indices.contains(index) ? dotOpacities[index] : 0.4)
                    }
                }
            }

            // Concentric rings animation system - matching original design
            ZStack {
                // Outer ring - neutral colors
                Circle()
                    .stroke(
                        Color.blue.opacity(outerRingOpacity * 0.3),
                        lineWidth: 2
                    )
                    .frame(width: 128, height: 128)
                    .scaleEffect(outerRingScale)
                    .rotationEffect(.degrees(rotationAngle))

                // Inner ring - neutral colors
                Circle()
                    .stroke(
                        Color.purple.opacity(0.2),
                        lineWidth: 2
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(innerRingScale)
                    .rotationEffect(.degrees(-rotationAngle * 0.75))

                // Core - subtle gradient center
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.1), Color.purple.opacity(0.1),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .scaleEffect(coreScale)
                    .shadow(color: .gray.opacity(0.2), radius: coreShadowRadius, x: 0, y: 0)

                // Orbital elements - neutral colors
                ForEach(0..<min(3, orbitalScales.count), id: \.self) { index in
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .offset(x: 80)
                        .rotationEffect(
                            .degrees(rotationAngle * Double(1 + index) + Double(index * 120))
                        )
                        .scaleEffect(
                            orbitalScales.indices.contains(index) ? orbitalScales[index] : 0.5)
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
            ForEach(0..<min(3, dotScales.count), id: \.self) { index in
                Circle()
                    .fill(Color.primary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(dotScales.indices.contains(index) ? dotScales[index] : 1.0)
                    .opacity(dotOpacities.indices.contains(index) ? dotOpacities[index] : 0.4)
            }
        }
        .padding(.top, 32)
    }

    // MARK: - Floating Particles

    private func floatingParticlesBackground(geometry: GeometryProxy) -> some View {
        ZStack {
            ForEach(0..<min(20, particlePositions.count), id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.1), Color.purple.opacity(0.1),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 6, height: 6)
                    .position(
                        x: (particlePositions.indices.contains(index)
                            ? particlePositions[index].x : 0.5) * geometry.size.width,
                        y: (particlePositions.indices.contains(index)
                            ? particlePositions[index].y : 0.5) * geometry.size.height
                    )
                    .offset(y: particleOffsets.indices.contains(index) ? particleOffsets[index] : 0)
                    .opacity(0.3)
                    .scaleEffect(
                        particleScales.indices.contains(index) ? particleScales[index] : 0.5)
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

    private func checkAuthenticationAndStartProcessing() {
        if appState.isAuthenticated {
            startProcessing()
        } else {
            showingSignInSheet = true
        }
    }

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
        withAnimation(
            .spring(response: 1.0, dampingFraction: 0.6).repeatForever(autoreverses: true)
        ) {
            outerRingScale = 1.1
            outerRingOpacity = 0.6
        }

        // Inner ring scaling animation
        withAnimation(
            .spring(response: 1.2, dampingFraction: 0.6).repeatForever(autoreverses: true)
        ) {
            innerRingScale = 1.1
        }

        // Core pulsing animation
        withAnimation(
            .spring(response: 1.0, dampingFraction: 0.6).repeatForever(autoreverses: true)
        ) {
            coreScale = 1.3
            coreShadowRadius = 8
        }

        // Rotation animation - linear for smooth spinning
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }

        // Orbital elements scaling
        for index in 0..<3 {
            withAnimation(
                .spring(response: 1.0, dampingFraction: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.2)
            ) {
                orbitalScales[index] = 1.0
            }
        }

        // Text animations
        withAnimation(
            .spring(response: 1.0, dampingFraction: 0.8).repeatForever(autoreverses: true)
        ) {
            subtitleOpacity = 1.0
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
            descriptionOpacity = 1.0
        }

        // Progress dots animation
        for index in 0..<3 {
            withAnimation(
                .spring(response: 0.8, dampingFraction: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.15)
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
            let randomDelay = Double.random(in: 0...0.8)
            let randomDuration = Double.random(in: 1.5...2.5)

            withAnimation(
                .spring(response: randomDuration, dampingFraction: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(randomDelay)
            ) {
                particleOffsets[index] = CGFloat.random(in: -40...(-20))
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

        // Start real API processing immediately - no artificial delays
        do {
            try await appState.enhanceRecording(recording)
            // The AppStateManager.enhanceRecording method handles the transition to results
        } catch {
            await MainActor.run {
                // Error is already handled in AppStateManager.enhanceRecording
                // But we can handle specific UI feedback here if needed
                print("Enhancement failed: \(error)")
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
