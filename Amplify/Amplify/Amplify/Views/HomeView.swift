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
                    // Header - left aligned like React
                    headerView
                        .padding(.top, 32) 
                        .padding(.bottom, 16)
                    
                    // Main content area - matching React layout
                    VStack {
                        Spacer(minLength: 40)
                        
                        // Photo prompt section  
                        photoPromptSection(geometry: geometry)
                        
                        // Dots indicator
                        dotsIndicator
                            .padding(.top, 16)
                        
                        Spacer(minLength: 80)
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
        VStack(alignment: .leading, spacing: 8) {
            // Gradient text matching React version - left aligned
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
                        .frame(height: max(200, min(geometry.size.height * 0.35, 280)))
                } else if let photo = currentPhoto {
                    VStack(spacing: 0) {
                        Image(uiImage: photo.image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(
                                maxWidth: max(200, geometry.size.width - 48),
                                maxHeight: max(200, min(geometry.size.height * 0.35, 280))
                            )
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
                    }
                }
            }
            .frame(
                maxWidth: max(200, geometry.size.width - 48),
                maxHeight: max(200, min(geometry.size.height * 0.35, 280))
            )
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
            .scaleEffect(recordButtonPressed ? 0.95 : (appState.canRecord ? 1.0 : 0.95))
            .animation(.interpolatingSpring(stiffness: 400, damping: 25), value: appState.canRecord)
            .animation(.interpolatingSpring(stiffness: 400, damping: 25), value: recordButtonPressed)
            .accessibilityIdentifier("RecordStoryButton")
            .accessibilityLabel("Record your story")
            .accessibilityHint("Tap to start recording your story about this photo")
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Actions
    
    @State private var recordButtonPressed = false
    @State private var isTransitioning = false
    
    private func startRecording() {
        guard let photo = currentPhoto else { return }
        guard !isTransitioning else { return } // Prevent double-tap issues
        
        isTransitioning = true
        
        // Immediate visual feedback
        recordButtonPressed = true
        
        // Immediate haptic feedback
        let lightImpact = UIImpactFeedbackGenerator(style: .light)
        lightImpact.impactOccurred()
        
        // Ultra-smooth transition with spring physics - consistent every time
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
            appState.transitionToRecording(with: photo)
        }
        
        // Reset states quickly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            recordButtonPressed = false
            isTransitioning = false
        }
        
        // Completion haptic at end of fast animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
            mediumImpact.impactOccurred()
        }
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
    
    // MARK: - Dots Indicator - Shows swipe capability
    
    private var dotsIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(Color.gray.opacity(index == 0 ? 0.8 : 0.3))
                    .frame(width: 6, height: 6)
                    .animation(.easeInOut(duration: 0.3), value: true)
            }
        }
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