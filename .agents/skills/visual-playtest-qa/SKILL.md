---
name: visual-playtest-qa
description: >-
  Human-like visual inspection and bug diagnosis skill for live Roblox game testing.
  Analyzes screenshots and viewport captures for spatial framing, lighting, geometry clipping,
  anomaly tell observability, UI legibility, and aesthetic horror ambiance.
---

# Visual Playtest QA & Automated Bug Detection Protocol

This skill enforces a human-like visual review methodology during game testing, ensuring that tests evaluate actual rendered visual frames and player experience rather than relying solely on code assumptions or log outputs.

---

## 1. Core Visual Inspection Dimensions

When analyzing game captures (`screen_capture` or viewport photos), evaluate the following 6 core dimensions:

### A. Camera Framing & Avatar Occlusion
* **Perspective Check**: Is the camera positioned at true eye-level?
* **Occlusion Check**: Is the player's own avatar or accessory blocking the countertop, interactive props, or guest character?
* **Field of View**: Are both the desk surface (bell, documents, stamps) and the guest's face/body clearly visible without awkward clipping?

### B. Character Design & Anomaly Observability
* **Normal vs. Anomaly Distinction**: Can a human player instantly tell if a guest has an unnatural visual tell?
* **Facial Expressiveness**: Are facial features (eyes, mouth, head angle, skin tone) crisp and distinct?
* **Morphological Tells**: Are supernatural proportions (elongated limbs, upside-down heads, missing faces, void eyes) stark, eerie, and undeniable?

### C. Lighting, Shading & Horror Atmosphere
* **Contrast & Legibility**: Is the scene dark enough for horror tension while keeping key interactables legible?
* **Directional Spotlights**: Does the overhead reception light cast moody shadows onto the guest?
* **Atmospheric Polish**: Are neon glows, micro-flickers, and spatial depth clearly present?

### D. UI/HUD Non-Intrusiveness
* **Screen Estate**: Does the HUD remain cleanly anchored to the edges (top/bottom) without obstructing the 3D guest in the center?
* **Typography & Styling**: Are fonts retro-styled and high contrast?

### E. Interactive Prop Feedback
* **Prop Placement**: Are the Bell, Guest Ledger, Stamps, and Desk Lamp naturally arranged across the counter?
* **Hitboxes & Prompts**: Are `ProximityPrompt` and `ClickDetector` targets reachable from behind the desk?

### F. Motion & Animation Flow
* **Gait & Pacing**: Do guests walk at a natural pace from the entrance to the counter?
* **Dynamic Tells**: Do twitches, static flickers, or footprint puddles appear in sync with the guest's movement?

---

## 2. Step-by-Step QA Workflow

1. **Capture & Load Frame**: Run `screen_capture` in live Play mode and read the image artifact directly with `view_file`.
2. **Execute Multi-Point Audit**: Run through dimensions A–F systematically.
3. **Log Visual Discrepancies**: Pinpoint exact visual defects (e.g. clipping, darkness, lack of tell distinction, camera misalignment).
4. **Formulate Action Plan**: Produce a targeted list of file edits to resolve visual defects before re-testing.
5. **Verify Resolution**: Re-capture the frame and confirm that the human player experience is completely polished.
