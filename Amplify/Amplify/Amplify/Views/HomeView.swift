//
//  HomeView.swift
//  Amplify
//
//  Home screen with photo prompt and record button - "Capture" entry point
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var appState: AppStateManager
    @ObservedObject var photoService: PhotoLibraryService
    @ObservedObject var audioService: AudioRecordingService
    @ObservedObject var speechService: SpeechRecognitionService
    
    @State private var currentPhoto: PhotoData?
    @State private var isLoadingPhoto = true
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Photo prompt section
                photoPromptSection(geometry: geometry)
                
                // Record button section
                recordButtonSection
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadInitialPhoto()
            await requestPermissions()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Amplify")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Turn moments into stories")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
        .padding(.horizontal)
    }
    
    // MARK: - Photo Prompt Section
    
    private func photoPromptSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            Text("Your Story Prompt")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Photo container with glassmorphism effect
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                if isLoadingPhoto {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(height: 250)
                } else if let photo = currentPhoto {
                    Image(uiImage: photo.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .accessibilityIdentifier("StoryPromptPhoto")
                        .accessibilityLabel("Story prompt photo")
                        .onTapGesture {
                            Task {
                                await refreshPhoto()
                            }
                        }
                }
            }
            .frame(height: 250)
            .padding(.horizontal, 24)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if abs(value.translation.width) > 100 {
                            Task {
                                await refreshPhoto()
                            }
                        }
                    }
            )
            
            // Swipe hint
            Text("Swipe or tap for a new photo")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 32)
    }
    
    // MARK: - Record Button Section
    
    private var recordButtonSection: some View {
        VStack(spacing: 16) {
            // Record button
            Button(action: startRecording) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.pink]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            .disabled(!appState.canRecord)
            .opacity(appState.canRecord ? 1.0 : 0.6)
            .scaleEffect(appState.canRecord ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.2), value: appState.canRecord)
            .accessibilityIdentifier("RecordStoryButton")
            .accessibilityLabel("Record your story")
            .accessibilityHint("Tap to start recording your story about this photo")
            
            Text("Tap to record your story")
                .font(.headline)
                .foregroundColor(.primary)
            
            if !appState.canRecord {
                Text("Permissions needed to record")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func startRecording() {
        guard let photo = currentPhoto else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        appState.transitionToRecording(with: photo)
    }
    
    private func loadInitialPhoto() async {
        isLoadingPhoto = true
        let result = await photoService.getRandomPhotoFromFavorites()
        
        await MainActor.run {
            switch result {
            case .success(let photo):
                currentPhoto = photo
            case .failure:
                currentPhoto = photoService.getFallbackPhoto()
            }
            isLoadingPhoto = false
        }
    }
    
    private func refreshPhoto() async {
        isLoadingPhoto = true
        let result = await photoService.getRandomPhotoFromFavorites()
        
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                switch result {
                case .success(let photo):
                    currentPhoto = photo
                case .failure:
                    currentPhoto = photoService.getFallbackPhoto()
                }
                isLoadingPhoto = false
            }
        }
    }
    
    private func requestPermissions() async {
        // Request photo library permission
        let photoPermission = await photoService.requestPhotoLibraryPermission()
        appState.updatePhotoPermissionStatus(photoPermission)
        
        // Request microphone permission
        let micPermission = await audioService.requestMicrophonePermission()
        appState.updateMicrophonePermissionStatus(micPermission)
        
        // Request speech recognition permission
        let speechPermission = await speechService.requestSpeechRecognitionPermission()
        appState.updateSpeechPermissionStatus(speechPermission)
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            appState: AppStateManager(),
            photoService: PhotoLibraryService(),
            audioService: AudioRecordingService(),
            speechService: SpeechRecognitionService()
        )
        .previewDevice("iPhone 15 Pro")
    }
}
#endif