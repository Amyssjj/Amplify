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
            ZStack {
                // Top Half - Full Photo Background
                VStack(spacing: 0) {
                    if let photo = appState.currentPhoto {
                        Image(uiImage: photo.image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(
                                width: max(0, geometry.size.width),
                                height: max(0, geometry.size.height * 0.6)
                            )
                            .clipped()
                    }
                    Spacer()
                }
                .ignoresSafeArea(.all, edges: .top)
                
                // Photo Overlay Controls
                VStack {
                    photoOverlayControls
                    Spacer()
                }
                
                // Bottom Sheet
                VStack {
                    Spacer()
                    bottomSheet(geometry: geometry)
                }
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
    
    private var photoOverlayControls: some View {
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
        VStack(spacing: 0) {
            // White rounded sheet
            VStack(spacing: 24) {
                // "Listening..." header
                VStack(spacing: 16) {
                    Text("Listening...")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.top, 24)
                
                // Transcript area
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack(alignment: .leading, spacing: 8) {
                            if currentTranscript.isEmpty {
                                Text("Start speaking to see your words appear here...")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                HStack {
                                    Text(currentTranscript)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .lineSpacing(2)
                                        .id("transcript")
                                    
                                    // Blinking cursor
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: 2, height: 20)
                                        .opacity(pulseAnimation ? 1.0 : 0.3)
                                        .animation(
                                            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                            value: pulseAnimation
                                        )
                                    
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .onChange(of: currentTranscript) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("transcript", anchor: .bottom)
                            }
                        }
                    }
                }
                .frame(height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 20)
                
                Spacer(minLength: 40)
                
                // Timer
                Text(formatDuration(appState.currentRecordingDuration))
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                // Stop button
                Button(action: stopRecording) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 80, height: 80)
                            .shadow(color: .red.opacity(0.4), radius: 15, x: 0, y: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                    }
                }
                .scaleEffect(pulseAnimation ? 1.02 : 1.0)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
                .accessibilityIdentifier("StopRecordingButton")
                .accessibilityLabel("Stop recording")
                
                Text("Tap to stop recording")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer(minLength: 32)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
            )
        }
        .frame(height: max(0, geometry.size.height * 0.5))
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
    
    private func cancelRecording() {
        speechService.stopLiveRecognition()
        audioService.cancelRecording()
        appState.returnToHome()
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