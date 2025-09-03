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
        VStack(spacing: 12) {
            HStack {
                Button("Cancel") {
                    cancelRecording()
                }
                .foregroundColor(.red)
                .accessibilityIdentifier("CancelRecordingButton")
                
                Spacer()
                
                // Recording timer
                Text(formatDuration(appState.currentRecordingDuration))
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .accessibilityIdentifier("RecordingTimer")
                
                Spacer()
                
                // Progress indicator
                CircularProgressView(
                    progress: appState.currentRecordingDuration / maxRecordingDuration,
                    lineWidth: 3
                )
                .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Photo reference (smaller)
            if let photo = appState.currentPhoto {
                Image(uiImage: photo.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Transcript Section
    
    private func transcriptSection(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Live Transcript")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if speechService.isRecognizing {
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                                .scaleEffect(pulseAnimation ? 1.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: pulseAnimation
                                )
                        }
                    }
                }
            }
            
            // Transcript container
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 8) {
                        if currentTranscript.isEmpty {
                            Text("Start speaking to see your words appear here...")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            Text(currentTranscript)
                                .font(.body)
                                .foregroundColor(.primary)
                                .id("transcript")
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .onChange(of: currentTranscript) { _ in
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("transcript", anchor: .bottom)
                        }
                    }
                }
            }
            .frame(minHeight: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .accessibilityIdentifier("LiveTranscript")
            .accessibilityLabel("Live transcript of your recording")
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Recording Controls
    
    private var recordingControlsSection: some View {
        VStack(spacing: 24) {
            // Recording status
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                Text("Recording...")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            // Stop button
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
                        .frame(width: 80, height: 80)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                }
            }
            .accessibilityIdentifier("StopRecordingButton")
            .accessibilityLabel("Stop recording")
            .accessibilityHint("Tap to stop recording and process your story")
            
            Text("Tap to stop recording")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.bottom, 40)
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