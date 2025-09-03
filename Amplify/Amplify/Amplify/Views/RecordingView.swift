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
    
    private let maxRecordingDuration: TimeInterval = 60.0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Half - Photo Section
                ZStack {
                    if let photo = appState.currentPhoto {
                        Image(uiImage: photo.image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(
                                width: max(1, geometry.size.width),
                                height: max(100, geometry.size.height * 0.5)
                            )
                            .clipped()
                    }
                    
                    // Photo Overlay Controls
                    VStack {
                        photoOverlayControls(geometry: geometry)
                        Spacer()
                    }
                }
                .frame(height: max(100, geometry.size.height * 0.5))
                .ignoresSafeArea(.container, edges: .top)
                
                // Bottom Half - White Sheet
                bottomSheet(geometry: geometry)
                    .ignoresSafeArea(.container, edges: .bottom)
            }
        }
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
        HStack {
            // Back button
            Button {
                cancelRecording()
            } label: {
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.8))
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.3))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
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
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, max(0, geometry.safeAreaInsets.top + 8))
    }
    
    // MARK: - Bottom Sheet
    
    private func bottomSheet(geometry: GeometryProxy) -> some View {
        let bottomSheetHeight = geometry.size.height / 2
        let headerHeight: CGFloat = 70 // "Listening..." header space
        let controlsHeight: CGFloat = 140 // Timer + button space
        let transcriptHeight = bottomSheetHeight - headerHeight - controlsHeight
        
        return VStack(spacing: 0) {
                // Fixed height header
                VStack {
                    Text("Listening...")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .frame(height: headerHeight)
                .frame(maxWidth: .infinity)
                
                // Transcript area with calculated height to fill remaining space
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack(alignment: .leading, spacing: 0) {
                            if currentTranscript.isEmpty {
                                Text("Start speaking to see your words appear here...")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 20)
                            } else {
                                Text(currentTranscript + (pulseAnimation ? "│" : "║"))
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .lineSpacing(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 20)
                                    .id("transcript")
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
                            }
                        }
                        .frame(minHeight: max(0, transcriptHeight - 40)) // Fill available height
                        .onChange(of: currentTranscript) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("transcript", anchor: .bottom)
                            }
                        }
                    }
                }
                .frame(height: transcriptHeight)
                
                // Fixed height bottom controls
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
                .frame(height: controlsHeight)
                .frame(maxWidth: .infinity)
        }
        .frame(height: bottomSheetHeight + geometry.safeAreaInsets.bottom)
        .frame(maxWidth: .infinity)
        .background(
            // White background that extends to screen edge
            Rectangle()
                .fill(Color(.systemBackground))
                .ignoresSafeArea(.container, edges: .bottom)
        )
        .clipShape(
            // Only round top corners, extend straight to bottom edge
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 24
            )
        )
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
    }
    
    // MARK: - Recording Controls
    
    private var recordingControlsSection: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 20)
            
            // Recording status with pulsing red dot
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                Text("Recording...")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            // Large stop button - RED during recording like React design
            Button(action: stopRecording) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 90, height: 90)
                        .shadow(color: .red.opacity(0.4), radius: 15, x: 0, y: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                }
            }
            .scaleEffect(pulseAnimation ? 1.02 : 1.0)
            .animation(
                .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                value: pulseAnimation
            )
            .accessibilityIdentifier("StopRecordingButton")
            .accessibilityLabel("Stop recording")
            .accessibilityHint("Tap to stop recording and process your story")
            
            Text("Tap to stop recording")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
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
    
    @State private var backButtonPressed = false
    @State private var isTransitioning = false
    
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