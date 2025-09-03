import React, { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { Play, Pause } from 'lucide-react';

interface MiniMediaPlayerProps {
  duration: number;
  currentTime: number;
  isPlaying: boolean;
  onPlayPause: () => void;
  onTimeUpdate: (time: number) => void;
}

export function MiniMediaPlayer({ 
  duration, 
  currentTime, 
  isPlaying, 
  onPlayPause, 
  onTimeUpdate 
}: MiniMediaPlayerProps) {
  const [isDragging, setIsDragging] = useState(false);

  // Simulate playback progress
  useEffect(() => {
    if (isPlaying && !isDragging) {
      const interval = setInterval(() => {
        onTimeUpdate(prev => Math.min(prev + 1, duration));
      }, 1000);

      return () => clearInterval(interval);
    }
  }, [isPlaying, isDragging, duration, onTimeUpdate]);

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const progressPercentage = (currentTime / duration) * 100;

  const handleSeek = (event: React.PointerEvent<HTMLDivElement>) => {
    const rect = event.currentTarget.getBoundingClientRect();
    const clickX = event.clientX - rect.left;
    const percentage = (clickX / rect.width) * 100;
    const newTime = Math.floor((percentage / 100) * duration);
    
    onTimeUpdate(newTime);
  };

  return (
    <motion.div 
      className="w-full p-4"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay: 0.2 }}
    >
      {/* Glass Container */}
      <div className="glass-card rounded-2xl p-4 shadow-lg">
        {/* Controls Row */}
        <div className="flex items-center gap-4">
          {/* Play/Pause Button */}
          <motion.button
            className="flex-shrink-0 glass-button p-3 rounded-full shadow-md"
            onClick={onPlayPause}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            animate={{
              backgroundColor: isPlaying ? "rgba(255, 255, 255, 0.7)" : "rgba(255, 255, 255, 0.5)"
            }}
            transition={{ type: "spring", stiffness: 400, damping: 25 }}
          >
            <motion.div
              initial={false}
              animate={{ 
                scale: isPlaying ? 1 : 1,
                rotate: isPlaying ? 0 : 0
              }}
              transition={{ 
                type: "spring", 
                stiffness: 300, 
                damping: 30,
                duration: 0.2
              }}
            >
              {isPlaying ? (
                <Pause className="w-5 h-5 text-gray-700" />
              ) : (
                <Play className="w-5 h-5 text-gray-700 ml-0.5" />
              )}
            </motion.div>
          </motion.button>

          {/* Progress Section */}
          <div className="flex-1 space-y-2">
            {/* Progress Bar */}
            <div 
              className="relative h-1.5 bg-white/40 rounded-full cursor-pointer group"
              onPointerDown={handleSeek}
            >
              {/* Background Track */}
              <div className="absolute inset-0 rounded-full bg-gray-300/40" />
              
              {/* Progress Fill */}
              <motion.div 
                className="absolute left-0 top-0 h-full bg-gradient-to-r from-blue-400 to-blue-500 rounded-full"
                style={{ width: `${progressPercentage}%` }}
                animate={{
                  opacity: isPlaying ? 1 : 0.8
                }}
                transition={{ duration: 0.3, ease: "easeOut" }}
              />
              
              {/* Progress Thumb */}
              <motion.div 
                className="absolute top-1/2 transform -translate-y-1/2 w-3 h-3 bg-white rounded-full shadow-md border border-blue-400/50 opacity-0 group-hover:opacity-100"
                style={{ left: `calc(${progressPercentage}% - 6px)` }}
                whileHover={{ scale: 1.2 }}
                transition={{ 
                  type: "spring", 
                  stiffness: 400, 
                  damping: 25,
                  opacity: { duration: 0.2 }
                }}
              />
            </div>

            {/* Time Display */}
            <div className="flex justify-between items-center">
              <span className="text-xs text-white/90 font-medium">
                {formatTime(currentTime)}
              </span>
              
              <span className="text-xs text-white/70">
                {formatTime(duration)}
              </span>
            </div>
          </div>

          {/* Status Indicator */}
          <motion.div 
            className={`flex-shrink-0 w-2 h-2 rounded-full transition-colors duration-300 ${
              isPlaying ? 'bg-green-400' : 'bg-gray-400'
            }`}
            animate={isPlaying ? {
              scale: [1, 1.2, 1],
              opacity: [0.8, 1, 0.8]
            } : {
              scale: 1,
              opacity: 0.6
            }}
            transition={{
              duration: 2,
              repeat: isPlaying ? Infinity : 0,
              ease: "easeInOut"
            }}
          />
        </div>
      </div>

      {/* Subtle Ambient Glow */}
      {isPlaying && (
        <motion.div 
          className="absolute -inset-2 pointer-events-none rounded-2xl"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.4, ease: "easeOut" }}
        >
          <motion.div
            className="w-full h-full bg-gradient-to-r from-blue-400/10 via-blue-500/20 to-blue-400/10 rounded-2xl"
            animate={{
              opacity: [0.3, 0.6, 0.3]
            }}
            transition={{
              duration: 3,
              repeat: Infinity,
              ease: "easeInOut"
            }}
          />
        </motion.div>
      )}
    </motion.div>
  );
}