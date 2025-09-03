import React, { useState, memo, useMemo, useCallback } from 'react';
import { motion, AnimatePresence, PanInfo } from 'motion/react';
import { Lightbulb, FileText } from 'lucide-react';
import type { Recording } from '../../App';

interface SwipeableCardsProps {
  recording: Recording;
  currentPlayTime: number;
  isPlaying: boolean;
  onTranscriptExpand: () => void;
  onInsightsExpand: () => void;
}

// Mock AI polished transcript with improvements
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

// Enhanced insights with frameworks and high-stake words
const getEnhancedInsights = () => [
  {
    id: 'framework-1',
    title: 'Story Framework: STAR Method',
    description: 'Situation → Task → Action → Result',
    details: 'Your story follows the STAR framework, making it compelling and easy to follow.',
    type: 'framework'
  },
  {
    id: 'highstake-1',
    title: 'High-Stake Words Used',
    words: ['breathtaking', 'extraordinary', 'remarkable'],
    description: 'These power words create emotional impact and keep listeners engaged.',
    type: 'vocabulary'
  },
  {
    id: 'improvement-1',
    title: 'Pacing Excellence',
    description: 'Great use of pauses for emphasis. Try varying tempo more in key moments.',
    suggestion: 'Add 2-second pauses before climactic moments',
    type: 'technique'
  },
  {
    id: 'framework-2',
    title: 'Narrative Arc: Hero\'s Journey',
    description: 'Challenge → Struggle → Transformation → Wisdom',
    details: 'Your story contains elements of the classic hero\'s journey structure.',
    type: 'framework'
  },
  {
    id: 'technique-1',
    title: 'Emotional Resonance',
    description: 'Your story creates strong emotional connection through descriptive language.',
    suggestion: 'Try adding more sensory details (sounds, textures, smells)',
    type: 'technique'
  },
  {
    id: 'framework-3',
    title: 'Three-Act Structure',
    description: 'Setup → Confrontation → Resolution',
    details: 'Classic storytelling structure that keeps audiences engaged from start to finish.',
    type: 'framework'
  },
  {
    id: 'vocabulary-2',
    title: 'Vivid Imagery Score: 8.5/10',
    description: 'Strong use of descriptive language creates clear mental pictures.',
    suggestion: 'Consider adding one unexpected metaphor for memorable impact',
    type: 'technique'
  },
  {
    id: 'improvement-2',
    title: 'Audience Engagement',
    description: 'Your conversational tone makes listeners feel personally connected.',
    suggestion: 'Try asking rhetorical questions to increase engagement',
    type: 'technique'
  }
];

// Memoized word component to prevent unnecessary re-renders
const TranscriptWord = memo(({ 
  word, 
  index, 
  improvement, 
  isCurrentWord, 
  animationDelay = 0.6 
}: {
  word: string;
  index: number;
  improvement?: { improved: string; index: number };
  isCurrentWord: boolean;
  animationDelay?: number;
}) => {
  const displayWord = improvement ? improvement.improved : word;
  
  return (
    <span
      className={`inline-block mr-1 px-1 py-0.5 rounded transition-colors duration-200 ${
        isCurrentWord
          ? 'shadow-sm font-medium'
          : improvement
          ? 'font-medium shadow-sm'
          : 'text-gray-800'
      }`}
      style={{
        backgroundColor: isCurrentWord 
          ? '#68D2E8' 
          : improvement 
          ? '#E6FF94'
          : 'transparent',
        color: isCurrentWord 
          ? '#FFFFFF'
          : improvement
          ? '#1F2937'
          : '#1F2937'
      }}
    >
      {displayWord}
    </span>
  );
});

TranscriptWord.displayName = 'TranscriptWord';

// Memoized transcript content to prevent re-renders
const TranscriptContent = memo(({ 
  words, 
  improvements, 
  duration, 
  currentPlayTime, 
  isPlaying,
  animationDelay 
}: {
  words: string[];
  improvements: Array<{ index: number; improved: string }>;
  duration: number;
  currentPlayTime: number;
  isPlaying: boolean;
  animationDelay: number;
}) => {
  // Memoize word calculations to prevent recalculation on every render
  const wordData = useMemo(() => {
    return words.map((word, index) => {
      const improvement = improvements.find(imp => imp.index === index);
      const wordStartTime = (index / words.length) * duration;
      return {
        word,
        index,
        improvement,
        wordStartTime
      };
    });
  }, [words, improvements, duration]);

  return (
    <div className="space-y-2 pb-4">
      {wordData.map(({ word, index, improvement, wordStartTime }) => {
        const isCurrentWord = isPlaying && 
                             currentPlayTime >= wordStartTime && 
                             currentPlayTime < wordStartTime + 0.5;
        
        return (
          <TranscriptWord
            key={index}
            word={word}
            index={index}
            improvement={improvement}
            isCurrentWord={isCurrentWord}
            animationDelay={animationDelay}
          />
        );
      })}
    </div>
  );
});

TranscriptContent.displayName = 'TranscriptContent';

// Memoized InsightsCard component to prevent re-renders during playback
const InsightsCard = memo(({ 
  enhancedInsights, 
  onInsightsClick 
}: {
  enhancedInsights: any[];
  onInsightsClick: () => void;
}) => {
  // Static content that doesn't change - no need for motion animations on every render
  return (
    <div 
      className="glass-card rounded-2xl p-6 flex-1 flex flex-col cursor-pointer hover:shadow-lg transition-all duration-200"
      onClick={onInsightsClick}
    >
      <div className="flex items-center gap-2 mb-4">
        <Lightbulb className="w-5 h-5 text-gray-600" />
        <h3 className="text-lg font-semibold text-gradient">Sharp Insights</h3>
      </div>

      <div className="flex-1 overflow-y-auto scrollbar-hide scroll-smooth">
        <div className="space-y-6 pb-4">
          {enhancedInsights.map((insight, index) => (
            <div
              key={insight.id}
              className="py-4"
            >
              <div className="flex flex-col gap-3">
                <div className="flex-1">
                  <h4 className="font-semibold mb-2 text-gray-900">{insight.title}</h4>
                  <p className="text-sm text-gray-700 mb-2 leading-relaxed">{insight.description}</p>
                  
                  {insight.type === 'vocabulary' && insight.words && (
                    <div className="flex flex-wrap gap-2 mt-2">
                      {insight.words.map((word, idx) => {
                        const colors = ['#68D2E8', '#FDDE55', '#E6FF94', '#B4E380', '#B4EBE6'];
                        const bgColor = colors[idx % colors.length];
                        const textColor = '#1F2937'; // Dark text for better readability on all backgrounds
                        
                        return (
                          <span 
                            key={idx}
                            className="px-2 py-1 rounded text-xs font-medium shadow-sm"
                            style={{
                              backgroundColor: bgColor,
                              color: textColor
                            }}
                          >
                            {word}
                          </span>
                        );
                      })}
                    </div>
                  )}
                  
                  {insight.details && (
                    <p className="text-xs text-gray-600 mt-2 leading-relaxed">
                      {insight.details}
                    </p>
                  )}
                  
                  {insight.suggestion && (
                    <div className="mt-2 p-2 bg-gray-50 rounded text-xs font-medium text-gray-700 border border-gray-200">
                      Suggestion: {insight.suggestion}
                    </div>
                  )}
                </div>
              </div>
              
              {/* Line divider - not shown for last item */}
              {index < enhancedInsights.length - 1 && (
                <div className="h-px bg-gray-200 mt-6" />
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
});

InsightsCard.displayName = 'InsightsCard';

// Memoized TranscriptCard component to prevent re-renders during playback
const TranscriptCard = memo(({ 
  polishedData,
  recording,
  currentPlayTime,
  isPlaying,
  onTranscriptClick
}: {
  polishedData: { words: string[]; improvements: Array<{ index: number; improved: string }> };
  recording: Recording;
  currentPlayTime: number;
  isPlaying: boolean;
  onTranscriptClick: () => void;
}) => (
  <div 
    className="glass-card rounded-2xl p-6 flex-1 flex flex-col cursor-pointer hover:shadow-lg transition-all duration-200"
    onClick={onTranscriptClick}
  >
    <div className="flex items-center gap-2 mb-4">
      <FileText className="w-5 h-5 text-gray-600" />
      <h3 className="text-lg font-semibold text-gradient">Transcription</h3>
    </div>

    <div className="flex-1 overflow-y-auto scrollbar-hide scroll-smooth">
      <TranscriptContent
        words={polishedData.words}
        improvements={polishedData.improvements}
        duration={recording.duration}
        currentPlayTime={currentPlayTime}
        isPlaying={isPlaying}
        animationDelay={0.6}
      />
    </div>
  </div>
));

TranscriptCard.displayName = 'TranscriptCard';

export function SwipeableCards({ recording, currentPlayTime, isPlaying, onTranscriptExpand, onInsightsExpand }: SwipeableCardsProps) {
  const [currentCard, setCurrentCard] = useState<'transcript' | 'insights'>('transcript');

  // Memoize expensive calculations
  const polishedData = useMemo(() => getPolishedTranscript(recording.transcript), [recording.transcript]);
  const enhancedInsights = useMemo(() => getEnhancedInsights(), []);

  // Memoize callback functions to prevent unnecessary re-renders
  const handleDragEnd = useCallback((event: any, info: PanInfo) => {
    const threshold = 100;
    
    if (info.offset.x > threshold) {
      // Swipe right - go to insights
      setCurrentCard('insights');
    } else if (info.offset.x < -threshold) {
      // Swipe left - go to transcript
      setCurrentCard('transcript');
    }
  }, []);

  const handleTranscriptClick = useCallback(() => {
    if (currentCard === 'transcript') {
      onTranscriptExpand();
    }
  }, [currentCard, onTranscriptExpand]);

  const handleInsightsClick = useCallback(() => {
    if (currentCard === 'insights') {
      onInsightsExpand();
    }
  }, [currentCard, onInsightsExpand]);

  return (
    <div className="flex-1 overflow-hidden px-6 pb-6">
      <motion.div
        className="h-full flex flex-col"
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.4, duration: 0.6 }}
      >
        {/* iOS-style Page Indicator Dots */}
        <div className="flex justify-center mb-6">
          <motion.div 
            className="flex items-center gap-2 glass-card px-4 py-2 rounded-full"
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.5, duration: 0.4 }}
          >
            <motion.button
              className={`w-2 h-2 rounded-full transition-all duration-300 ${
                currentCard === 'transcript'
                  ? 'bg-gray-800 scale-125'
                  : 'bg-gray-300'
              }`}
              onClick={() => setCurrentCard('transcript')}
              whileHover={{ scale: 1.3 }}
              whileTap={{ scale: 0.9 }}
            />
            <motion.button
              className={`w-2 h-2 rounded-full transition-all duration-300 ${
                currentCard === 'insights'
                  ? 'bg-gray-800 scale-125'
                  : 'bg-gray-300'
              }`}
              onClick={() => setCurrentCard('insights')}
              whileHover={{ scale: 1.3 }}
              whileTap={{ scale: 0.9 }}
            />
          </motion.div>
        </div>

        {/* Swipeable Card */}
        <motion.div
          className="flex-1 flex flex-col"
          drag="x"
          dragConstraints={{ left: 0, right: 0 }}
          onDragEnd={handleDragEnd}
          dragElastic={0.2}
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.6, duration: 0.6 }}
        >
          <AnimatePresence mode="wait">
            <motion.div
              key={currentCard}
              className="flex-1 flex flex-col"
              initial={{ opacity: 0, x: currentCard === 'insights' ? 100 : -100 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: currentCard === 'insights' ? -100 : 100 }}
              transition={{ 
                type: "spring", 
                stiffness: 300, 
                damping: 30,
                duration: 0.4
              }}
            >
              {currentCard === 'transcript' ? (
                <TranscriptCard 
                  key="static-transcript-card"
                  polishedData={polishedData}
                  recording={recording}
                  currentPlayTime={currentPlayTime}
                  isPlaying={isPlaying}
                  onTranscriptClick={handleTranscriptClick}
                />
              ) : (
                <InsightsCard 
                  key="static-insights-card"
                  enhancedInsights={enhancedInsights}
                  onInsightsClick={handleInsightsClick}
                />
              )}
            </motion.div>
          </AnimatePresence>
        </motion.div>
      </motion.div>
    </div>
  );
}