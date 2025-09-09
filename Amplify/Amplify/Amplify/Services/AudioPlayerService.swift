//
//  AudioPlayerService.swift
//  Amplify
//
//  Audio playback service for enhanced story audio
//

import Foundation
import AVFoundation

@MainActor
class AudioPlayerService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isLoading = false
    
    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private let enhancementService: EnhancementServiceProtocol
    private var currentEnhancementId: String?
    
    // MARK: - Initialization
    
    init(enhancementService: EnhancementServiceProtocol) {
        self.enhancementService = enhancementService
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Public Methods
    
    func preloadAudio(with audioData: Data, enhancementId: String) async throws {
        print("🔵 Preloading audio with \(audioData.count) bytes for enhancement: \(enhancementId)")
        
        // Setup the audio player without playing
        try setupAudioPlayer(with: audioData)
        currentEnhancementId = enhancementId
        
        print("✅ Audio preloaded and ready for instant playback")
    }
    
    func loadAndPlay(recording: Recording) async {
        guard let enhancementId = recording.enhancementId else {
            print("🔴 No enhancement ID available for audio playback")
            return
        }
        
        // If we already have this audio loaded (either cached or preloaded), just play it
        if currentEnhancementId == enhancementId && audioPlayer != nil {
            print("✅ Using preloaded/cached audio player for enhancement: \(enhancementId)")
            play()
            return
        }
        
        print("🔵 Loading new audio for enhancement: \(enhancementId)")
        isLoading = true
        
        do {
            // Get audio data from API
            let audioData = try await enhancementService.getEnhancementAudio(
                for: recording, 
                enhancementId: enhancementId
            )
            
            // Create and configure audio player
            try setupAudioPlayer(with: audioData)
            currentEnhancementId = enhancementId
            
            // Start playback
            play()
            
        } catch {
            print("🔴 Failed to load audio: \(error)")
            isLoading = false
        }
    }
    
    func play() {
        guard let player = audioPlayer else { 
            print("🔴 No audio player available")
            return 
        }
        
        // Ensure audio session is correctly configured for playback
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Force the session to playback mode before playing
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true, options: [])
            print("🔵 Audio session forced to playback mode and activated")
        } catch {
            print("🔴 Failed to configure audio session for playback: \(error)")
            // Continue anyway since playback might still work
        }
        
        print("🔵 Starting audio playback - Duration: \(player.duration) seconds")
        let success = player.play()
        print("🔵 AVAudioPlayer.play() returned: \(success)")
        
        if !success {
            // Try to get more information about why playback failed
            print("🔴 Playback failed - Player state: isPlaying=\(player.isPlaying), currentTime=\(player.currentTime)")
            print("🔴 Audio session state: category=\(AVAudioSession.sharedInstance().category), mode=\(AVAudioSession.sharedInstance().mode)")
        }
        
        isPlaying = success
        if success {
            startTimer()
        }
        isLoading = false
    }
    
    func pause() {
        guard let player = audioPlayer else { return }
        
        player.pause()
        isPlaying = false
        stopTimer()
    }
    
    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seek(to time: Double) {
        guard let player = audioPlayer else { return }
        
        player.currentTime = time
        currentTime = time
    }
    
    func stop() {
        guard let player = audioPlayer else { return }
        
        player.stop()
        player.currentTime = 0
        currentTime = 0
        isPlaying = false
        stopTimer()
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Try playAndRecord category first, fallback to playback
            do {
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
                print("✅ Audio session configured with playAndRecord category")
            } catch {
                print("🔴 playAndRecord failed, trying playback: \(error)")
                try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth])
                print("✅ Audio session configured with playback category")
            }
            try audioSession.setActive(true)
        } catch {
            print("🔴 Failed to setup audio session: \(error)")
        }
    }
    
    private func setupAudioPlayer(with audioData: Data) throws {
        print("🔵 Setting up audio player with \(audioData.count) bytes of data")
        
        // Stop existing player
        stop()
        
        // Create new player
        audioPlayer = try AVAudioPlayer(data: audioData)
        
        guard let player = audioPlayer else {
            throw AudioPlayerError.failedToCreatePlayer
        }
        
        // Configure player
        player.delegate = self
        let prepareSuccess = player.prepareToPlay()
        print("🔵 AVAudioPlayer.prepareToPlay() returned: \(prepareSuccess)")
        
        // Update duration
        duration = player.duration
        currentTime = 0
        
        // Check if we have valid audio
        print("🔵 Audio format - Sample Rate: \(player.format.sampleRate), Channels: \(player.format.channelCount)")
        print("✅ Audio player ready - Duration: \(duration) seconds")
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            
            Task { @MainActor in
                self.currentTime = player.currentTime
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerService: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            currentTime = 0
            stopTimer()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            isPlaying = false
            isLoading = false
            stopTimer()
            
            if let error = error {
                print("🔴 Audio decode error: \(error)")
            }
        }
    }
}

// MARK: - Error Types

enum AudioPlayerError: Error, LocalizedError {
    case failedToCreatePlayer
    case noEnhancementId
    case audioDataUnavailable
    
    var errorDescription: String? {
        switch self {
        case .failedToCreatePlayer:
            return "Failed to create audio player"
        case .noEnhancementId:
            return "No enhancement ID available for audio playback"
        case .audioDataUnavailable:
            return "Audio data is not available"
        }
    }
}