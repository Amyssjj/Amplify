import React, { useState } from 'react';
import { motion, PanInfo } from 'motion/react';
import { ImageWithFallback } from './figma/ImageWithFallback';
import { RefreshCw } from 'lucide-react';

interface PhotoCardProps {
  imageUrl: string;
  onSwipe: () => void;
  isExpanded?: boolean;
}

export function PhotoCard({ imageUrl, onSwipe, isExpanded = false }: PhotoCardProps) {
  const [dragX, setDragX] = useState(0);
  const [isLoading, setIsLoading] = useState(false);

  const handleDragEnd = (event: any, info: PanInfo) => {
    const swipeThreshold = 100;
    
    if (Math.abs(info.offset.x) > swipeThreshold) {
      setIsLoading(true);
      
      // Animate out
      setDragX(info.offset.x > 0 ? 300 : -300);
      
      // Load new photo after animation
      setTimeout(() => {
        onSwipe();
        setDragX(0);
        setIsLoading(false);
      }, 300);
    } else {
      setDragX(0);
    }
  };

  const cardVariants = {
    initial: { scale: 0.8, opacity: 0, rotateY: 15 },
    animate: { 
      scale: 1, 
      opacity: 1, 
      rotateY: 0,
      transition: {
        type: "spring",
        stiffness: 100,
        damping: 20,
        duration: 0.8
      }
    },
    hover: { 
      scale: 1.02,
      rotateY: -2,
      transition: {
        type: "spring",
        stiffness: 400,
        damping: 30
      }
    }
  };

  return (
    <div className="relative perspective-1000">
      <motion.div
        className={`relative ${isExpanded ? 'w-full h-64' : 'w-80 h-96 mx-auto'} rounded-3xl overflow-hidden glass-card shadow-deep`}
        variants={cardVariants}
        initial="initial"
        animate="animate"
        whileHover="hover"
        drag="x"
        dragConstraints={{ left: 0, right: 0 }}
        dragElastic={0.2}
        onDragEnd={handleDragEnd}
        style={{ 
          x: dragX,
          perspective: 1000
        }}
        whileDrag={{ 
          scale: 1.05, 
          rotateY: dragX / 10,
          transition: { duration: 0 }
        }}
      >
        {/* Image */}
        <div className="relative w-full h-full">
          <ImageWithFallback
            src={imageUrl}
            alt="Inspiration photo"
            className="w-full h-full object-cover"
          />
          
          {/* Glass overlay for better text readability */}
          <div className="absolute inset-0 bg-gradient-to-t from-black/20 via-transparent to-transparent" />
          
          {/* Loading state */}
          {isLoading && (
            <motion.div 
              className="absolute inset-0 glass-overlay flex items-center justify-center"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            >
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
              >
                <RefreshCw className="w-8 h-8 text-gray-600" />
              </motion.div>
            </motion.div>
          )}
          
          {/* Swipe indicator dots */}
          {!isExpanded && (
            <div className="absolute bottom-4 left-1/2 transform -translate-x-1/2">
              <div className="flex gap-2">
                {[...Array(3)].map((_, i) => (
                  <motion.div
                    key={i}
                    className="w-2 h-2 rounded-full bg-white/60"
                    initial={{ scale: 0.8, opacity: 0.6 }}
                    animate={{ 
                      scale: i === 1 ? 1.2 : 0.8,
                      opacity: i === 1 ? 1 : 0.6
                    }}
                    transition={{ duration: 0.3 }}
                  />
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Interactive glow effect */}
        <motion.div 
          className="absolute inset-0 rounded-3xl opacity-0 bg-gradient-to-br from-white/20 via-transparent to-transparent"
          whileHover={{ opacity: 1 }}
          transition={{ duration: 0.3 }}
        />
      </motion.div>



      {/* Depth shadow */}
      <div 
        className={`absolute inset-0 -z-10 ${isExpanded ? 'rounded-2xl' : 'rounded-3xl'} bg-black/5 blur-xl`}
        style={{
          transform: 'translateY(8px) translateZ(-10px)',
        }}
      />
    </div>
  );
}