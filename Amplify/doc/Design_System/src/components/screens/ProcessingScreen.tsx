import React from "react";
import { motion } from "motion/react";

export function ProcessingScreen() {
  return (
    <motion.div
      className="h-full flex flex-col justify-center items-center relative overflow-hidden"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.6 }}
    >
      {/* Main Content */}
      <div className="text-center z-10">
        {/* AI Processing Icon */}
        <motion.div
          className="w-32 h-32 mx-auto mb-8 relative"
          initial={{ scale: 0.8, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{
            delay: 0.2,
            duration: 0.8,
            type: "spring",
            stiffness: 100,
          }}
        >
          {/* Outer Ring */}
          <motion.div
            className="absolute inset-0 rounded-full glass-card"
            animate={{
              rotate: [0, 360],
              scale: [1, 1.05, 1],
            }}
            transition={{
              rotate: {
                duration: 8,
                repeat: Infinity,
                ease: "linear",
              },
              scale: {
                duration: 2,
                repeat: Infinity,
                ease: "easeInOut",
              },
            }}
          />

          {/* Inner Ring */}
          <motion.div
            className="absolute inset-4 rounded-full glass-button"
            animate={{
              rotate: [360, 0],
              scale: [1, 0.95, 1],
            }}
            transition={{
              rotate: {
                duration: 6,
                repeat: Infinity,
                ease: "linear",
              },
              scale: {
                duration: 1.5,
                repeat: Infinity,
                ease: "easeInOut",
                delay: 0.5,
              },
            }}
          />

          {/* Core */}
          <motion.div
            className="absolute inset-8 rounded-full bg-gradient-to-br from-blue-100 via-purple-50 to-pink-100 flex items-center justify-center"
            animate={{
              scale: [1, 1.1, 1],
              background: [
                "linear-gradient(135deg, rgb(219, 234, 254), rgb(249, 245, 255), rgb(254, 242, 242))",
                "linear-gradient(135deg, rgb(254, 242, 242), rgb(219, 234, 254), rgb(249, 245, 255))",
                "linear-gradient(135deg, rgb(249, 245, 255), rgb(254, 242, 242), rgb(219, 234, 254))",
              ],
            }}
            transition={{
              scale: {
                duration: 2,
                repeat: Infinity,
                ease: "easeInOut",
              },
              background: {
                duration: 4,
                repeat: Infinity,
                ease: "easeInOut",
              },
            }}
          >
            <motion.div
              className="text-4xl"
              animate={{
                rotate: [0, 10, -10, 0],
                scale: [1, 1.1, 1],
              }}
              transition={{
                duration: 3,
                repeat: Infinity,
                ease: "easeInOut",
              }}
            >
              🧠
            </motion.div>
          </motion.div>

          {/* Floating Particles */}
          {[...Array(6)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute w-2 h-2 bg-gradient-to-r from-blue-400 to-purple-400 rounded-full"
              style={{
                left: "50%",
                top: "50%",
                marginLeft: "-4px",
                marginTop: "-4px",
              }}
              animate={{
                x: [
                  0,
                  Math.cos((i * Math.PI * 2) / 6) * 80,
                  Math.cos(((i + 3) * Math.PI * 2) / 6) * 80,
                  0,
                ],
                y: [
                  0,
                  Math.sin((i * Math.PI * 2) / 6) * 80,
                  Math.sin(((i + 3) * Math.PI * 2) / 6) * 80,
                  0,
                ],
                scale: [0, 1, 1, 0],
                opacity: [0, 1, 1, 0],
              }}
              transition={{
                duration: 4,
                repeat: Infinity,
                delay: i * 0.3,
                ease: "easeInOut",
              }}
            />
          ))}
        </motion.div>

        {/* Text Content */}
        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.5, duration: 0.6 }}
        >
          <motion.h2
            className="text-2xl font-semibold text-gradient mb-4"
            animate={{
              opacity: [1, 0.7, 1],
            }}
            transition={{
              duration: 2,
              repeat: Infinity,
              ease: "easeInOut",
            }}
          >
            Cooking Now
          </motion.h2>

          <motion.p
            className="text-gray-600 mb-8"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.8, duration: 0.6 }}
          >
            Our AI is analyzing your story for insights and improvements
          </motion.p>

          {/* Progress Dots */}
          <div className="flex justify-center gap-2">
            {[...Array(3)].map((_, i) => (
              <motion.div
                key={i}
                className="w-3 h-3 bg-gradient-to-r from-blue-400 to-purple-400 rounded-full"
                animate={{
                  scale: [1, 1.5, 1],
                  opacity: [0.4, 1, 0.4],
                }}
                transition={{
                  duration: 1.5,
                  repeat: Infinity,
                  delay: i * 0.3,
                  ease: "easeInOut",
                }}
              />
            ))}
          </div>
        </motion.div>
      </div>

      {/* Background Ambient Elements */}
      <div className="absolute inset-0 pointer-events-none">
        {/* Floating Orbs */}
        {[...Array(5)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute rounded-full opacity-30"
            style={{
              width: `${60 + i * 20}px`,
              height: `${60 + i * 20}px`,
              background: `linear-gradient(135deg, 
                ${i % 2 === 0 ? "rgb(59, 130, 246)" : "rgb(168, 85, 247)"}, 
                ${i % 2 === 0 ? "rgb(147, 197, 253)" : "rgb(196, 181, 253)"})`,
              left: `${20 + (i * 15)}%`,
              top: `${10 + (i * 20)}%`,
            }}
            animate={{
              x: [0, 30, -30, 0],
              y: [0, -20, 20, 0],
              scale: [1, 1.1, 0.9, 1],
              rotate: [0, 180, 360],
            }}
            transition={{
              duration: 8 + i * 2,
              repeat: Infinity,
              ease: "easeInOut",
              delay: i * 0.5,
            }}
          />
        ))}

        {/* Gradient Overlays */}
        <motion.div
          className="absolute top-0 left-0 w-full h-full"
          style={{
            background:
              "radial-gradient(circle at 30% 20%, rgba(59, 130, 246, 0.1) 0%, transparent 50%)",
          }}
          animate={{
            opacity: [0.3, 0.6, 0.3],
          }}
          transition={{
            duration: 4,
            repeat: Infinity,
            ease: "easeInOut",
          }}
        />

        <motion.div
          className="absolute bottom-0 right-0 w-full h-full"
          style={{
            background:
              "radial-gradient(circle at 70% 80%, rgba(168, 85, 247, 0.1) 0%, transparent 50%)",
          }}
          animate={{
            opacity: [0.2, 0.5, 0.2],
          }}
          transition={{
            duration: 6,
            repeat: Infinity,
            ease: "easeInOut",
            delay: 2,
          }}
        />
      </div>
    </motion.div>
  );
}