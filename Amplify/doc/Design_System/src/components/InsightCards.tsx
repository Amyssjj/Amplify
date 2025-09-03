import React from 'react';
import { motion } from 'motion/react';

interface Insight {
  id: string;
  icon: string;
  title: string;
  description: string;
}

interface InsightCardsProps {
  insights: Insight[];
}

export function InsightCards({ insights }: InsightCardsProps) {
  const cardVariants = {
    hidden: { 
      opacity: 0, 
      y: 30, 
      scale: 0.9,
      rotateX: 15 
    },
    visible: (index: number) => ({
      opacity: 1,
      y: 0,
      scale: 1,
      rotateX: 0,
      transition: {
        type: "spring",
        stiffness: 100,
        damping: 15,
        delay: index * 0.1,
        duration: 0.6
      }
    }),
    hover: {
      scale: 1.02,
      y: -5,
      rotateX: -2,
      transition: {
        type: "spring",
        stiffness: 400,
        damping: 25
      }
    }
  };

  const getInsightColor = (index: number) => {
    const colors = [
      'from-blue-100/60 to-blue-200/40 border-blue-200/50',
      'from-green-100/60 to-green-200/40 border-green-200/50',
      'from-purple-100/60 to-purple-200/40 border-purple-200/50',
      'from-orange-100/60 to-orange-200/40 border-orange-200/50'
    ];
    return colors[index % colors.length];
  };

  const getIconBgColor = (index: number) => {
    const colors = [
      'bg-blue-200/60',
      'bg-green-200/60',
      'bg-purple-200/60',
      'bg-orange-200/60'
    ];
    return colors[index % colors.length];
  };

  return (
    <div className="space-y-4">
      {insights.map((insight, index) => (
        <motion.div
          key={insight.id}
          className={`glass-card rounded-2xl p-6 shadow-float bg-gradient-to-br ${getInsightColor(index)} border`}
          variants={cardVariants}
          custom={index}
          initial="hidden"
          animate="visible"
          whileHover="hover"
          style={{ perspective: 1000 }}
        >
          <div className="flex items-start gap-4">
            {/* Icon */}
            <motion.div 
              className={`flex-shrink-0 w-12 h-12 ${getIconBgColor(index)} rounded-xl flex items-center justify-center shadow-sm`}
              whileHover={{ 
                scale: 1.1, 
                rotate: 5,
                transition: { type: "spring", stiffness: 300, damping: 20 }
              }}
            >
              <span className="text-xl">{insight.icon}</span>
            </motion.div>

            {/* Content */}
            <div className="flex-1 min-w-0">
              <motion.h4 
                className="font-semibold text-gray-800 mb-2"
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.1 + 0.2, duration: 0.5 }}
              >
                {insight.title}
              </motion.h4>
              
              <motion.p 
                className="text-gray-600 text-sm leading-relaxed"
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.1 + 0.3, duration: 0.5 }}
              >
                {insight.description}
              </motion.p>
            </div>

            {/* Decorative Element */}
            <motion.div 
              className="flex-shrink-0 w-6 h-6 rounded-full bg-gradient-to-br from-white/60 to-white/20 border border-white/40"
              animate={{
                rotate: [0, 180, 360],
                scale: [1, 1.1, 1]
              }}
              transition={{
                duration: 8,
                repeat: Infinity,
                ease: "linear"
              }}
            >
              <div className="w-full h-full rounded-full bg-gradient-to-br from-transparent via-white/30 to-transparent" />
            </motion.div>
          </div>

          {/* Progress Bar for Insight Strength */}
          <motion.div 
            className="mt-4 pt-4 border-t border-white/20"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: index * 0.1 + 0.5, duration: 0.5 }}
          >
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs text-gray-500 font-medium">Insight Strength</span>
              <span className="text-xs text-gray-600 font-medium">
                {index === 0 ? 'Excellent' : index === 1 ? 'Very Good' : index === 2 ? 'Good' : 'Potential'}
              </span>
            </div>
            
            <div className="h-1.5 bg-white/40 rounded-full overflow-hidden">
              <motion.div 
                className={`h-full rounded-full ${
                  index === 0 ? 'bg-green-400' : 
                  index === 1 ? 'bg-blue-400' : 
                  index === 2 ? 'bg-purple-400' : 'bg-orange-400'
                }`}
                initial={{ width: 0 }}
                animate={{ 
                  width: `${90 - (index * 15)}%`,
                  boxShadow: `0 0 8px ${
                    index === 0 ? 'rgba(34, 197, 94, 0.4)' : 
                    index === 1 ? 'rgba(59, 130, 246, 0.4)' : 
                    index === 2 ? 'rgba(168, 85, 247, 0.4)' : 'rgba(251, 146, 60, 0.4)'
                  }`
                }}
                transition={{ 
                  delay: index * 0.1 + 0.7, 
                  duration: 1, 
                  ease: "easeOut" 
                }}
              />
            </div>
          </motion.div>

          {/* Hover Glow Effect */}
          <motion.div 
            className="absolute inset-0 rounded-2xl opacity-0 bg-gradient-to-br from-white/20 via-transparent to-transparent pointer-events-none"
            whileHover={{ opacity: 1 }}
            transition={{ duration: 0.3 }}
          />
        </motion.div>
      ))}

      {/* Summary Card */}
      <motion.div
        className="glass-card rounded-2xl p-6 shadow-float bg-gradient-to-br from-gray-50/80 to-white/60 border border-gray-200/50 mt-6"
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: insights.length * 0.1 + 0.5, duration: 0.6 }}
      >
        <div className="text-center">
          <motion.div 
            className="w-12 h-12 mx-auto mb-4 bg-gradient-to-br from-blue-100 to-purple-100 rounded-xl flex items-center justify-center"
            animate={{
              rotate: [0, 5, -5, 0],
              scale: [1, 1.05, 1]
            }}
            transition={{
              duration: 4,
              repeat: Infinity,
              ease: "easeInOut"
            }}
          >
            <span className="text-2xl">✨</span>
          </motion.div>
          
          <h4 className="font-semibold text-gray-800 mb-2">Keep Practicing!</h4>
          <p className="text-sm text-gray-600 leading-relaxed">
            Every story you tell helps you grow as a communicator. 
            Try another photo to continue building your skills.
          </p>
        </div>
      </motion.div>
    </div>
  );
}