import React, { useState } from "react";
import { motion, PanInfo } from "motion/react";
import { ImageWithFallback } from "../figma/ImageWithFallback";
import { RefreshCw } from "lucide-react";

interface PhotoCardProps {
  imageUrl: string;
  onSwipe?: () => void;
}

export function PhotoCard({ imageUrl, onSwipe }: PhotoCardProps) {
  const [isDragging, setIsDragging] = useState(false);

  const handleDragEnd = (event: any, info: PanInfo) => {
    setIsDragging(false);
    
    // Swipe threshold
    const threshold = 100;
    
    if (Math.abs(info.offset.x) > threshold && onSwipe) {
      onSwipe();
    }
  };

  const handleDragStart = () => {
    setIsDragging(true);
  };

  return (
    <motion.div
      className="relative w-full h-80 overflow-hidden"
      layoutId="photo-card"
      whileHover={{ scale: isDragging ? 1 : 1.02 }}
      transition={{ 
        type: "spring", 
        stiffness: 300, 
        damping: 30,
        layout: { duration: 0.8 }
      }}
    >
      {/* Main Photo Card */}
      <motion.div
        className="glass-card rounded-3xl overflow-hidden shadow-float h-full cursor-grab active:cursor-grabbing"
        drag={onSwipe ? "x" : false}
        dragConstraints={{ left: 0, right: 0 }}
        dragElastic={0.3}
        onDragStart={handleDragStart}
        onDragEnd={handleDragEnd}
        whileDrag={{ 
          scale: 0.98,
          rotateZ: info => info.offset.x / 10,
        }}
        animate={{
          rotateZ: 0,
          scale: 1
        }}
        transition={{ 
          type: "spring", 
          stiffness: 400, 
          damping: 25 
        }}
      >
        {/* Photo */}
        <div className="relative w-full h-full">
          <ImageWithFallback
            src={imageUrl}
            alt="Story inspiration"
            className="w-full h-full object-cover"
          />
          
          {/* Subtle gradient overlay */}
          <div className="absolute inset-0 bg-gradient-to-t from-black/10 via-transparent to-white/5" />
          
          {/* Swipe hint - only show if onSwipe is provided */}
          {onSwipe && (
            <motion.div
              className="absolute bottom-4 left-1/2 transform -translate-x-1/2"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 2, duration: 0.6 }}
            >
              <motion.div
                className="glass-button px-4 py-2 rounded-full flex items-center gap-2"
                animate={{
                  x: [-5, 5, -5],
                }}
                transition={{
                  duration: 2,
                  repeat: Infinity,
                  ease: "easeInOut",
                }}
              >
                <RefreshCw className="w-3 h-3 text-gray-600" />
                <span className="text-xs text-gray-600 font-medium">
                  Swipe for new photo
                </span>
              </motion.div>
            </motion.div>
          )}
        </div>
      </motion.div>

      {/* Drag Progress Indicator */}
      {isDragging && onSwipe && (
        <motion.div
          className="absolute bottom-0 left-0 right-0 h-1 bg-white/20 rounded-full overflow-hidden mx-4 mb-4"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
        >
          <motion.div
            className="h-full bg-gradient-to-r from-blue-400 to-purple-400 rounded-full"
            initial={{ width: "0%" }}
            animate={{ width: "100%" }}
            transition={{ duration: 0.3 }}
          />
        </motion.div>
      )}

      {/* Background Glow Effect */}
      <motion.div
        className="absolute -inset-4 rounded-3xl opacity-20 pointer-events-none"
        style={{
          background: "radial-gradient(circle, rgba(59, 130, 246, 0.3) 0%, transparent 70%)",
        }}
        animate={{
          scale: [1, 1.1, 1],
          opacity: [0.1, 0.3, 0.1],
        }}
        transition={{
          duration: 4,
          repeat: Infinity,
          ease: "easeInOut",
        }}
      />
    </motion.div>
  );
}