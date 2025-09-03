import React, { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { Mic, Square } from 'lucide-react';

interface RecordButtonProps {
  onPress: () => void;
  isRecording: boolean;
  countdown?: number;
  onCountdownComplete?: () => void;
}

export function RecordButton({ 
  onPress, 
  isRecording, 
  countdown,
  onCountdownComplete 
}: RecordButtonProps) {
  const [pressScale, setPressScale] = useState(1);
  const [ripples, setRipples] = useState<number[]>([]);

  // Countdown effect
  useEffect(() => {
    if (countdown !== undefined && countdown <= 0 && onCountdownComplete) {
      onCountdownComplete();
    }
  }, [countdown, onCountdownComplete]);

  // Pulse ripple effect when recording
  useEffect(() => {
    if (isRecording) {
      const interval = setInterval(() => {
        const newRipple = Date.now();
        setRipples(prev => [...prev.slice(-2), newRipple]);
      }, 800);

      return () => clearInterval(interval);
    } else {
      setRipples([]);
    }
  }, [isRecording]);

  // Clean up old ripples
  useEffect(() => {
    if (ripples.length > 0) {
      const timeout = setTimeout(() => {
        setRipples(prev => prev.slice(1));
      }, 2000);
      return () => clearTimeout(timeout);
    }
  }, [ripples]);

  const handlePress = () => {
    setPressScale(0.95);
    setTimeout(() => setPressScale(1), 150);
    onPress();
  };

  const progressPercentage = countdown ? ((30 - countdown) / 30) * 100 : 0;

  return (
    <div className="relative flex items-center justify-center">
      {/* Ripple effects */}
      {ripples.map((ripple) => (
        <motion.div
          key={ripple}
          className="absolute rounded-full border-2 border-red-300/40"
          initial={{ width: 80, height: 80, opacity: 0.8 }}
          animate={{ 
            width: 160, 
            height: 160, 
            opacity: 0 
          }}
          transition={{ 
            duration: 2, 
            ease: "easeOut" 
          }}
        />
      ))}

      {/* Outer glow ring */}
      <motion.div 
        className={`absolute w-24 h-24 rounded-full ${
          isRecording 
            ? 'bg-red-400/20 border-red-400/30' 
            : 'bg-blue-400/10 border-blue-400/20'
        } border-2`}
        animate={{
          scale: isRecording ? [1, 1.1, 1] : 1,
          opacity: isRecording ? [0.6, 0.8, 0.6] : 0.8
        }}
        transition={{
          duration: 2,
          repeat: isRecording ? Infinity : 0,
          ease: "easeInOut"
        }}
      />

      {/* Progress ring for countdown */}
      {isRecording && countdown !== undefined && (
        <motion.div className="absolute w-20 h-20">
          <svg className="w-full h-full transform -rotate-90" viewBox="0 0 100 100">
            <circle
              cx="50"
              cy="50"
              r="45"
              fill="none"
              stroke="rgba(239, 68, 68, 0.2)"
              strokeWidth="3"
            />
            <motion.circle
              cx="50"
              cy="50"
              r="45"
              fill="none"
              stroke="rgb(239, 68, 68)"
              strokeWidth="3"
              strokeLinecap="round"
              strokeDasharray={`${progressPercentage * 2.827} 282.7`}
              initial={{ strokeDasharray: "0 282.7" }}
              animate={{ strokeDasharray: `${progressPercentage * 2.827} 282.7` }}
              transition={{ duration: 0.5, ease: "easeOut" }}
            />
          </svg>
        </motion.div>
      )}

      {/* Main button */}
      <motion.button
        className={`relative w-20 h-20 rounded-full glass-button shadow-float flex items-center justify-center transition-all duration-200 ${
          isRecording 
            ? 'bg-red-500/80 border-red-400/60' 
            : 'bg-white/80 border-white/60 hover:bg-white/90'
        }`}
        style={{ scale: pressScale }}
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        onClick={handlePress}
        animate={{
          boxShadow: isRecording 
            ? "0 8px 32px rgba(239, 68, 68, 0.3), 0 4px 16px rgba(239, 68, 68, 0.2)"
            : "0 8px 32px rgba(0, 0, 0, 0.1), 0 4px 16px rgba(0, 0, 0, 0.08)"
        }}
      >
        {/* Button content */}
        <motion.div
          animate={{
            scale: isRecording ? 0.7 : 1,
            rotate: isRecording ? 180 : 0
          }}
          transition={{ 
            type: "spring", 
            stiffness: 200, 
            damping: 20 
          }}
        >
          {isRecording ? (
            <Square 
              className="w-6 h-6 text-white fill-current" 
            />
          ) : (
            <Mic 
              className="w-6 h-6 text-gray-700" 
            />
          )}
        </motion.div>

        {/* Inner highlight */}
        <motion.div 
          className="absolute inset-2 rounded-full bg-gradient-to-br from-white/40 to-transparent opacity-60"
          animate={{
            opacity: isRecording ? 0.3 : 0.6
          }}
        />
      </motion.button>

      {/* Countdown timer display */}
      {isRecording && countdown !== undefined && (
        <motion.div 
          className="absolute -bottom-8 left-1/2 transform -translate-x-1/2"
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -10 }}
        >
          <div className="glass-button px-3 py-1 rounded-full">
            <span className={`text-sm font-medium ${
              countdown <= 5 ? 'text-red-600' : 'text-gray-700'
            }`}>
              {countdown}s
            </span>
          </div>
        </motion.div>
      )}
    </div>
  );
}