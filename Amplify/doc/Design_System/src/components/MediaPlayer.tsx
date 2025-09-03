import React, { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { Play, Pause, SkipBack, SkipForward } from 'lucide-react';

interface MediaPlayerProps {
  duration: number;
  currentTime: number;
  isPlaying: boolean;
  onPlayPause: () => void;
  onTimeUpdate: (time: number) => void;
}

export function MediaPlayer({ 
  duration, 
  currentTime, 
  isPlaying, 
  onPlayPause, 
  onTimeUpdate 
}: MediaPlayerProps) {
  const [isDragging, setIsDragging] = useState(false);
  const [dragTime, setDragTime] = useState(0);

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

  const progressPercentage = ((isDragging ? dragTime : currentTime) / duration) * 100;

  const handleSeek = (event: React.PointerEvent<HTMLDivElement>) => {
    const rect = event.currentTarget.getBoundingClientRect();
    const clickX = event.clientX - rect.left;
    const percentage = (clickX / rect.width) * 100;
    const newTime = Math.floor((percentage / 100) * duration);
    
    onTimeUpdate(newTime);
  };

  return (
    <motion.div 
      className="w-full max-w-sm"
      initial={{ scale: 0.95, opacity: 0, y: 10 }}
      animate={{ scale: 1, opacity: 1, y: 0 }}
      transition={{ 
        duration: 0.8, 
        type: "spring", 
        stiffness: 100,
        damping: 25
      }}
    >
      {/* Main Controls Container */}
      <div className="backdrop-blur-lg bg-white/50 border border-white/30 rounded-2xl p-6 shadow-lg">
        {/* Control Buttons */}
        <div className="flex items-center justify-center gap-6 mb-6">
          {/* Skip Back Button */}
          <motion.button
            className="backdrop-blur-md bg-white/40 border border-white/40 p-3 rounded-full shadow-md hover:bg-white/60"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            transition={{ type: "spring", stiffness: 400, damping: 25 }}
            onClick={() => onTimeUpdate(Math.max(0, currentTime - 10))}
          >
            <SkipBack className="w-4 h-4 text-gray-700" />
          </motion.button>

          {/* Play/Pause Button */}
          <motion.button
            className="backdrop-blur-md bg-white/60 border border-white/50 p-4 rounded-full shadow-md"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={onPlayPause}
            transition={{ type: "spring", stiffness: 400, damping: 25 }}
            animate={{
              boxShadow: isPlaying 
                ? "0 4px 20px rgba(59, 130, 246, 0.25)" 
                : "0 4px 12px rgba(0, 0, 0, 0.08)",
              backgroundColor: isPlaying ? "rgba(255, 255, 255, 0.7)" : "rgba(255, 255, 255, 0.6)"
            }}
          >
            <motion.div
              initial={false}
              animate={{ 
                scale: isPlaying ? 1 : 1,
                opacity: 1
              }}
              transition={{ 
                type: "spring", 
                stiffness: 300, 
                damping: 30,
                duration: 0.3
              }}
            >
              {isPlaying ? (
                <Pause className="w-6 h-6 text-gray-700" />
              ) : (
                <Play className="w-6 h-6 text-gray-700 ml-0.5" />
              )}
            </motion.div>
          </motion.button>

          {/* Skip Forward Button */}
          <motion.button
            className="backdrop-blur-md bg-white/40 border border-white/40 p-3 rounded-full shadow-md hover:bg-white/60"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            transition={{ type: "spring", stiffness: 400, damping: 25 }}
            onClick={() => onTimeUpdate(Math.min(duration, currentTime + 10))}
          >
            <SkipForward className="w-4 h-4 text-gray-700" />
          </motion.button>
        </div>

        {/* Progress Bar */}
        <div className="space-y-3">
          {/* Progress Track */}
          <div 
            className="relative h-2 bg-white/40 rounded-full cursor-pointer group"
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
              whileHover={{ scale: 1.3 }}
              transition={{ 
                type: "spring", 
                stiffness: 400, 
                damping: 25,
                opacity: { duration: 0.2 }
              }}
            />
          </div>

          {/* Time Display */}
          <div className="flex justify-between items-center text-sm">
            <span className="text-gray-600 font-medium">
              {formatTime(currentTime)}
            </span>
            
            <span className="text-gray-500">
              {formatTime(duration)}
            </span>
          </div>
        </div>

        {/* Playback Status */}
        <motion.div 
          className="flex items-center justify-center mt-4"
          initial={{ opacity: 0, y: 5 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4, duration: 0.5, ease: "easeOut" }}
        >
          <div className="flex items-center gap-2">
            {/* Status Indicator */}
            <motion.div 
              className={`w-2 h-2 rounded-full transition-colors duration-300 ${
                isPlaying ? 'bg-green-400' : 'bg-gray-400'
              }`}
              animate={isPlaying ? {
                scale: [1, 1.1, 1],
                opacity: [0.9, 1, 0.9]
              } : {
                scale: 1,
                opacity: 0.7
              }}
              transition={{
                duration: 2,
                repeat: isPlaying ? Infinity : 0,
                ease: "easeInOut"
              }}
            />
            
            <motion.span 
              className="text-xs text-gray-600 font-medium"
              animate={{ opacity: 1 }}
              transition={{ duration: 0.3 }}
            >
              {isPlaying ? 'Playing' : 'Paused'}
            </motion.span>
          </div>
        </motion.div>
      </div>

      {/* Subtle Ambient Glow (Background) */}
      {isPlaying && (
        <motion.div 
          className="absolute -inset-2 pointer-events-none rounded-3xl"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.6, ease: "easeOut" }}
        >
          <motion.div
            className="w-full h-full bg-gradient-to-r from-blue-400/5 via-blue-500/10 to-blue-400/5 rounded-3xl"
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