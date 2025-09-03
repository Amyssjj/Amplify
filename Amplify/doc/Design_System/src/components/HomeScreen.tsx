import React from "react";
import { motion } from "motion/react";
import { PhotoCard } from "./PhotoCard";
import { RecordButton } from "./RecordButton";
import { Mic } from "lucide-react";

interface HomeScreenProps {
  currentPhoto: string;
  onStartRecording: () => void;
  onNewPhoto: () => void;
}

export function HomeScreen({
  currentPhoto,
  onStartRecording,
  onNewPhoto,
}: HomeScreenProps) {
  return (
    <motion.div
      className="h-full flex flex-col relative"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.8, ease: "easeOut" }}
    >
      {/* Header */}
      <motion.div
        className="px-6 pt-8 pb-4"
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 0.2, duration: 0.6 }}
      >
        <h1 className="text-3xl font-semibold text-gradient mb-2">
          Amplify
        </h1>
        <p className="text-gray-600">
          Level up your storytelling
        </p>
      </motion.div>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col justify-center px-6 -mt-20">
        {/* Photo Card */}
        <motion.div
          className="mb-20"
          initial={{ scale: 0.8, y: 40, opacity: 0 }}
          animate={{ scale: 1, y: 0, opacity: 1 }}
          transition={{
            delay: 0.4,
            duration: 0.8,
            type: "spring",
            stiffness: 100,
            damping: 20,
          }}
        >
          <PhotoCard
            imageUrl={currentPhoto}
            onSwipe={onNewPhoto}
          />
        </motion.div>
      </div>

      {/* Record Button Area */}
      <motion.div
        className="pb-12 px-6"
        initial={{ y: 60, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{
          delay: 0.8,
          duration: 0.8,
          type: "spring",
          stiffness: 120,
          damping: 25,
        }}
      >
        <div className="flex justify-center">
          <RecordButton
            onPress={onStartRecording}
            isRecording={false}
          />
        </div>

        {/* Hint Text */}
        <motion.div
          className="text-center mt-6"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1.2, duration: 0.6 }}
        ></motion.div>
      </motion.div>

      {/* Background Ambient Elements */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden">
        <motion.div
          className="absolute -top-20 -right-20 w-40 h-40 rounded-full bg-gradient-to-br from-blue-100/30 to-purple-100/20 blur-3xl"
          animate={{
            scale: [1, 1.2, 1],
            rotate: [0, 180, 360],
          }}
          transition={{
            duration: 20,
            repeat: Infinity,
            ease: "linear",
          }}
        />
        <motion.div
          className="absolute -bottom-20 -left-20 w-32 h-32 rounded-full bg-gradient-to-tr from-pink-100/20 to-orange-100/30 blur-3xl"
          animate={{
            scale: [1.2, 1, 1.2],
            rotate: [360, 180, 0],
          }}
          transition={{
            duration: 15,
            repeat: Infinity,
            ease: "linear",
          }}
        />
      </div>
    </motion.div>
  );
}