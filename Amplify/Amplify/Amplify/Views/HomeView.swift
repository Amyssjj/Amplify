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
            ZStack {
                // Background gradient animations - matching React version
                backgroundAnimations
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.top, 32)
                        .padding(.bottom, 16)
                    
                    // Main content area - centered like React
                    VStack {
                        Spacer()
                        
                        // Photo prompt section  
                        photoPromptSection(geometry: geometry)
                            .padding(.bottom, 80)
                        
                        Spacer()
                    }
                    
                    // Record button section at bottom
                    recordButtonSection
                        .padding(.bottom, 48)
                }
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
            // Gradient text matching React version
            Text("Amplify")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black, Color.gray]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Text("Level up your storytelling")
                .font(.subheadline)
                .foregroundColor(Color(.systemGray))
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Photo Prompt Section - Matching React PhotoCard
    
    private func photoPromptSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Photo card with glass effect matching React version
            ZStack {
                // Glass card background - matching React .glass-card
                RoundedRectangle(cornerRadius: 24) // rounded-3xl = 24px
                    .fill(
                        .ultraThinMaterial.opacity(0.6)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.4))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                
                if isLoadingPhoto {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(height: 320)
                } else if let photo = currentPhoto {
                    VStack(spacing: 0) {
                        Image(uiImage: photo.image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                // Subtle gradient overlay like React
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.black.opacity(0.1),
                                        Color.clear,
                                        Color.white.opacity(0.05)
                                    ]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                            )
                            .accessibilityIdentifier("StoryPromptPhoto")
                            .accessibilityLabel("Story prompt photo")
                            .onTapGesture {
                                Task {
                                    await refreshPhoto()
                                }
                            }
                        
                        // Swipe hint with glass button effect like React
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                                .foregroundColor(Color(.systemGray2))
                            Text("Swipe for new photo")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(.systemGray2))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial.opacity(0.8))
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.3))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .offset(y: -16)
                    }
                }
            }
            .frame(height: 320)
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
        }
    }
    
    // MARK: - Record Button Section - Matching React RecordButton
    
    private var recordButtonSection: some View {
        VStack(spacing: 0) {
            // Record button with glass effect like React
            Button(action: startRecording) {
                ZStack {
                    // Glass button background matching React .glass-button
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
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.primary)
                }
            }
            .disabled(!appState.canRecord)
            .opacity(appState.canRecord ? 1.0 : 0.6)
            .scaleEffect(appState.canRecord ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.2), value: appState.canRecord)
            .accessibilityIdentifier("RecordStoryButton")
            .accessibilityLabel("Record your story")
            .accessibilityHint("Tap to start recording your story about this photo")
        }
        .padding(.horizontal, 24)
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
    
    // MARK: - Background Animations - Matching React floating elements
    
    private var backgroundAnimations: some View {
        ZStack {
            // Top-right floating gradient - matches React version
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.purple.opacity(0.2),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 40)
                .position(x: UIScreen.main.bounds.width * 0.8, y: 100)
            
            // Bottom-left floating gradient - matches React version  
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.pink.opacity(0.2),
                            Color.orange.opacity(0.3),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 64
                    )
                )
                .frame(width: 128, height: 128)
                .blur(radius: 40)
                .position(x: UIScreen.main.bounds.width * 0.2, y: UIScreen.main.bounds.height * 0.8)
        }
        .allowsHitTesting(false) // Don't interfere with touch events
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