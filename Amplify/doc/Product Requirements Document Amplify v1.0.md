## Product Requirements Document: Amplify v1.0

**Author:** Gemini
**Date:** August 31, 2025
**Version:** 1.0

### 1. Introduction & Vision

**The Problem:** Millions of people have valuable ideas but struggle to express them spontaneously and with impact. They feel their communication is "dry" or "simple," leading to a lack of confidence in presentations, meetings, and social situations. The path to improvement is unclear, unstructured, and lacks immediate feedback.

**The Vision:** Amplify is a mobile AI communication coach that transforms how people practice and improve their storytelling. By providing a safe space to practice and instant, constructive feedback, Amplify empowers users to bridge the gap between their thoughts and their words, building the competence and confidence needed to become compelling communicators.

### 2. Goals & Objectives

**User Goals:**
*   To increase confidence in spontaneous speaking.
*   To learn and internalize effective storytelling frameworks and structures.
*   To improve phrasing, word choice, and overall delivery impact.
*   To create a consistent practice habit for communication skills.

**Business Goals:**
*   Achieve high user engagement, measured by the number of stories recorded per user per week.
*   Secure strong Day 7 and Day 30 user retention rates, indicating a valuable and habit-forming product.
*   Attain a 4.5+ star rating in the app stores, driven by positive user feedback on skill improvement.

### 3. Target Audience & Personas

**Primary Persona: "The Aspiring Communicator"**
*   **Who:** Sarah, a 30-year-old mid-level manager or professional.
*   **Needs:** She frequently needs to present ideas in meetings, network at events, and communicate her vision to her team.
*   **Pain Points:** She feels her core ideas are strong, but her delivery lacks polish. She often uses filler words and struggles to structure her thoughts on the fly. She fears she isn't perceived as a leader due to her communication style.
*   **Goals:** She wants a tool to practice that is private, constructive, and fits into her busy schedule.

### 4. User Journey & Flow

The core user experience is a simple, repeatable loop designed for practice and learning:

1.  **Onboarding/First Use:** The app requests one-time access to the user's photo library.
2.  **The Personal Spark:** The user opens the app and is presented with a random photo from their "Favorites" album.
3.  **The Story:** The user taps a button to record their spontaneous story or thoughts about the image (up to 60 seconds). A live transcript appears as they speak.
4.  **The Amplification:** The AI processes the user's raw text, then presents a polished, "amplified" version via a high-quality AI voice and text.
5.  **The Level-Up:** The user receives a concise, actionable breakdown of the improvements, focusing on the **Frameworks** used and the **Phrasing** enhancements. 

### 5. Features & Functional Requirements (v1.0)

#### 5.1. The Personal Spark Screen (Home)
*   **FR 1.1:** **Photo Library Permission:** On first launch, the app must present a clear, compelling permission request dialog explaining why it needs access to the user's photos (e.g., "Amplify uses your favorite photos to make your practice through your own story.").
*   **FR 1.2:** **Image Selection Logic:** Upon app launch, the app will:Check for permission to access the photo library.Access the user's "Favorites" album.Randomly select one photo from this album to display as the prompt.
*   **FR 1.3:** **Fallback Mechanism:**If permission is denied, the user will be taken to a screen explaining the core feature and a button to go to Settings to enable it. A curated, default stock image will be provided for them to try the app's functionality.If the "Favorites" album is empty or does not exist, the app will randomly select a photo from the user's main camera roll from the last 30 days.
*   **FR 1.4:** The screen must display a high-quality, full-screen image upon app launch.
*   **FR 1.5:** A clear, intuitive "Record Your Story" button (e.g., a microphone icon) must be the primary call-to-action.

#### 5.2. The Recording Experience
*   **FR 2.1:** Tapping and holding the record button will initiate voice recording for a maximum of 60 seconds.
*   **FR 2.2:** A highly accurate, low-latency speech-to-text engine must provide a live transcript as the user speaks.
*   **FR 2.3:** A visual indicator (e.g., a circular progress bar) must show the remaining recording time.
*   **FR 2.4:** Upon release of the button, the raw audio file and the final transcript must be saved and sent for processing.

#### 5.3. The Amplified Story Screen
*   **FR 3.1:** The AI must generate an "amplified" text based on the user's original transcript. The amplification logic must:
    *   Preserve the user's core idea and authentic voice.
    *   Correct grammatical errors.
    *   Improve sentence structure for better flow.
    *   Replace weak/filler words with more impactful language.
*   **FR 3.2:** A high-quality, natural-sounding text-to-speech (TTS) engine will read the amplified story aloud. The user must have controls to play/pause the audio.
*   **FR 3.3:** The amplified text must be displayed clearly on the screen.

#### 5.4. The Level-Up Feedback Module
*   **FR 4.1:** The module must be presented below the amplified story in two distinct, collapsible sections: `🏗️ Framework & Structure` and `✨ Phrasing & Impact`.
*   **FR 4.2:** The AI must identify and name the storytelling framework(s) the user implicitly used and/or the AI applied (e.g., "Aha! Moment," "Then vs. Now").
*   **FR 4.3:** The feedback must be presented as concise, "before and after" examples with a simple explanation ("The Why") for each improvement.
*   **FR 4.4:** Each key insight (e.g., a framework name or a phrasing tip) must have a button allowing the user to **[+ Save to my Toolkit]**.

#### 5.5. The User's Toolkit
*   **FR 5.1:** A dedicated section in the app where users can view all their saved frameworks and phrasing tips.
*   **FR 5.2:** This section should be organized and easily searchable, acting as a personal library for revision.

### 6. Non-Functional Requirements
*   **Performance:** The AI processing time (from end of recording to display of results) should not exceed 5-7 seconds to maintain a fluid user experience.
*   **Privacy:** The app's privacy policy must clearly state that user photos are accessed for display purposes only and are **never uploaded to servers or stored by Amplify.**
*   **Accessibility:** The app must adhere to standard accessibility guidelines (WCAG 2.1), including support for screen readers and high-contrast text options.
*   **Platform:** The initial release will be for iOS.

### 7. Success Metrics
*   **Engagement:** Daily Active Users (DAU), average number of recordings per user/week.
*   **Retention:** D1, D7, and D30 retention rates.
*   **User Satisfaction:** App Store ratings and qualitative reviews.
*   **Feature Adoption:** Click-through rate on the "Save to my Toolkit" button.

### 8. Assumptions & Risks
*   **Assumption:** Users are willing to use voice input and are comfortable with an AI analyzing their speech.
*   **Technical Risk:** The quality and nuance of the AI amplification are critical. If the polished version feels generic, inauthentic, or misses the user's point, it will break the core value proposition.
*   **User Experience Risk:** The AI's feedback must be framed positively and constructively. A critical or robotic tone could discourage users.

### 9. Future Work (Post v1.0)
*   **Learning Paths:** Curated programs focused on specific goals (e.g., "Interview Prep," "Presentation Skills").
*   **Advanced Toolkit:** Introduce more complex frameworks and rhetorical devices.
*   **Community Features:** Allow users to share their amplified stories (with permission) or participate in challenges.
*   **Monetization:** Explore a subscription model (Amplify Pro) for unlimited recordings, advanced analytics, and specialized learning paths.