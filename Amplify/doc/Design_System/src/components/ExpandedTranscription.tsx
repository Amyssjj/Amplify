import React, { useEffect, useRef, useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { X } from 'lucide-react';

interface ExpandedTranscriptionProps {
  isVisible: boolean;
  isRecording: boolean;
  displayedWords: string[];
  onClose: () => void;
  improvements?: Array<{ index: number; improved: string; reason: string }>;
  duration?: number;
  currentPlayTime?: number;
  isPlaying?: boolean;
}

export function ExpandedTranscription({
  isVisible,
  isRecording,
  displayedWords,
  onClose,
  improvements = [],
  duration = 0,
  currentPlayTime = 0,
  isPlaying = false
}: ExpandedTranscriptionProps) {
  const transcriptionContainer = useRef<HTMLDivElement>(null);
  const [isAnimating, setIsAnimating] = useState(false);

  // Auto-scroll to bottom when new words are added
  useEffect(() => {
    if (transcriptionContainer.current && displayedWords.length > 0) {
      transcriptionContainer.current.scrollTop = transcriptionContainer.current.scrollHeight;
    }
  }, [displayedWords]);

  // Handle animation state
  useEffect(() => {
    if (isVisible) {
      setIsAnimating(true);
      const timer = setTimeout(() => setIsAnimating(false), 800);
      return () => clearTimeout(timer);
    }
  }, [isVisible]);

  // iOS 16 liquid spring animation configuration
  const liquidSpring = {
    type: "spring" as const,
    stiffness: 400,
    damping: 35,
    mass: 0.8
  };

  const staggeredSpring = {
    type: "spring" as const,
    stiffness: 350,
    damping: 30,
    mass: 0.6
  };

  return (
    <AnimatePresence mode="wait">
      {isVisible && (
        <motion.div
          className="fixed inset-0 z-50"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.4, ease: "easeOut" }}
          style={{ pointerEvents: 'auto' }}
          onClick={onClose}
        >
          {/* Full Screen Content Card */}
          <motion.div
            className="w-full h-full bg-white overflow-hidden shadow-deep relative"
            initial={{ 
              scale: 0.8,
              opacity: 0
            }}
            animate={{ 
              scale: 1,
              opacity: 1
            }}
            exit={{ 
              scale: 0.8,
              opacity: 0
            }}
            transition={liquidSpring}
            onClick={(e) => e.stopPropagation()}
          >
            {/* Header */}
            <motion.div
              className="absolute top-0 left-0 right-0 bg-white border-b border-gray-200 p-4 z-10"
              initial={{ y: -100, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              exit={{ y: -100, opacity: 0 }}
              transition={{ ...staggeredSpring, delay: 0.1 }}
            >
              <div className="flex items-center justify-between">
                <motion.h2 
                  className="text-2xl font-semibold text-gradient"
                  initial={{ opacity: 0, x: -30 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -30 }}
                  transition={{ ...staggeredSpring, delay: 0.2 }}
                >
                  {isRecording ? "Live Transcription" : "Transcription"}
                </motion.h2>
                
                <motion.button
                  onClick={onClose}
                  className="bg-gray-100 p-3 rounded-full hover:bg-gray-200 transition-all"
                  initial={{ opacity: 0, scale: 0.5, rotate: -90 }}
                  animate={{ opacity: 1, scale: 1, rotate: 0 }}
                  exit={{ opacity: 0, scale: 0.5, rotate: 90 }}
                  whileHover={{ scale: 1.1, rotate: 90 }}
                  whileTap={{ scale: 0.9 }}
                  transition={{ ...staggeredSpring, delay: 0.25 }}
                >
                  <X className="w-6 h-6 text-gray-700" />
                </motion.button>
              </div>
            </motion.div>

            {/* Main Content Area */}
            <motion.div
              className="flex-1 pt-16 pb-4 px-6 overflow-hidden"
              initial={{ opacity: 0, y: 50 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 30 }}
              transition={{ ...staggeredSpring, delay: 0.15 }}
            >
              {/* Transcription Container - matching SwipeableCards exactly */}
              <div 
                ref={transcriptionContainer}
                className="h-full overflow-y-auto scrollbar-hide scroll-smooth"
              >
                {/* Content */}
                <div className="px-6 py-4 px-[0px] py-[28px]">
                  {/* Empty State */}
                  {displayedWords.length === 0 && (
                    <motion.div
                      className="flex items-center justify-center h-full"
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                    >
                      {/* Empty state - minimal */}
                    </motion.div>
                  )}

                  {/* Transcription Text */}
                  {displayedWords.length > 0 && (
                    <div className="space-y-2 pb-4">
                      {displayedWords.map((word, index) => {
                        const improvement = improvements.find(imp => imp.index === index);
                        const displayWord = improvement ? improvement.improved : word;
                        
                        // For Results screen - calculate word timing for highlighting
                        let isCurrentWord = false;
                        if (!isRecording && duration > 0) {
                          const wordStartTime = (index / displayedWords.length) * duration;
                          isCurrentWord = isPlaying && 
                                          currentPlayTime >= wordStartTime && 
                                          currentPlayTime < wordStartTime + 0.5;
                        } else if (isRecording) {
                          // For Recording screen - highlight last word
                          isCurrentWord = index === displayedWords.length - 1;
                        }
                        
                        // Match SwipeableCards styling exactly
                        return (
                          <span
                            key={`${word}-${index}`}
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
                      })}

                      {/* Typing cursor - matching RecordingInterface exactly */}
                      {isRecording && (
                        <motion.span
                          className="inline-block w-0.5 h-5 ml-1"
                          style={{ backgroundColor: '#68D2E8' }}
                          animate={{ opacity: [1, 0, 1] }}
                          transition={{
                            duration: 1,
                            repeat: Infinity,
                            ease: "easeInOut",
                          }}
                        />
                      )}
                    </div>
                  )}
                </div>
              </div>
            </motion.div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}