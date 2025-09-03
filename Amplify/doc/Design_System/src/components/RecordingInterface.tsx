import React, { useState, useEffect } from "react";
import { motion } from "motion/react";
import { PhotoCard } from "./PhotoCard";
import { RecordButton } from "./RecordButton";
import { ArrowLeft } from "lucide-react";

interface RecordingInterfaceProps {
  currentPhoto: string;
  onFinishRecording: (
    transcript: string,
    duration: number,
  ) => void;
  onBack: () => void;
}

// Mock transcription words for demonstration
const MOCK_TRANSCRIPTION_WORDS = [
  "Looking",
  "at",
  "this",
  "beautiful",
  "sunset",
  "reminds",
  "me",
  "of",
  "a",
  "summer",
  "evening",
  "when",
  "I",
  "was",
  "traveling",
  "through",
  "the",
  "mountains.",
  "The",
  "sky",
  "was",
  "painted",
  "with",
  "these",
  "incredible",
  "orange",
  "and",
  "pink",
  "hues",
  "that",
  "seemed",
  "to",
  "dance",
  "across",
  "the",
  "horizon.",
  "It",
  "was",
  "one",
  "of",
  "those",
  "moments",
  "that",
  "makes",
  "you",
  "pause",
  "and",
  "appreciate",
  "the",
  "simple",
  "beauty",
  "of",
  "nature.",
];

export function RecordingInterface({
  currentPhoto,
  onFinishRecording,
  onBack,
}: RecordingInterfaceProps) {
  const [isRecording, setIsRecording] = useState(true); // Start recording immediately
  const [countdown, setCountdown] = useState(30);
  const [currentWords, setCurrentWords] = useState<string[]>(
    [],
  );
  const [recordingStarted, setRecordingStarted] =
    useState(true); // Recording starts automatically
  const [displayedWords, setDisplayedWords] = useState<
    string[]
  >([]);
  const [transcriptionContainer, setTranscriptionContainer] = useState<HTMLDivElement | null>(null);

  // Start recording countdown
  useEffect(() => {
    let interval: NodeJS.Timeout;

    if (isRecording && countdown > 0) {
      interval = setInterval(() => {
        setCountdown((prev) => prev - 1);
      }, 1000);
    } else if (countdown <= 0) {
      handleStopRecording();
    }

    return () => clearInterval(interval);
  }, [isRecording, countdown]);

  // Simulate live transcription
  useEffect(() => {
    let wordInterval: NodeJS.Timeout;

    if (isRecording) {
      let wordIndex = 0;
      wordInterval = setInterval(
        () => {
          if (wordIndex < MOCK_TRANSCRIPTION_WORDS.length) {
            setCurrentWords((prev) => [
              ...prev,
              MOCK_TRANSCRIPTION_WORDS[wordIndex],
            ]);
            wordIndex++;
          }
        },
        800 + Math.random() * 400,
      ); // Vary timing to feel more natural
    }

    return () => clearInterval(wordInterval);
  }, [isRecording]);

  // Update displayed words when currentWords changes
  useEffect(() => {
    setDisplayedWords(currentWords);
  }, [currentWords]);

  // Auto-scroll to bottom when new words are added
  useEffect(() => {
    if (transcriptionContainer && displayedWords.length > 0) {
      transcriptionContainer.scrollTop = transcriptionContainer.scrollHeight;
    }
  }, [displayedWords, transcriptionContainer]);

  const handleStopRecording = () => {
    setIsRecording(false);
    const transcript = currentWords.join(" ");
    const duration = 30 - countdown;
    onFinishRecording(transcript, duration);
  };

  return (
    <motion.div
      className="h-full flex flex-col"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.4 }}
    >
      {/* Photo Section - Top Half */}
      <motion.div
        className="h-1/2 relative overflow-hidden"
        initial={{ y: -50, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{
          delay: 0.1,
          duration: 0.6,
          type: "spring",
          stiffness: 100,
          damping: 20,
        }}
      >
        {/* Photo Container with Glass Effect */}
        <div className="absolute inset-0">
          <motion.div
            className="w-full h-full relative"
            layoutId="photo-card"
            transition={{
              type: "spring",
              stiffness: 100,
              damping: 25,
              duration: 0.8,
            }}
          >
            <img
              src={currentPhoto}
              alt="Recording inspiration"
              className="w-full h-full object-cover"
            />

            {/* Subtle overlay for better contrast */}
            <div className="absolute inset-0 bg-gradient-to-b from-black/5 via-transparent to-black/10" />

            {/* Back Button */}
            <motion.button
              className="absolute top-16 left-4 glass-button p-3 rounded-full shadow-lg"
              onClick={onBack}
              initial={{ scale: 0, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ delay: 0.3 }}
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="w-5 h-5 text-gray-700" />
            </motion.button>

            {/* Recording indicator */}
            {isRecording && (
              <motion.div
                className="absolute top-16 right-4 flex items-center gap-2 glass-button px-3 py-2 rounded-full"
                initial={{ scale: 0, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ delay: 0.3 }}
              >
                <motion.div
                  className="w-2 h-2 bg-red-500 rounded-full"
                  animate={{
                    opacity: [1, 0.4, 1],
                  }}
                  transition={{
                    duration: 1,
                    repeat: Infinity,
                    ease: "easeInOut",
                  }}
                />
                <span className="text-xs font-medium text-gray-700">
                  REC
                </span>
              </motion.div>
            )}
          </motion.div>
        </div>
      </motion.div>

      {/* Transcription Section - Bottom Half */}
      <motion.div
        className="h-1/2 relative"
        initial={{ y: 50, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{
          delay: 0.2,
          duration: 0.6,
          type: "spring",
          stiffness: 100,
          damping: 20,
        }}
      >
        {/* Bottom Sheet */}
        <div className="absolute bottom-0 left-0 right-0 p-4">
          <motion.div 
            className="bg-white/90 rounded-t-3xl p-6 pb-8 relative overflow-hidden flex flex-col shadow-lg"
            initial={{ y: 100, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ 
              type: "spring", 
              stiffness: 300, 
              damping: 30,
              delay: 0.2 
            }}
          >
            {/* Header */}
            <motion.div
              className="text-center mb-6"
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.4 }}
            >
              <h2 className="text-xl font-semibold text-gradient mb-2">
                {isRecording
                  ? "Listening..."
                  : "Recording Complete"}
              </h2>
            </motion.div>

            {/* Live Transcription Area */}
            <div className="mb-6 relative">
              {/* Transcription Container */}
              <div 
                ref={setTranscriptionContainer}
                className="rounded-2xl h-[200px] relative overflow-y-auto bg-white/80 px-[0px] py-[14px]"
              >
                {/* Background Pattern - Removed */}

                {/* Content */}
                <div className="relative z-10">
                  {/* Empty State */}
                  {displayedWords.length === 0 && (
                    <motion.div
                      className="flex items-center justify-center h-full"
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      exit={{ opacity: 0 }}
                    >
                      {/* Empty state - no visual elements */}
                    </motion.div>
                  )}

                  {/* Live Text */}
                  {displayedWords.length > 0 && (
                    <div className="px-4">
                      <div className="flex flex-wrap gap-x-1 gap-y-0 leading-tight">
                        {displayedWords.map((word, index) => (
                          <span
                            key={`${word}-${index}`}
                            className="text-gray-800"
                          >
                            {word}
                          </span>
                        ))}

                        {/* Typing cursor */}
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


                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Record Button */}
            <motion.div
              className="flex justify-center"
              initial={{ y: 30, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.6 }}
            >
              <RecordButton
                onPress={handleStopRecording}
                isRecording={isRecording}
                countdown={isRecording ? countdown : undefined}
                onCountdownComplete={handleStopRecording}
              />
            </motion.div>
          </motion.div>
        </div>
      </motion.div>

    </motion.div>
  );
}