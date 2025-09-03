import React, { useEffect, useRef, useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { X, Lightbulb } from 'lucide-react';

interface ExpandedInsightsProps {
  isVisible: boolean;
  onClose: () => void;
  insights?: Array<{
    id: string;
    title: string;
    description: string;
    details?: string;
    suggestion?: string;
    words?: string[];
    type: 'framework' | 'vocabulary' | 'technique';
  }>;
}

// Enhanced insights with comprehensive storytelling feedback
const getComprehensiveInsights = () => [
  {
    id: 'framework-1',
    title: 'Story Framework: STAR Method',
    description: 'Situation → Task → Action → Result',
    details: 'Your story follows the STAR framework, making it compelling and easy to follow. This structure helps listeners understand the context, challenge, your response, and the outcome.',
    type: 'framework' as const
  },
  {
    id: 'highstake-1',
    title: 'High-Stake Words Used',
    words: ['breathtaking', 'extraordinary', 'remarkable', 'incredible', 'stunning'],
    description: 'These power words create emotional impact and keep listeners engaged.',
    details: 'Power words trigger emotional responses and make your story more memorable. You used 5 high-impact words that elevate the narrative beyond ordinary description.',
    type: 'vocabulary' as const
  },
  {
    id: 'improvement-1',
    title: 'Pacing Excellence',
    description: 'Great use of pauses for emphasis. Try varying tempo more in key moments.',
    suggestion: 'Add 2-second pauses before climactic moments to build anticipation',
    details: 'Your natural pacing creates rhythm and allows listeners to process important information. Consider strategic pauses for even greater impact.',
    type: 'technique' as const
  },
  {
    id: 'framework-2',
    title: 'Narrative Arc: Hero\'s Journey',
    description: 'Challenge → Struggle → Transformation → Wisdom',
    details: 'Your story contains elements of the classic hero\'s journey structure, which resonates deeply with human psychology and creates emotional connection.',
    type: 'framework' as const
  },
  {
    id: 'technique-1',
    title: 'Emotional Resonance',
    description: 'Your story creates strong emotional connection through descriptive language.',
    suggestion: 'Try adding more sensory details (sounds, textures, smells) to immerse listeners',
    details: 'Emotional resonance is achieved through vivid imagery and relatable experiences. Your descriptive language helps listeners visualize the scene.',
    type: 'technique' as const
  },
  {
    id: 'framework-3',
    title: 'Three-Act Structure',
    description: 'Setup → Confrontation → Resolution',
    details: 'Classic storytelling structure that keeps audiences engaged from start to finish. Your story naturally follows this timeless pattern.',
    type: 'framework' as const
  },
  {
    id: 'vocabulary-2',
    title: 'Vivid Imagery Score: 8.5/10',
    description: 'Strong use of descriptive language creates clear mental pictures.',
    suggestion: 'Consider adding one unexpected metaphor for memorable impact',
    details: 'Your imagery score is excellent. Listeners can easily visualize your story, which increases engagement and retention.',
    type: 'technique' as const
  },
  {
    id: 'improvement-2',
    title: 'Audience Engagement',
    description: 'Your conversational tone makes listeners feel personally connected.',
    suggestion: 'Try asking rhetorical questions to increase engagement',
    details: 'Conversational storytelling creates intimacy and makes listeners feel like they\'re part of the experience rather than passive observers.',
    type: 'technique' as const
  },
  {
    id: 'framework-4',
    title: 'Show Don\'t Tell Mastery',
    description: 'You demonstrate concepts through action rather than explanation.',
    details: 'This advanced storytelling technique makes your narrative more engaging and allows listeners to draw their own conclusions.',
    type: 'framework' as const
  },
  {
    id: 'technique-2',
    title: 'Conflict and Tension',
    description: 'Good use of subtle tension to maintain listener interest.',
    suggestion: 'Amplify the stakes slightly to create more dramatic tension',
    details: 'Even peaceful stories benefit from small conflicts or moments of uncertainty. This keeps listeners emotionally invested.',
    type: 'technique' as const
  }
];

export function ExpandedInsights({
  isVisible,
  onClose,
  insights = getComprehensiveInsights()
}: ExpandedInsightsProps) {
  const insightsContainer = useRef<HTMLDivElement>(null);
  const [isAnimating, setIsAnimating] = useState(false);

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
                  Sharp Insights
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
              {/* Insights Container - matching SwipeableCards exactly */}
              <div 
                ref={insightsContainer}
                className="h-full overflow-y-auto scrollbar-hide scroll-smooth"
              >
                {/* Content */}
                <div className="px-6 py-4">
                  {/* Empty State */}
                  {insights.length === 0 && (
                    <motion.div
                      className="flex items-center justify-center h-full"
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                    >
                      {/* Empty state - minimal */}
                    </motion.div>
                  )}

                  {/* Insights Content */}
                  {insights.length > 0 && (
                    <div className="space-y-8 pb-4">
                      {insights.map((insight, index) => (
                        <motion.div
                          key={insight.id}
                          className="py-6"
                          initial={{ opacity: 0, y: 30 }}
                          animate={{ opacity: 1, y: 0 }}
                          transition={{ delay: 0.1 + index * 0.05, duration: 0.5 }}
                        >
                          <div className="flex flex-col gap-4">
                            <div className="flex-1">
                              <motion.h3 
                                className="font-semibold text-xl mb-3 text-gray-900"
                                initial={{ opacity: 0, x: -20 }}
                                animate={{ opacity: 1, x: 0 }}
                                transition={{ delay: 0.3 + index * 0.05 }}
                              >
                                {insight.title}
                              </motion.h3>
                              
                              <motion.p 
                                className="text-gray-700 mb-4 leading-relaxed"
                                initial={{ opacity: 0, x: -20 }}
                                animate={{ opacity: 1, x: 0 }}
                                transition={{ delay: 0.4 + index * 0.05 }}
                              >
                                {insight.description}
                              </motion.p>
                              
                              {insight.type === 'vocabulary' && insight.words && (
                                <motion.div 
                                  className="flex flex-wrap gap-3 mb-4"
                                  initial={{ opacity: 0, y: 10 }}
                                  animate={{ opacity: 1, y: 0 }}
                                  transition={{ delay: 0.5 + index * 0.05 }}
                                >
                                  {insight.words.map((word, idx) => {
                                    const colors = ['#68D2E8', '#FDDE55', '#E6FF94', '#B4E380', '#B4EBE6'];
                                    const bgColor = colors[idx % colors.length];
                                    const textColor = '#1F2937'; // Dark text for better readability on all backgrounds
                                    
                                    return (
                                      <motion.span 
                                        key={idx}
                                        className="px-4 py-2 rounded-lg text-sm font-medium shadow-md"
                                        style={{
                                          backgroundColor: bgColor,
                                          color: textColor
                                        }}
                                        initial={{ scale: 0 }}
                                        animate={{ scale: 1 }}
                                        transition={{ delay: 0.6 + (index * 0.05) + (idx * 0.1), type: "spring" }}
                                        whileHover={{ scale: 1.05 }}
                                      >
                                        {word}
                                      </motion.span>
                                    );
                                  })}
                                </motion.div>
                              )}
                              
                              {insight.details && (
                                <motion.p 
                                  className="text-sm text-gray-600 leading-relaxed mb-4"
                                  initial={{ opacity: 0 }}
                                  animate={{ opacity: 1 }}
                                  transition={{ delay: 0.6 + index * 0.05 }}
                                >
                                  {insight.details}
                                </motion.p>
                              )}
                              
                              {insight.suggestion && (
                                <motion.div 
                                  className="mt-4 p-4 bg-gray-50 rounded-xl border border-gray-200"
                                  initial={{ opacity: 0, y: 10 }}
                                  animate={{ opacity: 1, y: 0 }}
                                  transition={{ delay: 0.7 + index * 0.05 }}
                                  whileHover={{ scale: 1.02 }}
                                >
                                  <p className="text-sm font-medium text-gray-700 leading-relaxed">
                                    <span className="font-semibold">Suggestion:</span> {insight.suggestion}
                                  </p>
                                </motion.div>
                              )}
                            </div>
                          </div>
                          
                          {/* Line divider - not shown for last item */}
                          {index < insights.length - 1 && (
                            <motion.div 
                              className="h-px bg-gray-200 mt-8"
                              initial={{ scaleX: 0 }}
                              animate={{ scaleX: 1 }}
                              transition={{ delay: 0.8 + index * 0.05, duration: 0.4 }}
                            />
                          )}
                        </motion.div>
                      ))}
                      
                      {/* Summary Card */}
                      <motion.div
                        className="py-8 mt-4"
                        initial={{ opacity: 0, y: 30 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: 0.1 + insights.length * 0.05, duration: 0.6 }}
                      >
                        <motion.div 
                          className="h-px bg-gray-200 mb-8"
                          initial={{ scaleX: 0 }}
                          animate={{ scaleX: 1 }}
                          transition={{ delay: 0.15 + insights.length * 0.05, duration: 0.4 }}
                        />
                        <div className="flex flex-col gap-4">
                          <div className="flex-1">
                            <h3 className="font-semibold text-xl mb-4 text-gray-900">Overall Assessment</h3>
                            <p className="text-gray-700 leading-relaxed">
                              Your storytelling demonstrates strong fundamentals with excellent use of descriptive language and natural pacing. You're effectively using proven narrative frameworks while maintaining authenticity. Keep practicing with different story types to further develop your communication skills.
                            </p>
                          </div>
                        </div>
                      </motion.div>
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