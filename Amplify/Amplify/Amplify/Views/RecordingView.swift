//
//  RecordingView.swift
//  Amplify
//
//  Recording screen with live transcription - "Capture" execution
//

import SwiftUI

struct RecordingView: View {
    @ObservedObject var appState: AppStateManager
    @ObservedObject var audioService: AudioRecordingService
    @ObservedObject var speechService: SpeechRecognitionService
    
    @State private var currentTranscript = ""
    @State private var recordingStarted = false
    @State private var pulseAnimation = false
    @State private var backButtonPressed = false
    @State private var isTransitioning = false
    
    private let maxRecordingDuration: TimeInterval = 60.0
    private let bottomSheetOverlap: CGFloat = 24
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Photo in top half with clean positioning
                if let photo = appState.currentPhoto {
                    Image(uiImage: photo.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.5)
                        .clipped()
                        .overlay(
                            // Dark gradient at bottom for better contrast
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 100)
                            .offset(y: (geometry.size.height * 0.5) - 100)
                        )
                } else {
                    // Fallback background when no photo
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .frame(height: geometry.size.height * 0.5)
                    
                    // DEBUG: Show when no photo is available
                    VStack {
                        Text("❌ DEBUG")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("No photo available")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    .frame(height: geometry.size.height * 0.5)
                }
                
                // Photo controls overlay
                VStack {
                    photoOverlayControls(geometry: geometry)
                    Spacer()
                }
                .frame(height: geometry.size.height * 0.5)
                
                // Bottom sheet with clean overlap
                bottomSheetContent()
                    .frame(width: geometry.size.width, height: (geometry.size.height * 0.5) + bottomSheetOverlap)
                    .background(
                        Color(.systemBackground)
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 24,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: 24
                                )
                            )
                            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -5)
                    )
                    .offset(y: (geometry.size.height * 0.5) - bottomSheetOverlap)
            }
            .background(Color.black) // Fill any gaps with black
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .onAppear {
            setupRecording()
        }
        .onDisappear {
            cleanupRecording()
        }
    }
    
    
    // MARK: - Photo Overlay Controls
    
    private func photoOverlayControls(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            HStack {
                // Back button
                Button {
                    cancelRecording()
                } label: {
                    Circle()
                        .fill(.ultraThinMaterial.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                        )
                }
                .scaleEffect(backButtonPressed ? 0.9 : 1.0)
                .animation(.interpolatingSpring(stiffness: 400, damping: 25), value: backButtonPressed)
                .accessibilityIdentifier("CancelRecordingButton")
                
                Spacer()
                
                // REC indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )
                    
                    Text("REC")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.8))
                )
            }
            .frame(height: 44)
            .padding(.horizontal, 16)
            .padding(.top, 10) // Fine-tune this value (8-12 points typically)
            
            Spacer()
        }
        .padding(.top, geometry.safeAreaInsets.top)
        .frame(height: geometry.size.height * 0.5)
    }
    
    // MARK: - Bottom Sheet Content
    
    private func bottomSheetContent() -> some View {
        VStack(spacing: 0) {
            // Header - natural sizing with padding
            Text("Listening...")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.top, 24)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity)
            
            // Transcript area - flexible height with natural scrolling
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 16) {
                        if currentTranscript.isEmpty {
                            Text("Start speaking to see your words appear here...")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                                .lineSpacing(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 40)
                        } else {
                            Text(currentTranscript + (pulseAnimation ? "│" : "║"))
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineSpacing(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                                .id("transcript")
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .onChange(of: currentTranscript) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("transcript", anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity) // Take remaining space
            
            // Bottom controls - natural sizing
            VStack(spacing: 16) {
                // Timer pill
                Text(formatDuration(appState.currentRecordingDuration))
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial.opacity(0.8))
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.3))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                
                // Recording button
                Button(action: stopRecording) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.3))
                            .frame(width: 90, height: 90)
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                            .opacity(pulseAnimation ? 0.0 : 0.3)
                            .animation(
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                                value: pulseAnimation
                            )
                        
                        Circle()
                            .fill(Color.red)
                            .frame(width: 70, height: 70)
                            .shadow(color: .red.opacity(0.4), radius: 15, x: 0, y: 8)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white)
                            .frame(width: 14, height: 14)
                    }
                }
                .scaleEffect(pulseAnimation ? 1.02 : 1.0)
                .animation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
                .accessibilityIdentifier("StopRecordingButton")
                .accessibilityLabel("Stop recording")
            }
            .padding(.bottom, 32) // Natural bottom padding
            .frame(maxWidth: .infinity)
        }
    }
    
    
    // MARK: - Actions
    
    private func setupRecording() {
        Task {
            // Prepare audio recording
            let audioResult = await audioService.prepareForRecording()
            
            switch audioResult {
            case .success:
                // Start audio recording
                let recordResult = audioService.startRecording()
                
                switch recordResult {
                case .success:
                    // Start speech recognition
                    let speechResult = await speechService.startLiveRecognition { transcript in
                        DispatchQueue.main.async {
                            currentTranscript = transcript
                        }
                    }
                    
                    await MainActor.run {
                        switch speechResult {
                        case .success:
                            appState.startRecording()
                            recordingStarted = true
                            pulseAnimation = true
                        case .failure(_):
                            appState.handleError(.speechRecognitionAccessDenied)
                        }
                    }
                    
                case .failure(_):
                    await MainActor.run {
                        appState.handleError(.recordingFailed)
                    }
                }
                
            case .failure(_):
                await MainActor.run {
                    appState.handleError(.microphoneAccessDenied)
                }
            }
        }
    }
    
    private func stopRecording() {
        guard recordingStarted else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        speechService.stopLiveRecognition()
        let audioResult = audioService.stopRecording()
        
        switch audioResult {
        case .success(let audioData):
            let recording = Recording(
                id: UUID(),
                transcript: currentTranscript,
                duration: audioData.duration,
                photoURL: appState.currentPhoto?.identifier ?? "",
                timestamp: Date()
            )
            
            appState.stopRecording(with: recording)
            
        case .failure(_):
            appState.handleError(.audioProcessingFailed)
        }
    }
    
    private func cancelRecording() {
        guard !isTransitioning else { return } // Prevent double-tap issues
        
        isTransitioning = true
        
        // Immediate visual feedback
        backButtonPressed = true
        
        // Light haptic feedback
        let lightImpact = UIImpactFeedbackGenerator(style: .light)
        lightImpact.impactOccurred()
        
        // Clean up services
        speechService.stopLiveRecognition()
        audioService.cancelRecording()
        
        // Smooth spring transition back to home - consistent every time
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
            appState.returnToHome()
        }
        
        // Reset states
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            backButtonPressed = false
            isTransitioning = false
        }
    }
    
    private func cleanupRecording() {
        speechService.stopLiveRecognition()
        audioService.cleanup()
        pulseAnimation = false
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

#if DEBUG
struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView(
            appState: AppStateManager(),
            audioService: AudioRecordingService(),
            speechService: SpeechRecognitionService()
        )
        .previewDevice("iPhone 15 Pro")
    }
}
#endif