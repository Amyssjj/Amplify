import React from "react";
import { motion } from "motion/react";
import { MiniMediaPlayer } from "../media/MiniMediaPlayer";
import { SwipeableCards } from "../results/SwipeableCards";
import { ArrowLeft, Share } from "lucide-react";
import type { Recording } from "../../App";

interface ResultsScreenProps {
  recording: Recording;
  onBackToHome: () => void;
  currentPlayTime: number;
  isPlaying: boolean;
  onPlayTimeUpdate: (time: number) => void;
  onPlayingChange: (playing: boolean) => void;
  onTranscriptExpand: () => void;
  onInsightsExpand: () => void;
}

export function ResultsScreen({
  recording,
  onBackToHome,
  currentPlayTime,
  isPlaying,
  onPlayTimeUpdate,
  onPlayingChange,
  onTranscriptExpand,
  onInsightsExpand,
}: ResultsScreenProps) {

  return (
    <motion.div
      className="h-full flex flex-col relative"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.6 }}
    >
      {/* Header */}
      <motion.div
        className="flex items-center justify-between p-6 relative z-10"
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.1, duration: 0.6 }}
      >
        <motion.button
          className="glass-button p-3 rounded-full shadow-lg"
          onClick={onBackToHome}
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
        >
          <ArrowLeft className="w-5 h-5 text-gray-700" />
        </motion.button>

        <div className="text-center">
          <h1 className="text-lg font-semibold text-gradient">
            Your Story
          </h1>
          <p className="text-sm text-gray-600">
            {Math.floor(recording.duration / 60)}:
            {(recording.duration % 60)
              .toString()
              .padStart(2, "0")}
          </p>
        </div>

        <motion.button
          className="glass-button p-3 rounded-full shadow-lg"
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
        >
          <Share className="w-5 h-5 text-gray-700" />
        </motion.button>
      </motion.div>

      {/* Photo and Media Player Section */}
      <motion.div
        className="px-6 mb-6"
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{
          delay: 0.2,
          duration: 0.8,
          type: "spring",
          stiffness: 100,
        }}
      >
        <div className="relative">
          {/* Photo */}
          <div className="relative w-full h-48 rounded-2xl overflow-hidden shadow-lg mb-4">
            <img
              src={recording.photoUrl}
              alt="Story inspiration"
              className="w-full h-full object-cover"
            />

            {/* Subtle gradient overlay for text readability */}
            <div className="absolute inset-0 bg-gradient-to-t from-black/20 via-transparent to-transparent" />

            {/* Mini Media Player Overlay - Positioned at bottom */}
            <div className="absolute bottom-0 left-0 right-0">
              <MiniMediaPlayer
                duration={recording.duration}
                currentTime={currentPlayTime}
                isPlaying={isPlaying}
                onPlayPause={() => onPlayingChange(!isPlaying)}
                onTimeUpdate={onPlayTimeUpdate}
              />
            </div>
          </div>
        </div>
      </motion.div>

      {/* Swipeable Cards Section */}
      <SwipeableCards 
        recording={recording}
        currentPlayTime={currentPlayTime}
        isPlaying={isPlaying}
        onTranscriptExpand={onTranscriptExpand}
        onInsightsExpand={onInsightsExpand}
      />
    </motion.div>
  );
}