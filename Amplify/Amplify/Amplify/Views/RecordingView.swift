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
                                width: geometry.size.width,
                                height: geometry.size.height * 0.5
                            )
                            .clipped()
                    }
                    
                    // Photo Overlay Controls
                    VStack {
                        photoOverlayControls(geometry: geometry)
                        Spacer()
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)  // Fill entire allocated space
                .background(Color.blue.opacity(0.3))  // DEBUG: Photo section background
                .ignoresSafeArea(.container, edges: .top)
                
                // Bottom Half - White Sheet
                bottomSheet(geometry: geometry)
                    .ignoresSafeArea(.container, edges: .bottom)
            }
            .background(Color.red.opacity(0.5))  // DEBUG: Main VStack container background
        }
        .background(Color.yellow.opacity(0.3))  // DEBUG: GeometryReader background
        .navigationBarHidden(true)
        .onAppear {
            setupRecording()
        }
        .onDisappear {
            cleanupRecording()
        }
    }
    
    // MARK: - Device Detection Helper
    
    private func detectiPhoneModel(width: CGFloat, height: CGFloat) -> String {
        let dimensions = "\(Int(width))x\(Int(height))"
        
        switch dimensions {
        case "390x844": return "iPhone 14, iPhone 15"
        case "393x852": return "iPhone 14 Pro, iPhone 15 Pro" 
        case "402x778": return "iPhone 16 Pro"
        case "430x932": return "iPhone 14 Plus, iPhone 15 Plus"
        case "440x956": return "iPhone 16 Pro Max"
        case "375x812": return "iPhone 13 mini"
        case "428x926": return "iPhone 14 Pro Max, iPhone 15 Pro Max"
        case "375x667": return "iPhone SE (2nd/3rd gen)"
        case "414x896": return "iPhone 11, iPhone XR"
        case "390x693": return "iPhone 16, iPhone 16 Plus"
        default: return "Unknown iPhone Model (\(dimensions))"
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
        // Simple 50/50 split - let ignoresSafeArea handle extensions automatically
        let totalHeight = geometry.size.height
        let bottomSheetHeight = totalHeight * 0.5
        
        
        let headerHeight: CGFloat = 50 // Header space for "Listening..."
        let controlsHeight: CGFloat = 140 // Timer + button space
        let transcriptHeight = bottomSheetHeight - headerHeight - controlsHeight
        
        return VStack(spacing: 0) {
                // Fixed height header - positioned close to photo bottom
                VStack {
                    Text("Listening...")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: headerHeight)
                .frame(maxWidth: .infinity)
                .background(Color.purple.opacity(0.4))  // DEBUG: Header section background
                // No top padding - header should be flush with photo edge
                
                // Transcript area with 8-line design, text starts in middle
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack(alignment: .leading, spacing: 0) {
                            // Create 8-line spacing (4 lines above + content + space below)
                            let lineHeight: CGFloat = 24
                            let totalLines: CGFloat = 8
                            let topSpacing = lineHeight * 3.5 // Start near middle of 8 lines
                            
                            // Top spacer to position text in middle of 8-line area
                            Spacer()
                                .frame(height: topSpacing)
                            
                            if currentTranscript.isEmpty {
                                Text("Start speaking to see your words appear here...")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .lineSpacing(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24)
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
                            
                            // Bottom spacer to complete 8-line area
                            Spacer()
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
        .frame(width: geometry.size.width, height: bottomSheetHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity)  // Fill entire allocated space
        .background(
            // DEBUG: Bottom sheet background
            Rectangle()
                .fill(Color.green.opacity(0.4))
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
        .ignoresSafeArea(.container, edges: .bottom)
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