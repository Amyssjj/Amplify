import React, { useEffect, useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Mic, MicOff, Square } from "lucide-react";

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
  onCountdownComplete,
}: RecordButtonProps) {
  const [ripples, setRipples] = useState<number[]>([]);

  // Handle countdown completion
  useEffect(() => {
    if (countdown === 0 && onCountdownComplete) {
      onCountdownComplete();
    }
  }, [countdown, onCountdownComplete]);

  // Create ripple effect when recording
  useEffect(() => {
    let interval: NodeJS.Timeout;

    if (isRecording) {
      interval = setInterval(() => {
        const newRipple = Date.now();
        setRipples((prev) => [...prev, newRipple]);

        // Remove ripple after animation
        setTimeout(() => {
          setRipples((prev) => prev.filter((id) => id !== newRipple));
        }, 2000);
      }, 800);
    }

    return () => clearInterval(interval);
  }, [isRecording]);

  const formatCountdown = (seconds: number) => {
    return `0:${seconds.toString().padStart(2, "0")}`;
  };

  return (
    <div className="relative flex flex-col items-center">
      {/* Countdown Display */}
      <AnimatePresence>
        {countdown !== undefined && countdown > 0 && (
          <motion.div
            className="mb-4"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.3 }}
          >
            <motion.div
              className="glass-button px-4 py-2 rounded-full"
              animate={{
                scale: countdown <= 5 ? [1, 1.1, 1] : 1,
              }}
              transition={{
                duration: 0.5,
                repeat: countdown <= 5 ? Infinity : 0,
              }}
            >
              <span
                className={`text-sm font-medium ${
                  countdown <= 5 ? "text-red-600" : "text-gray-700"
                }`}
              >
                {formatCountdown(countdown)}
              </span>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Button Container */}
      <div className="relative">
        {/* Ripple Effects */}
        <AnimatePresence>
          {ripples.map((rippleId) => (
            <motion.div
              key={rippleId}
              className="absolute inset-0 rounded-full border-2 border-red-400/30"
              initial={{ scale: 1, opacity: 0.6 }}
              animate={{ scale: 2.5, opacity: 0 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 2, ease: "easeOut" }}
            />
          ))}
        </AnimatePresence>

        {/* Main Button */}
        <motion.button
          className={`relative w-20 h-20 rounded-full flex items-center justify-center shadow-float transition-all duration-300 ${
            isRecording
              ? "bg-red-500 hover:bg-red-600"
              : "glass-button hover:bg-white/60"
          }`}
          onClick={onPress}
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          animate={{
            boxShadow: isRecording
              ? [
                  "0 0 0 0 rgba(239, 68, 68, 0.4)",
                  "0 0 0 20px rgba(239, 68, 68, 0)",
                ]
              : "0 20px 40px -12px rgba(0, 0, 0, 0.1)",
          }}
          transition={{
            boxShadow: {
              duration: 1.5,
              repeat: isRecording ? Infinity : 0,
              ease: "easeOut",
            },
          }}
        >
          {/* Button Content */}
          <motion.div
            initial={false}
            animate={{
              scale: isRecording ? 1 : 1,
              rotate: isRecording ? 0 : 0,
            }}
            transition={{
              type: "spring",
              stiffness: 300,
              damping: 25,
            }}
          >
            <AnimatePresence mode="wait">
              {isRecording ? (
                <motion.div
                  key="recording"
                  initial={{ scale: 0, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  exit={{ scale: 0, opacity: 0 }}
                  transition={{ duration: 0.2 }}
                >
                  <Square className="w-8 h-8 text-white fill-current" />
                </motion.div>
              ) : (
                <motion.div
                  key="idle"
                  initial={{ scale: 0, opacity: 0 }}
                  animate={{ scale: 1, opacity: 1 }}
                  exit={{ scale: 0, opacity: 0 }}
                  transition={{ duration: 0.2 }}
                >
                  <Mic className="w-8 h-8 text-gray-700" />
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>

          {/* Inner Glow for Recording State */}
          <AnimatePresence>
            {isRecording && (
              <motion.div
                className="absolute inset-1 rounded-full bg-gradient-to-br from-red-400 to-red-600 opacity-20"
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 0.2, scale: 1 }}
                exit={{ opacity: 0, scale: 0.8 }}
                transition={{ duration: 0.3 }}
              />
            )}
          </AnimatePresence>
        </motion.button>

        {/* Outer Pulse Ring */}
        <AnimatePresence>
          {isRecording && (
            <motion.div
              className="absolute inset-0 rounded-full border-2 border-red-400"
              initial={{ scale: 1, opacity: 0.8 }}
              animate={{ scale: 1.8, opacity: 0 }}
              transition={{
                duration: 2,
                repeat: Infinity,
                ease: "easeOut",
              }}
            />
          )}
        </AnimatePresence>
      </div>

      {/* Status Text */}
      <motion.div
        className="mt-4 text-center"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.3, duration: 0.5 }}
      >
        <AnimatePresence mode="wait">
          {isRecording ? (
            <motion.p
              key="recording-text"
              className="text-sm text-gray-600 font-medium"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.3 }}
            >
              Tap to stop recording
            </motion.p>
          ) : (
            <motion.p
              key="idle-text"
              className="text-sm text-gray-600 font-medium"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.3 }}
            >
              Tap to start recording
            </motion.p>
          )}
        </AnimatePresence>
      </motion.div>
    </div>
  );
}