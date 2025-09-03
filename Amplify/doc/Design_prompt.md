## Product Vision

**The Problem:** Millions of people have valuable ideas but struggle to express them spontaneously and with impact. They feel their communication is "dry" or "simple," leading to a lack of confidence in presentations, meetings, and social situations. The path to improvement is unclear, unstructured, and lacks immediate feedback.

**The Vision:** Amplify is a mobile AI communication coach that transforms how people practice and improve their storytelling. By providing a safe space to practice and instant, constructive feedback, Amplify empowers users to bridge the gap between their thoughts and their words, building the competence and confidence needed to become compelling communicators.



### **Design Philosophy: "Capture, Cook, Comprehend"**

Our design will be guided by a three-part philosophy that mirrors the user's journey:

*   **Capture:** The initial interaction will be effortless and inviting, encouraging users to capture their thoughts with minimal friction.
*   **Cook:** The processing phase will be a moment of delight and anticipation, transforming a simple recording into something more.
*   **Comprehend:** The final output will be clear, insightful, and easy to consume, providing genuine value to the user.

---

### **1. Permission Requests: The "Polite Welcome"**

First impressions are critical. We'll ask for permissions only when they are needed, explaining the value proposition clearly and concisely.

**User Flow:**

1.  **Welcome Screen:** A single screen with a beautiful, abstract animation and a clear, concise headline: "Give your photos a voice."
2.  **Initial Interaction:** The user is immediately presented with the home screen. Upon the first tap of the "record" button, the system will trigger the necessary permission prompts.
3.  **Permission Rationale:** We will use the system's built-in rationale prompts to explain *why* we need access.
    *   **Photo Library:** "To surprise you with a photo from your memories."
    *   **Microphone:** "To record your story for the photo."

**UI Components & Motion:**

| Component          | Description                            | Motion & Haptics                          |
| ------------------ | -------------------------------------- | ----------------------------------------- |
| **System Prompts** | Native iOS/Android permission dialogs. | Standard system-level haptics will apply. |

---

### **2. Home Page: "The Spark of Inspiration"**

The home page is designed to be simple and focused, with a clear call to action.

**User Flow:**

1.  After permissions are granted, the app displays a large photo card.
2.  A prominent record button is centered at the bottom, inviting the user to speak.

**UI Components & Motion:**

| Component         | Description                                                  | Motion & Haptics                                             |
| ----------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **Photo Card**    | A large, rounded-corner card that displays a random photo from the user's library. It will have a subtle inner shadow to give it depth. | **On Load:** The photo card will gently fade and scale into view. **Swipe:** Users can swipe left or right on the card to load a new random photo, accompanied by a light haptic "thump" with each new photo. |
| **Record Button** | A large, circular button with a microphone icon. It will have a soft, pulsating glow to indicate it's ready. | **On Tap:** A quick, crisp haptic tap.                       |

---

### **3. Recording & Live Transcription: "The Conversation"**

This is where the magic begins. The transition from the home screen to the recording interface will be fluid and seamless.

**User Flow:**

1.  The user taps the record button.
2.  A bottom sheet gracefully slides up to fill the bottom half of the screen.
3.  Simultaneously, the photo card scales and moves to the top half of the screen.
4.  The record button transforms into a countdown timer.
5.  As the user speaks, a live transcription appears in the bottom sheet.

**UI Components & Motion:**

### **The Choreography of the Animation**

Here is a step-by-step breakdown of the motion from the moment the user taps the record button:

**Initial State:** A large photo card is centered on the screen. A record button is at the bottom.

**Step 1: The Trigger (0 ms)**

*   **User Action:** User taps the record button.
*   **Immediate Feedback:**
    *   **Visual:** The record button visually depresses (scales down to 95% size).
    *   **Haptics:** A single, crisp, light haptic tap (`UIImpactFeedbackGenerator(style: .light)`). This provides instant confirmation that the tap was registered.

**Step 2: The Expansion and Ascent (0 - 350 ms)**

This is the core of the animation where both elements move in perfect concert.

*   **Photo Card Motion:**
    *   The card begins to move vertically upwards towards the top of the screen.
    *   **Simultaneously**, it starts to expand horizontally, its width animating from its initial size towards 100% of the screen width.
    *   **Corner Radius Transformation:** The card's corner radius will change during the animation. It starts with rounded corners on all four sides. As it expands and moves up, the top-left and top-right corner radii will decrease to 0, making them sharp. The bottom-left and bottom-right radii will remain rounded, creating a clean line where it will meet the bottom sheet.

*   **Bottom Sheet Motion:**
    *   The bottom sheet begins sliding up from off-screen.
    *   Its animation speed is perfectly timed with the photo card's movement. The top edge of the bottom sheet should feel like it's "pushing" the bottom edge of the photo card upwards, even though they don't touch.

**Step 3: The Settle (350 - 400 ms)**

This is the final phase that makes the animation feel physical and polished rather than robotic.

*   **The "Docking" Effect:**
    *   Both the photo card and the bottom sheet will use a "spring" or "damped oscillation" easing curve. This means they will slightly overshoot their final position (by 2-3 pixels) and then gently settle back into their final docked state in the center of the screen.
*   **Final Haptic Feedback:**
    *   As both elements "lock" into their final positions, a single, slightly more substantial haptic "thud" occurs (`UIImpactFeedbackGenerator(style: .medium)`). This provides a satisfying sense of completion and confirms that the interface is now ready for the next interaction (recording).

**Final State:** The photo card occupies the full width of the top half of the screen (with sharp top corners). The bottom sheet occupies the bottom half, with the live transcription area and the transformed record button ready to go.

---

### **Visual Summary of the Interaction**

| Component         | State Change (From -> To)                                    | Motion & Easing                                              | Haptics                                                      |
| :---------------- | :----------------------------------------------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| **Record Button** | Icon: Microphone -> Stop Timer<br>State: Default -> Active   | Quick scale-down/up on tap. Border animates for countdown.   | **Tap:** Light, crisp tap.<br>**Countdown:** Pulses at 5s & 1s. |
| **Photo Card**    | Size: Centered, inset card -> Full-width, top 50%<br>Corners: All rounded -> Top sharp, bottom rounded | Moves up while expanding horizontally. Uses a "spring" easing curve to settle. | **On Settle:** A single, satisfying "thud" (shared with bottom sheet). |
| **Bottom Sheet**  | Position: Off-screen -> Bottom 50%                           | Slides up from the bottom, perfectly timed with the card's movement. Also uses a "spring" easing curve. | **On Settle:** A single, satisfying "thud" (shared with photo card). |



| Component              | Description                                                  | Motion & Haptics                                             |
| ---------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **Live Transcription** | Text will appear in real-time in the bottomsheet. Words that are being processed will have a slightly faded look before becoming solid. | **Text Animation:** Each new word will fade in and subtly slide up, creating a gentle, flowing effect. |
| **Countdown Button**   | The record button's border will animate from full to empty over 30 seconds. The microphone icon will be replaced with a stop icon. | **Animation:** A circular wipe animation for the countdown. **Haptics:** A distinct haptic pulse at the 5-second and 1-second marks to provide a non-visual cue that time is running out. |

---

### **4. "Cooking Now": The Delightful Intermission**

This transition is crucial for managing user expectations and adding a touch of brand personality.

**User Flow:**

1.  When the recording finishes, the recording UI fades out.
2.  A full-screen animation appears with the text "Cooking now..."

**UI Components & Motion:**

| Component                 | Description                                                  | Motion & Haptics                                             |
| ------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **Full-Screen Animation** | A beautiful and creative Lottie animation that is on-brand. For example, swirling particles that coalesce into a soundwave. | **Transition:** A smooth cross-fade from the recording screen to the "cooking" animation. **Haptics:** A gentle, continuous, low-frequency hum can be used to provide a sense of background processing. |

---

### **5. Polished Version & Sharp-Insights: "The Reveal"**

This is the payoff for the user. The information is presented in a clear, digestible, and engaging way.

**User Flow:**

1.  After the "cooking" animation, the final screen loads.
2.  The top half features the photo with a media player.
3.  The bottom half contains the timed captions and the "Sharp-Insights."

**UI Components & Motion:**

| Component          | Description                                                  | Motion & Haptics                                             |
| ------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **Media Player**   | The photo is displayed with a clean, minimalistic media player overlaid, including a play/pause button and a progress bar. | **On Interaction:** Tapping the play/pause button will have a crisp haptic feedback. Scrubbing the progress bar will have a subtle, fine-tuned haptic feedback that corresponds to the movement. |
| **Timed Captions** | The full transcription is displayed. As the audio plays, the corresponding word is highlighted. | **Highlighting:** The highlight will have a smooth, fluid transition from word to word, achieved with a subtle background color change or an underline animation. |
| **Sharp-Insights** | This section will be presented as a series of small, digestible cards, each with an icon and a short, insightful sentence. | **On Load:** The insight cards will animate in one by one, with a gentle fade and slide-up effect. A light haptic tap will accompany the appearance of each card, drawing the user's attention down the page. |



