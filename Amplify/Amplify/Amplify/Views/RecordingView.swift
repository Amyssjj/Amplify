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
                // Header with photo reference
                headerView
                
                // Live transcript section
                transcriptSection(geometry: geometry)
                
                // Recording controls
                recordingControlsSection
                
                Spacer()
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
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 20) {
            // Top navigation bar
            HStack {
                Button("Cancel") {
                    cancelRecording()
                }
                .foregroundColor(.red)
                .font(.body)
                .accessibilityIdentifier("CancelRecordingButton")
                
                Spacer()
                
                // Recording timer - prominent center position
                Text(formatDuration(appState.currentRecordingDuration))
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .accessibilityIdentifier("RecordingTimer")
                
                Spacer()
                
                // Settings/More button (3 dots) like in design
                Button {
                    // Settings action - placeholder
                } label: {
                    CircularProgressView(
                        progress: appState.currentRecordingDuration / maxRecordingDuration,
                        lineWidth: 3
                    )
                    .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Photo thumbnail - centered and smaller like design
            if let photo = appState.currentPhoto {
                Image(uiImage: photo.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Transcript Section
    
    private func transcriptSection(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Live Transcript title and 3-dot menu
            HStack {
                Text("Live Transcript")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 3-dot menu button matching design
                Button {
                    // Menu action - placeholder
                } label: {
                    HStack(spacing: 3) {
                        ForEach(0..<3) { _ in
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            
            // Large transcript container - matching design
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 12) {
                        if currentTranscript.isEmpty {
                            Text("Start speaking to see your words appear here...")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                                .padding(.top, 20)
                        } else {
                            Text(currentTranscript)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                                .id("transcript")
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .onChange(of: currentTranscript) { _ in
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("transcript", anchor: .bottom)
                        }
                    }
                }
            }
            .frame(minHeight: 250)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
            )
            .accessibilityIdentifier("LiveTranscript")
            .accessibilityLabel("Live transcript of your recording")
        }
        .padding(.horizontal, 24)
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
            
            // Large stop button matching design exactly
            Button(action: stopRecording) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                        .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                    
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
                        case .failure(let error):
                            appState.handleError(.speechRecognitionAccessDenied)
                        }
                    }
                    
                case .failure(let error):
                    await MainActor.run {
                        appState.handleError(.recordingFailed)
                    }
                }
                
            case .failure(let error):
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
            
        case .failure(let error):
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