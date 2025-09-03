import React, { useState } from 'react';
import { HomeScreen } from './components/screens/HomeScreen';
import { RecordingScreen } from './components/screens/RecordingScreen';
import { ProcessingScreen } from './components/screens/ProcessingScreen';
import { ResultsScreen } from './components/screens/ResultsScreen';
import { ExpandedTranscription } from './components/modals/ExpandedTranscription';
import { ExpandedInsights } from './components/modals/ExpandedInsights';

export type AppState = 'home' | 'recording' | 'processing' | 'results';

export interface Recording {
  id: string;
  photoUrl: string;
  transcript: string;
  audioData?: string;
  insights: Array<{
    id: string;
    icon: string;
    title: string;
    description: string;
  }>;
  duration: number;
}

// Mock sample photos for demonstration
const SAMPLE_PHOTOS = [
  "https://images.unsplash.com/photo-1629161156834-67f7a989ca67?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxiZWF1dGlmdWwlMjBzdW5zZXQlMjBsYW5kc2NhcGV8ZW58MXx8fHwxNzU2NzM3MDg3fDA&ixlib=rb-4.1.0&q=80&w=1080",
  "https://images.unsplash.com/photo-1609836964884-99e9b93230e0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxvY2VhbiUyMHdhdmVzJTIwbmF0dXJlfGVufDF8fHx8MTc1NjgwMTk5OXww&ixlib=rb-4.1.0&q=80&w=1080",
  "https://images.unsplash.com/photo-1708597700275-407e0d786c2f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtb3VudGFpbiUyMGZvcmVzdCUyMHBlYWNlZnVsfGVufDF8fHx8MTc1NjgzNTE1NHww&ixlib=rb-4.1.0&q=80&w=1080"
];

export default function App() {
  const [currentState, setCurrentState] = useState<AppState>('home');
  const [currentPhoto, setCurrentPhoto] = useState(SAMPLE_PHOTOS[0]);
  const [currentRecording, setCurrentRecording] = useState<Recording | null>(null);
  const [isTranscriptExpanded, setIsTranscriptExpanded] = useState(false);
  const [isInsightsExpanded, setIsInsightsExpanded] = useState(false);
  const [currentPlayTime, setCurrentPlayTime] = useState(0);
  const [isPlaying, setIsPlaying] = useState(false);

  const handleStartRecording = () => {
    setCurrentState('recording');
  };

  const handleFinishRecording = (transcript: string, duration: number) => {
    setCurrentState('processing');
    
    // Simulate AI processing delay
    setTimeout(() => {
      const recording: Recording = {
        id: Date.now().toString(),
        photoUrl: currentPhoto,
        transcript: transcript || "This is a nice view of the mountain. The thing about nature is that it's really good for the soul. I can see the beautiful landscape stretching out before me, and it makes me feel peaceful and grateful for this moment.",
        duration,
        insights: [
          {
            id: '1',
            icon: '🎯',
            title: 'Clear Purpose',
            description: 'Your story had a strong central theme that kept listeners engaged.'
          },
          {
            id: '2',
            icon: '🌊',
            title: 'Natural Flow',
            description: 'Great use of transitional phrases to connect your ideas smoothly.'
          },
          {
            id: '3',
            icon: '✨',
            title: 'Vivid Details',
            description: 'Your descriptive language helped paint a clear picture for the audience.'
          },
          {
            id: '4',
            icon: '🚀',
            title: 'Room to Grow',
            description: 'Try varying your pace more to add emphasis to key moments.'
          }
        ]
      };
      
      setCurrentRecording(recording);
      setCurrentState('results');
    }, 3000);
  };

  const handleNewPhoto = () => {
    const randomIndex = Math.floor(Math.random() * SAMPLE_PHOTOS.length);
    setCurrentPhoto(SAMPLE_PHOTOS[randomIndex]);
  };

  const handleBackToHome = () => {
    setCurrentState('home');
    setCurrentRecording(null);
    setIsTranscriptExpanded(false);
    setIsInsightsExpanded(false);
    setCurrentPlayTime(0);
    setIsPlaying(false);
  };

  // Mock AI polished transcript function
  const getPolishedTranscript = (originalTranscript: string) => {
    const words = originalTranscript.split(' ');
    const improvements = [
      { index: 2, original: 'nice', improved: 'breathtaking', reason: 'More vivid imagery' },
      { index: 8, original: 'thing', improved: 'phenomenon', reason: 'Precise terminology' },
      { index: 15, original: 'really', improved: 'remarkably', reason: 'Stronger emphasis' },
      { index: 22, original: 'good', improved: 'extraordinary', reason: 'More impactful' }
    ];
    
    return { words, improvements };
  };

  // Full screen recording mode
  if (currentState === 'recording') {
    return (
      <div className="h-screen w-full bg-gradient-to-br from-white to-gray-50 overflow-hidden">
        <RecordingScreen 
          currentPhoto={currentPhoto}
          onFinishRecording={handleFinishRecording}
          onBack={handleBackToHome}
        />
      </div>
    );
  }

  return (
    <div className="h-screen w-full bg-gradient-to-br from-white to-gray-50 overflow-hidden relative">
      {/* iOS Status Bar Simulation */}
      <div className="absolute top-0 left-0 right-0 h-12 z-50 flex items-center justify-between px-6 text-black">
        <div className="flex items-center gap-1">
          <div className="text-sm font-medium">9:41</div>
        </div>
        <div className="flex items-center gap-1">
          <div className="w-4 h-2 bg-black rounded-sm"></div>
          <div className="w-6 h-3 border border-black rounded-sm">
            <div className="w-4 h-1 bg-black rounded-xs m-0.5"></div>
          </div>
        </div>
      </div>

      {/* App Content */}
      <div className="pt-12 h-full">
        {currentState === 'home' && (
          <HomeScreen 
            currentPhoto={currentPhoto}
            onStartRecording={handleStartRecording}
            onNewPhoto={handleNewPhoto}
          />
        )}
        
        {currentState === 'processing' && (
          <ProcessingScreen />
        )}
        
        {currentState === 'results' && currentRecording && (
          <ResultsScreen 
            recording={currentRecording}
            onBackToHome={handleBackToHome}
            currentPlayTime={currentPlayTime}
            isPlaying={isPlaying}
            onPlayTimeUpdate={setCurrentPlayTime}
            onPlayingChange={setIsPlaying}
            onTranscriptExpand={() => setIsTranscriptExpanded(true)}
            onInsightsExpand={() => setIsInsightsExpanded(true)}
          />
        )}
      </div>

      {/* App-level ExpandedTranscription - Overlays everything */}
      {currentState === 'results' && currentRecording && (
        <ExpandedTranscription
          isVisible={isTranscriptExpanded}
          isRecording={false}
          displayedWords={getPolishedTranscript(currentRecording.transcript).words}
          improvements={getPolishedTranscript(currentRecording.transcript).improvements}
          duration={currentRecording.duration}
          currentPlayTime={currentPlayTime}
          isPlaying={isPlaying}
          onClose={() => setIsTranscriptExpanded(false)}
        />
      )}

      {/* App-level ExpandedInsights - Overlays everything */}
      {currentState === 'results' && currentRecording && (
        <ExpandedInsights
          isVisible={isInsightsExpanded}
          onClose={() => setIsInsightsExpanded(false)}
        />
      )}
    </div>
  );
}