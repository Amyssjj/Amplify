//
//  ResultsView.swift
//  Amplify
//
//  Results screen with enhanced story and insights - "Comprehend" phase
//

import SwiftUI

struct ResultsView: View {
    @ObservedObject var appState: AppStateManager
    
    @State private var selectedInsightIndex = 0
    @State private var showingTranscriptModal = false
    @State private var showingInsightModal = false
    @State private var isPlaying = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Enhanced transcript preview
                transcriptPreviewSection
                
                // Insights carousel
                insightsCarouselSection
                
                // Action buttons
                actionButtonsSection
                
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
               selectedInsightIndex < recording.insights.count {
                InsightModalView(
                    insight: recording.insights[selectedInsightIndex],
                    isPresented: $showingInsightModal
                )
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Add explicit spacing from top
                Color.clear
                    .frame(height: geometry.safeAreaInsets.top + 20)
                
                HStack {
                    Button("< Home") {
                        appState.returnToHome()
                    }
                    .foregroundColor(.blue)
                    .accessibilityIdentifier("ReturnHomeButton")
                    
                    Spacer()
                    
                    Text("Your Enhanced Story")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .accessibilityIdentifier("YourEnhancedStory")
                    
                    Spacer()
                    
                    // Play button
                    Button(action: togglePlayback) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .accessibilityIdentifier("PlayEnhancedStory")
                    .accessibilityLabel(isPlaying ? "Pause story" : "Play enhanced story")
                }
                .frame(height: 44)
                .padding(.horizontal, 24)
                
                // Duration and improvement indicator
                if let recording = appState.currentRecording {
                    HStack(spacing: 16) {
                    Label(formatDuration(recording.duration), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if recording.enhancedTranscript != nil {
                        Label("Enhanced", systemImage: "sparkles")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            }
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Transcript Preview
    
    private var transcriptPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Enhanced Transcript")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Expand") {
                    showingTranscriptModal = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Transcript preview container
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if let recording = appState.currentRecording {
                        Text(recording.enhancedTranscript ?? recording.transcript)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(5)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .onTapGesture {
                showingTranscriptModal = true
            }
            .accessibilityIdentifier("EnhancedTranscript")
            .accessibilityLabel("Enhanced transcript preview")
            .accessibilityHint("Tap to view full transcript")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    
    // MARK: - Insights Carousel
    
    private var insightsCarouselSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Insights")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let recording = appState.currentRecording {
                    Text("\(selectedInsightIndex + 1) of \(recording.insights.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            
            // Insights carousel
            if let recording = appState.currentRecording, !recording.insights.isEmpty {
                TabView(selection: $selectedInsightIndex) {
                    ForEach(Array(recording.insights.enumerated()), id: \.element.id) { index, insight in
                        InsightCardView(insight: insight)
                            .tag(index)
                            .onTapGesture {
                                showingInsightModal = true
                            }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 160)
                .accessibilityIdentifier("InsightsCards")
                .accessibilityLabel("AI insights carousel")
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Text("No insights available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 160)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 32)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Save to Toolkit button
            Button(action: saveToToolkit) {
                HStack {
                    Image(systemName: "folder.badge.plus")
                        .font(.title3)
                    
                    Text("Save to Toolkit")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("Save enhanced story to toolkit")
            
            // Try Again button
            Button(action: tryAgain) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                    
                    Text("Try Again")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                )
            }
            .accessibilityLabel("Try recording another story")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    // MARK: - Actions
    
    private func togglePlayback() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        isPlaying.toggle()
        
        // TODO: Implement actual audio playback
        if isPlaying {
            // Start playback
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isPlaying = false
            }
        } else {
            // Stop playback
        }
    }
    
    private func saveToToolkit() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // TODO: Implement save to toolkit functionality
        print("Saving to toolkit...")
    }
    
    private func tryAgain() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        appState.returnToHome()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Insight Card View

struct InsightCardView: View {
    let insight: AIInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with category icon and title
            HStack {
                Image(systemName: insight.category.systemIcon)
                    .font(.title3)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(insight.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Confidence indicator
                ConfidenceIndicatorView(confidence: insight.confidence)
            }
            
            // Description
            Text(insight.description)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            // Action indicator
            if insight.isActionable {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text("Tap for suggestion")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }
}

// MARK: - Confidence Indicator

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