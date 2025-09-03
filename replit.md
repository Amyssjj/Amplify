# Amplify - AI Communication Coach

## Overview

Amplify is a mobile AI communication coach app that helps users practice and improve their storytelling through a "Capture, Cook, Comprehend" workflow. The app uses random photos from the user's library as prompts for spontaneous storytelling practice, then provides AI-powered analysis and feedback to help users develop better communication skills.

The application follows a linear user journey: users see a photo prompt, record their story, wait for AI processing, and review results with interactive transcripts and insights. The focus is on building confidence in spontaneous speaking through structured practice and constructive feedback.

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Frontend Architecture
The application is built with React and TypeScript, using a screen-based navigation pattern that mirrors the user flow. The architecture is organized around four main application states:

- **Home Screen**: Entry point with photo display and record button
- **Recording Screen**: Live recording interface with real-time transcription
- **Processing Screen**: AI processing animation and loading state
- **Results Screen**: Story playback with swipeable insights and transcript cards

### Component Organization
Components are structured by feature and responsibility rather than type:

- **Screen Components**: Handle main application states and navigation between them
- **Modal Components**: Full-screen overlays for expanded views (transcription, insights)
- **Shared Components**: Reusable UI elements like PhotoCard and RecordButton
- **Feature-Specific Components**: Media players, swipeable cards, and specialized UI elements

### State Management
The application uses React's built-in state management with a centralized App component that manages:

- Current application state (home, recording, processing, results)
- Recording data and transcripts
- Photo selection and rotation
- Media playback controls
- Modal visibility states

### Design System
The app uses a comprehensive design system built on:

- **ShadCN UI Components**: Provides accessible, customizable base components
- **Tailwind CSS**: Utility-first styling with custom design tokens
- **Motion/Framer Motion**: Advanced animations and transitions
- **Glass morphism design**: Modern UI aesthetics with frosted glass effects

### Animation Framework
Heavy use of Framer Motion for:

- Page transitions between application states
- Interactive feedback on user actions
- Loading animations during AI processing
- Gesture-based interactions (swipe, drag)
- Micro-interactions for enhanced user experience

### Photo Management
The app accesses the user's photo library with:

- Permission-based access to user's "Favorites" album
- Fallback to curated stock photos if permission denied
- Random photo selection algorithm
- Swipe-to-refresh photo functionality

## External Dependencies

### UI and Animation Libraries
- **@radix-ui/react-***: Accessible headless UI components for dialogs, buttons, and form controls
- **motion (Framer Motion)**: Advanced animation library for smooth transitions and gestures
- **lucide-react**: Icon library for consistent iconography
- **class-variance-authority**: Type-safe component variant system
- **tailwind-merge**: Utility for merging Tailwind CSS classes

### Development Tools
- **Vite**: Fast build tool and development server
- **TypeScript**: Type safety and better developer experience
- **React 18**: Latest React features including concurrent rendering

### Media and Content
- **Unsplash**: Stock photography service for fallback images when photo permission is denied
- **Speech-to-Text API**: Real-time transcription during recording (implementation pending)
- **AI Processing Service**: Story analysis and improvement suggestions (implementation pending)

### Mobile Considerations
The architecture is designed for mobile-first experience with:

- Touch-optimized interactions and gesture support
- Responsive design that works across different screen sizes
- Native mobile permissions integration for photo library access
- Optimized performance for mobile devices

The application is structured as a Progressive Web App (PWA) that can potentially be deployed as a native mobile app using frameworks like Capacitor or React Native in the future.