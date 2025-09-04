//
//  ResultsView.swift
//  Amplify
//
//  Results screen with enhanced story and insights - "Comprehend" phase
//

import SwiftUI

struct ResultsView: View {
    @ObservedObject var appState: AppStateManager
    
    @State private var selectedCardIndex = 0 // 0 = transcript, 1 = insights
    @State private var showingTranscriptModal = false
    @State private var showingInsightModal = false
    @State private var isPlaying = false
    @State private var currentPlayTime: Double = 0
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background - matching homepage
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header - matching React design
                headerView
                
                // Photo with Media Player Overlay
                photoWithMediaPlayerSection
                
                // Swipeable Cards
                swipeableCardsSection
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingTranscriptModal) {
            TranscriptModalView(
                recording: appState.currentRecording,
                isPresented: $showingTranscriptModal
            )
        }
        .sheet(isPresented: $showingInsightModal) {
            if let recording = appState.currentRecording,
               !recording.insights.isEmpty {
                InsightModalView(
                    insight: recording.insights[0], // Show first insight for now
                    isPresented: $showingInsightModal
                )
            }
        }
    }
    
    // MARK: - Header View - Matching React Design
    
    private var headerView: some View {
        HStack {
            // Back button - glass effect like React
            Button(action: { appState.returnToHome() }) {
                Image(systemName: "arrow.left")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
            .accessibilityIdentifier("BackButton")
            
            Spacer()
            
            // Center title and duration - matching React
            VStack(spacing: 2) {
                Text("Your Story")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(titleGradient)
                
                if let recording = appState.currentRecording {
                    Text(formatDuration(recording.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Share button - glass effect like React
            Button(action: { /* TODO: Share functionality */ }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
            .accessibilityIdentifier("ShareButton")
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }
    
    // MARK: - Photo with Media Player Section - Matching React
    
    private var photoWithMediaPlayerSection: some View {
        VStack(spacing: 0) {
            if let recording = appState.currentRecording {
                ZStack {
                    // Photo container - exactly matching React h-48 (192px)
                    Group {
                        if let currentPhoto = appState.currentPhoto {
                            // Display actual selected photo
                            Image(uiImage: currentPhoto.image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 192)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            // Fallback gradient if no photo
                            RoundedRectangle(cornerRadius: 16)
                                .fill(fallbackPhotoGradient)
                                .frame(height: 192)
                        }
                    }
                    .overlay(
                        // Subtle gradient overlay for text readability - matching React
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.2), Color.clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    )
                    
                    // Media Player Overlay - positioned at bottom like React
                    VStack {
                        Spacer()
                        mediaPlayerOverlay(duration: recording.duration)
                            .padding(.bottom, 16)
                            .padding(.horizontal, 16)
                    }
                }
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - Swipeable Cards Section - Matching React
    
    private var swipeableCardsSection: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Transcript Card
                    transcriptCard
                        .frame(width: geometry.size.width - 48) // Account for side padding
                        .padding(.horizontal, 24)
                    
                    // Insights Card  
                    insightsCard
                        .frame(width: geometry.size.width - 48) // Account for side padding
                        .padding(.horizontal, 24)
                }
                .offset(x: -CGFloat(selectedCardIndex) * geometry.size.width + dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 100
                            let newIndex: Int
                            
                            if value.translation.width > threshold && selectedCardIndex > 0 {
                                newIndex = selectedCardIndex - 1
                            } else if value.translation.width < -threshold && selectedCardIndex < 1 {
                                newIndex = selectedCardIndex + 1
                            } else {
                                newIndex = selectedCardIndex
                            }
                            
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                selectedCardIndex = newIndex
                                dragOffset = 0
                            }
                        }
                )
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedCardIndex)
            }
            .frame(height: 280) // Optimized height matching React cards
            
            // Card indicator dots - matching React style
            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { index in
                    Circle()
                        .fill(index == selectedCardIndex ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: selectedCardIndex)
                }
            }
            .padding(.top, 16)
        }
    }
    
    // MARK: - Media Player Overlay - Matching React MiniMediaPlayer
    
    private func mediaPlayerOverlay(duration: TimeInterval) -> some View {
        VStack(spacing: 12) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    
                    // Progress track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: geometry.size.width * CGFloat(currentPlayTime / duration), height: 4)
                }
            }
            .frame(height: 4)
            // TODO: Add seek functionality later
            .onTapGesture {
                // Simple tap to seek to middle for now
                currentPlayTime = duration * 0.5
            }
            
            // Controls
            HStack {
                // Time display
                Text(formatDuration(currentPlayTime))
                    .font(.caption)
                    .foregroundColor(.white)
                    .monospacedDigit()
                
                Spacer()
                
                // Play/Pause button
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Duration display
                Text(formatDuration(duration))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(mediaPlayerBackground)
    }
    
    // MARK: - Background Components
    
    private var mediaPlayerBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .opacity(0.8)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    private var titleGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue, Color.purple]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var fallbackPhotoGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Transcript Card - Matching React TranscriptCard
    
    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon and title - exactly matching React
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.title3)
                    .foregroundColor(.gray)
                
                Text("Transcription")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(titleGradient)
                
                Spacer()
            }
            
            // Transcript content - scrollable with improved styling
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if let recording = appState.currentRecording {
                        Text(recording.transcript)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(20)
        .background(cardBackground)
        .onTapGesture {
            showingTranscriptModal = true
        }
    }
    
    // MARK: - Insights Card - Matching React InsightsCard
    
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            insightsHeaderView
            insightsContentView
        }
        .padding(20)
        .background(cardBackground)
        .onTapGesture {
            showingInsightModal = true
        }
    }
    
    private var insightsHeaderView: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb")
                .font(.title3)
                .foregroundColor(.gray)
            
            Text("Sharp Insights")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(titleGradient)
            
            Spacer()
        }
    }
    
    private var insightsContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let recording = appState.currentRecording {
                    ForEach(Array(recording.insights.enumerated()), id: \.element.id) { index, insight in
                        insightRowView(insight: insight, index: index, totalCount: recording.insights.count)
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .frame(maxHeight: .infinity)
    }
    
    private func insightRowView(insight: AIInsight, index: Int, totalCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.emoji)
                    .font(.title2)
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineSpacing(2)
            
            if index < totalCount - 1 {
                Divider()
                    .opacity(0.3)
            }
        }
    }
    
    // MARK: - Actions
    
    @MainActor
    private func togglePlayback() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        isPlaying.toggle()
        
        // TODO: Implement actual audio playback with time updates
        if isPlaying {
            // Simulate playback progress using Task for concurrency safety
            Task { @MainActor in
                while isPlaying, let recording = appState.currentRecording {
                    // Use Task.sleep for non-blocking delay
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    
                    // Update on main thread
                    currentPlayTime += 0.1
                    if currentPlayTime >= recording.duration {
                        currentPlayTime = recording.duration
                        isPlaying = false
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Helper Components (Keeping for modal compatibility)

struct ConfidenceIndicatorView: View {
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Rectangle()
                    .fill(index < Int(confidence * 5) ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 3, height: 12)
            }
        }
    }
}

// MARK: - Modal Views

struct TranscriptModalView: View {
    let recording: Recording?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let recording = recording {
                        // Original transcript
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Original")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(recording.transcript)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        
                        if let enhanced = recording.enhancedTranscript {
                            Divider()
                            
                            // Enhanced transcript
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Enhanced")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Text(enhanced)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Full Transcript")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct InsightModalView: View {
    let insight: AIInsight
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category and confidence
                    HStack {
                        Label(insight.category.displayName, systemImage: insight.category.systemIcon)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        ConfidenceIndicatorView(confidence: insight.confidence)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Analysis")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(insight.description)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    // Suggestion
                    if let suggestion = insight.suggestion {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggestion")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            Text(suggestion)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // High stake words
                    if !insight.highStakeWords.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Key Words")
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                                ForEach(insight.highStakeWords, id: \.self) { word in
                                    Text(word)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(insight.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#if DEBUG
struct ResultsView_Previews: PreviewProvider {
    static var previews: some View {
        ResultsView(appState: AppStateManager())
            .previewDevice("iPhone 15 Pro")
    }
}
#endif