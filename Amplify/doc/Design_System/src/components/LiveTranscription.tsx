import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';

interface LiveTranscriptionProps {
  words: string[];
  isActive: boolean;
}

export function LiveTranscription({ words, isActive }: LiveTranscriptionProps) {
  const [displayedWords, setDisplayedWords] = useState<string[]>([]);

  useEffect(() => {
    setDisplayedWords(words);
  }, [words]);

  const getWordVariants = (index: number) => ({
    hidden: { 
      opacity: 0, 
      y: 20, 
      scale: 0.8 
    },
    visible: { 
      opacity: 1, 
      y: 0, 
      scale: 1,
      transition: {
        type: "spring",
        stiffness: 200,
        damping: 20,
        delay: index * 0.1
      }
    },
    processing: {
      opacity: 0.6,
      scale: 0.95,
      transition: {
        duration: 0.2
      }
    }
  });

  return (
    <div className="relative">
      {/* Transcription Container */}
      <div className="glass-card rounded-2xl p-4 h-full min-h-[200px] relative overflow-hidden">
        {/* Background Pattern */}
        <div className="absolute inset-0 opacity-5">
          <div className="grid grid-cols-12 gap-1 h-full">
            {[...Array(48)].map((_, i) => (
              <motion.div
                key={i}
                className="bg-gray-600 rounded"
                animate={{
                  opacity: isActive ? [0.1, 0.3, 0.1] : 0.1
                }}
                transition={{
                  duration: 2,
                  repeat: Infinity,
                  delay: i * 0.1,
                  ease: "easeInOut"
                }}
              />
            ))}
          </div>
        </div>

        {/* Content */}
        <div className="relative z-10">
          {/* Empty State */}
          {displayedWords.length === 0 && (
            <motion.div 
              className="flex items-center justify-center h-full min-h-[150px]"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            >
              <div className="text-center">
                <motion.div 
                  className="w-12 h-12 mx-auto mb-4 rounded-full bg-gradient-to-br from-gray-200 to-gray-300 flex items-center justify-center"
                  animate={isActive ? {
                    scale: [1, 1.1, 1],
                    rotate: [0, 5, -5, 0]
                  } : {}}
                  transition={{
                    duration: 2,
                    repeat: Infinity,
                    ease: "easeInOut"
                  }}
                >
                  <div className="w-4 h-4 rounded-full bg-gray-500" />
                </motion.div>
                <p className="text-sm text-gray-500">
                  {isActive ? 'Listening for your voice...' : 'Tap record to start speaking'}
                </p>
              </div>
            </motion.div>
          )}

          {/* Live Text */}
          {displayedWords.length > 0 && (
            <motion.div 
              className="space-y-2"
              layout
            >
              <div className="flex flex-wrap gap-1">
                <AnimatePresence>
                  {displayedWords.map((word, index) => (
                    <motion.span
                      key={`${word}-${index}`}
                      className={`inline-block px-2 py-1 rounded font-medium shadow-sm ${
                        index === displayedWords.length - 1 && isActive
                          ? '' // Custom styling applied via style prop
                          : 'text-gray-800'
                      }`}
                      style={{
                        backgroundColor: index === displayedWords.length - 1 && isActive 
                          ? '#68D2E8' 
                          : 'transparent',
                        color: index === displayedWords.length - 1 && isActive 
                          ? '#FFFFFF' 
                          : '#1F2937'
                      }}
                      variants={getWordVariants(index)}
                      initial="hidden"
                      animate={index === displayedWords.length - 1 && isActive ? "processing" : "visible"}
                      exit="hidden"
                      layout
                    >
                      {word}
                    </motion.span>
                  ))}
                </AnimatePresence>
                
                {/* Typing cursor */}
                {isActive && (
                  <motion.span
                    className="inline-block w-0.5 h-5 ml-1"
                    style={{ backgroundColor: '#68D2E8' }}
                    animate={{ opacity: [1, 0, 1] }}
                    transition={{
                      duration: 1,
                      repeat: Infinity,
                      ease: "easeInOut"
                    }}
                  />
                )}
              </div>
              
              {/* Word count indicator */}
              <motion.div 
                className="flex justify-between items-center mt-4 pt-2 border-t border-gray-200/50"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.5 }}
              >
                <span className="text-xs text-gray-500">
                  {displayedWords.length} word{displayedWords.length !== 1 ? 's' : ''}
                </span>
                
                {/* Confidence indicator */}
                <div className="flex items-center gap-1">
                  {[...Array(3)].map((_, i) => (
                    <motion.div
                      key={i}
                      className={`w-1 h-3 rounded-full ${
                        isActive 
                          ? i < 2 ? 'bg-green-400' : 'bg-green-300' 
                          : 'bg-gray-300'
                      }`}
                      animate={isActive ? {
                        scaleY: [1, 1.5, 1],
                        opacity: [0.6, 1, 0.6]
                      } : {}}
                      transition={{
                        duration: 1,
                        repeat: Infinity,
                        delay: i * 0.2,
                        ease: "easeInOut"
                      }}
                    />
                  ))}
                  <span className="text-xs text-gray-500 ml-1">
                    {isActive ? 'Good' : 'Ready'}
                  </span>
                </div>
              </motion.div>
            </motion.div>
          )}
        </div>
      </div>

      {/* Ambient sound waves visualization */}
      {isActive && (
        <motion.div 
          className="absolute -bottom-2 left-1/2 transform -translate-x-1/2 flex items-end gap-1"
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: 10 }}
        >
          {[...Array(5)].map((_, i) => (
            <motion.div
              key={i}
              className="w-1 rounded-full"
              style={{ backgroundColor: '#A4CCD9' }}
              animate={{
                height: [4, 12, 4],
                opacity: [0.4, 1, 0.4]
              }}
              transition={{
                duration: 1.5,
                repeat: Infinity,
                delay: i * 0.2,
                ease: "easeInOut"
              }}
            />
          ))}
        </motion.div>
      )}
    </div>
  );
}