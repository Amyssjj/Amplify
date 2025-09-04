//
//  ContentView.swift
//  Amplify
//
//  Created by Jing on 9/1/25.
//

//
//  ContentView.swift
//  Amplify
//
//  Main navigation coordinator for the Amplify app
//

import SwiftUI
import Foundation

struct ContentView: View {
    @StateObject private var appState = AppStateManager()
    @StateObject private var photoService = PhotoLibraryService()
    @StateObject private var audioService = AudioRecordingService()
    @StateObject private var speechService = SpeechRecognitionService()
    @StateObject private var aiService = AIEnhancementService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Main content based on current screen
                Group {
                    switch appState.currentScreen {
                    case .home:
                        HomeView(
                            appState: appState,
                            photoService: photoService,
                            audioService: audioService,
                            speechService: speechService
                        )
                    case .recording:
                        RecordingView(
                            appState: appState,
                            audioService: audioService,
                            speechService: speechService
                        )
                    case .processing:
                        ProcessingView(appState: appState, aiService: aiService)
                    case .results:
                        ResultsView(
                            appState: appState
                        )
                    }
                }
                .transition(.asymmetric(
                    insertion: customTransition(for: appState.currentScreen),
                    removal: customTransition(for: appState.currentScreen)
                ))
                .animation(.spring(response: 0.55, dampingFraction: 0.825, blendDuration: 0), value: appState.currentScreen)
            }
        }
        .alert(
            appState.currentError?.title ?? "Error",
            isPresented: $appState.showingError
        ) {
            Button("OK") {
                appState.clearError()
            }
        } message: {
            Text(appState.currentError?.message ?? "An error occurred")
        }
    }
    
    // MARK: - iPhone Notes-Style Transitions
    
    private func customTransition(for screen: AppScreen) -> AnyTransition {
        switch screen {
        case .recording:
            // iPhone Notes-style coordinated expansion
            return AnyTransition.asymmetric(
                insertion: .modifier(
                    active: RecordingTransitionModifier(progress: 0),
                    identity: RecordingTransitionModifier(progress: 1)
                ),
                removal: .modifier(
                    active: RecordingTransitionModifier(progress: 1),
                    identity: RecordingTransitionModifier(progress: 0)
                )
            )
        case .home:
            // Smooth return with gentle scaling
            return AnyTransition.asymmetric(
                insertion: .scale(scale: 0.92, anchor: .center)
                    .combined(with: .opacity)
                    .combined(with: .move(edge: .top)),
                removal: .scale(scale: 1.08, anchor: .center)
                    .combined(with: .opacity)
                    .combined(with: .move(edge: .bottom))
            )
        case .processing:
            return AnyTransition.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.94, anchor: .center)),
                removal: .opacity.combined(with: .scale(scale: 1.06, anchor: .center))
            )
        case .results:
            return AnyTransition.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
    }
}

// MARK: - Recording Transition Modifier

struct RecordingTransitionModifier: ViewModifier {
    let progress: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(
                x: 0.95 + (0.05 * progress), 
                y: 0.95 + (0.05 * progress),
                anchor: .center
            )
            .offset(y: -20 * (1 - progress))
            .opacity(0.3 + (0.7 * progress))
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 15 Pro")
    }
}
#endif
