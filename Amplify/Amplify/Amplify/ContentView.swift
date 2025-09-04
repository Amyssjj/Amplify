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
    @Namespace private var photoTransition
    
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
                            speechService: speechService,
                            photoTransition: photoTransition
                        )
                    case .recording:
                        RecordingView(
                            appState: appState,
                            audioService: audioService,
                            speechService: speechService,
                            photoTransition: photoTransition
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
                .animation(.interpolatingSpring(stiffness: 180, damping: 40), value: appState.currentScreen)
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
    
    // MARK: - Custom Transitions
    
    private func customTransition(for screen: AppScreen) -> AnyTransition {
        switch screen {
        case .recording:
            // No transition - let matchedGeometryEffect handle unified photo expansion+movement
            return AnyTransition.identity
        case .home:
            // Elegant return to home with refined spring physics
            return AnyTransition.asymmetric(
                insertion: .scale(scale: 0.96, anchor: .center)
                    .combined(with: .move(edge: .top))
                    .combined(with: .opacity),
                removal: .scale(scale: 1.04, anchor: .center)
                    .combined(with: .move(edge: .bottom))
                    .combined(with: .opacity)
            )
        case .processing:
            return AnyTransition.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.9, anchor: .center)),
                removal: .opacity.combined(with: .scale(scale: 1.1, anchor: .center))
            )
        case .results:
            return AnyTransition.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 15 Pro")
    }
}
#endif
