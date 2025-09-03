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
                        ProcessingView(
                            appState: appState,
                            aiService: aiService
                        )
                    case .results:
                        ResultsView(
                            appState: appState
                        )
                    }
                }
                .animation(.easeInOut(duration: 0.5), value: appState.currentScreen)
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
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 15 Pro")
    }
}
#endif
