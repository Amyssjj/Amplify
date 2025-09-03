import React from 'react';
import { motion } from 'motion/react';

export function ProcessingScreen() {
  return (
    <motion.div 
      className="h-full flex flex-col items-center justify-center relative overflow-hidden"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.5 }}
    >
      {/* Background Gradient */}
      <div className="absolute inset-0 bg-gradient-to-br from-blue-50 via-white to-purple-50" />
      
      {/* Floating Particles */}
      <div className="absolute inset-0">
        {[...Array(20)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-2 h-2 bg-gradient-to-br from-blue-300 to-purple-300 rounded-full opacity-60"
            style={{
              left: `${Math.random() * 100}%`,
              top: `${Math.random() * 100}%`,
            }}
            animate={{
              y: [-20, -40, -20],
              x: [0, 10, 0],
              scale: [0.5, 1, 0.5],
              opacity: [0.3, 0.8, 0.3]
            }}
            transition={{
              duration: 3 + Math.random() * 2,
              repeat: Infinity,
              delay: Math.random() * 2,
              ease: "easeInOut"
            }}
          />
        ))}
      </div>

      {/* Main Content */}
      <motion.div 
        className="relative z-10 text-center"
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ delay: 0.2, duration: 0.8, type: "spring", stiffness: 100 }}
      >
        {/* Central Animation */}
        <motion.div 
          className="relative mb-8"
          animate={{ rotate: 360 }}
          transition={{ duration: 8, repeat: Infinity, ease: "linear" }}
        >
          {/* Outer Ring */}
          <motion.div 
            className="w-32 h-32 rounded-full border-2 border-blue-300/40 flex items-center justify-center"
            animate={{ 
              scale: [1, 1.1, 1],
              borderColor: ["rgba(147, 197, 253, 0.4)", "rgba(167, 139, 250, 0.6)", "rgba(147, 197, 253, 0.4)"]
            }}
            transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
          >
            {/* Inner Ring */}
            <motion.div 
              className="w-20 h-20 rounded-full border-2 border-purple-300/60 flex items-center justify-center"
              animate={{ 
                rotate: -360,
                scale: [0.9, 1.1, 0.9]
              }}
              transition={{ 
                rotate: { duration: 6, repeat: Infinity, ease: "linear" },
                scale: { duration: 3, repeat: Infinity, ease: "easeInOut" }
              }}
            >
              {/* Core */}
              <motion.div 
                className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-400 to-purple-500 shadow-lg"
                animate={{ 
                  scale: [1, 1.3, 1],
                  boxShadow: [
                    "0 4px 20px rgba(147, 197, 253, 0.3)",
                    "0 8px 40px rgba(167, 139, 250, 0.5)",
                    "0 4px 20px rgba(147, 197, 253, 0.3)"
                  ]
                }}
                transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
              />
            </motion.div>
          </motion.div>

          {/* Orbital Elements */}
          {[...Array(3)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute w-3 h-3 bg-gradient-to-br from-blue-400 to-purple-400 rounded-full"
              style={{
                originX: 0.5,
                originY: 0.5,
              }}
              animate={{
                rotate: 360,
                scale: [0.5, 1, 0.5]
              }}
              transition={{
                rotate: { 
                  duration: 4 + i, 
                  repeat: Infinity, 
                  ease: "linear" 
                },
                scale: { 
                  duration: 2, 
                  repeat: Infinity, 
                  delay: i * 0.5,
                  ease: "easeInOut" 
                }
              }}
              transformOrigin="80px center"
            />
          ))}
        </motion.div>

        {/* Text */}
        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.5, duration: 0.6 }}
        >
          <motion.h1 
            className="text-3xl font-semibold text-gradient mb-4"
            animate={{ 
              backgroundPosition: ["0% 50%", "100% 50%", "0% 50%"]
            }}
            transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
          >
            Cooking now...
          </motion.h1>
          
          <motion.p 
            className="text-gray-600 text-lg mb-2"
            animate={{ opacity: [0.7, 1, 0.7] }}
            transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
          >
            Transforming your story
          </motion.p>
          
          <motion.p 
            className="text-sm text-gray-500"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1, duration: 0.6 }}
          >
            Our AI is analyzing your words and adding magic ✨
          </motion.p>
        </motion.div>

        {/* Progress Dots */}
        <motion.div 
          className="flex justify-center gap-2 mt-8"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.8 }}
        >
          {[...Array(3)].map((_, i) => (
            <motion.div
              key={i}
              className="w-2 h-2 bg-blue-400 rounded-full"
              animate={{
                scale: [1, 1.5, 1],
                opacity: [0.4, 1, 0.4]
              }}
              transition={{
                duration: 1.5,
                repeat: Infinity,
                delay: i * 0.3,
                ease: "easeInOut"
              }}
            />
          ))}
        </motion.div>
      </motion.div>

      {/* Bottom Ambient Elements */}
      <motion.div 
        className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-white/80 to-transparent"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.2, duration: 1 }}
      />

      {/* Sound Wave Animation */}
      <motion.div 
        className="absolute bottom-8 left-1/2 transform -translate-x-1/2 flex items-end gap-1"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 1.5, duration: 0.8 }}
      >
        {[...Array(7)].map((_, i) => (
          <motion.div
            key={i}
            className="w-1 bg-gradient-to-t from-blue-400 to-purple-400 rounded-full"
            animate={{
              height: [8, 24, 8],
              opacity: [0.4, 1, 0.4]
            }}
            transition={{
              duration: 1.5,
              repeat: Infinity,
              delay: i * 0.1,
              ease: "easeInOut"
            }}
          />
        ))}
      </motion.div>
    </motion.div>
  );
}