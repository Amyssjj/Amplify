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
      className="w-full"
      initial={{ scale: 0.95, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
      transition={{ 
        duration: 0.6, 
        type: "spring", 
        stiffness: 120,
        damping: 25
      }}
    >
      {/* Mini Controls Container - No background to show photo */}
      <div className="flex items-center gap-4 px-4 py-3">
        {/* Progress Bar - Takes most space */}
        <div className="flex-1 space-y-2">
          {/* Progress Track */}
          <div 
            className="relative h-1.5 bg-white/50 rounded-full cursor-pointer group backdrop-blur-sm"
            onPointerDown={handleSeek}
          >
            {/* Background Track */}
            <div className="absolute inset-0 rounded-full bg-black/20" />
            
            {/* Progress Fill */}
            <motion.div 
              className="absolute left-0 top-0 h-full bg-white rounded-full shadow-sm"
              style={{ width: `${progressPercentage}%` }}
              animate={{
                opacity: isPlaying ? 1 : 0.9
              }}
              transition={{ duration: 0.3, ease: "easeOut" }}
            />
            
            {/* Progress Thumb */}
            <motion.div 
              className="absolute top-1/2 transform -translate-y-1/2 w-3 h-3 bg-white rounded-full shadow-md opacity-0 group-hover:opacity-100"
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
          <div className="flex justify-between items-center text-xs">
            <span className="text-white/90 font-medium backdrop-blur-sm bg-black/20 px-2 py-0.5 rounded-full">
              {formatTime(currentTime)}
            </span>
            
            <span className="text-white/70 backdrop-blur-sm bg-black/20 px-2 py-0.5 rounded-full">
              {formatTime(duration)}
            </span>
          </div>
        </div>

        {/* Play/Pause Button - On the right */}
        <motion.button
          className="backdrop-blur-md bg-white/80 border border-white/50 p-3 rounded-full shadow-lg"
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          onClick={onPlayPause}
          transition={{ type: "spring", stiffness: 400, damping: 25 }}
          animate={{
            boxShadow: isPlaying 
              ? "0 4px 20px rgba(59, 130, 246, 0.3)" 
              : "0 4px 12px rgba(0, 0, 0, 0.15)",
            backgroundColor: isPlaying ? "rgba(255, 255, 255, 0.9)" : "rgba(255, 255, 255, 0.8)"
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
              <Pause className="w-5 h-5 text-gray-700" />
            ) : (
              <Play className="w-5 h-5 text-gray-700 ml-0.5" />
            )}
          </motion.div>
        </motion.button>
      </div>
    </motion.div>
  );
}