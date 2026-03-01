## Overview

This document captures the wireframes shown in the image:

* **Screen A — Home**
* **Screen B — Workout**
* **Screen C — Post Workout Summary**

---

## Screen A — Home

### Purpose

Get users into a workout immediately & viewing their daily streaks.

### User Intent

* “What movements can this help with?”
* “Which one can I try now?”
* “Did I keep my streak?”

### What users can see

* Simple greeting
* Current streak number (e.g., 🔥 **3-day streak**)
* A horizontal grid of movement cards (**2–3 total**), such as:

  * **Lateral Raise** *(Available)*
  * **Shoulder External Rotation** *(Locked)*
  * **Squat Pattern** *(Locked)*
* Each movement card includes:

  * Movement name
  * Simple illustration or icon
  * Status:

    * **Available**
    * 🔒 **Locked** (e.g., “Coming soon”)

### What users can do

* Start session of selected movement (**go to Screen B**)

### Wireframe (layout)

```text
┌──────────────────────────────────────────────┐
│ Screen A - Home                              │
│                                              │
│ Hello User! 👋                                │
│ You ready for today's session                │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │ 🔥 3-day streak                           │ │
│ │ keep up the work!                         │ │
│ └──────────────────────────────────────────┘ │
│                                              │
│ Movement                                     │
│                                              │
│ ┌──────────────────────┐  ┌─────────────────┐│
│ │ Lateral Raise         │  │ Shoulder External││
│ │ [Available]           │  │ Rotation         ││
│ │                      │  │ [Locked] 🔒       ││
│ │      [ pic ]         │  │      [ pic ]      ││
│ │                      │  │                  ││
│ │ [ Start Session ]     │  │ [ Start Session ] ││
│ └──────────────────────┘  └─────────────────┘│
└──────────────────────────────────────────────┘
```

### Notes / States

* **Locked** cards appear visually disabled (e.g., greyed), but still visible to encourage progression.

---

## Screen B — Workout

### Purpose

Let users perform the selected rehab movement while receiving real-time visual form correction.

### User Intent

* “Am I doing this right?”
* “Tell me when to adjust.”
* “Show me the progress.”

### What users can see

* Live front-camera feed
* Skeleton or landmark overlay
* One fixed visual reference (e.g., shoulder-height line)
* Large, high-contrast feedback text, such as:

  * “Raise arms higher”
  * “Lower arms slightly”
  * “Good”
* Instruction cue

### What users can do

* Perform the movement continuously
* Adjust form based on feedback
* Tap **End Session** at any time (or exit/back)

### Wireframe (layout)

```text
┌──────────────────────────────────────────────┐
│ Screen B - Workout                            │
│ ←  Lateral Raise                              │
│                                              │
│ Raise Higher!                                 │
│ Don't give up!                                │
│                                              │
│ [ Progress Bar ▓▓▓▓▓▓▓▓▓▓▓ ]           100%   │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │                                          │ │
│ │   (Live camera feed + landmark overlay)  │ │
│ │              [skeleton]                  │ │
│ │                                          │ │
│ │                              ┌─────────┐ │ │
│ │                              │ 🔍 pic  │ │ │
│ │                              └─────────┘ │ │
│ └──────────────────────────────────────────┘ │
│                                              │
│   ○ (end/back)     [   Complete   ]      ○→   │
└──────────────────────────────────────────────┘
```

### Notes / States

* Feedback text should be **high contrast** and readable while moving.
* “Complete” implies the movement/session finished successfully.

---

## Screen C — Post Workout Summary

### Purpose

Create a clear psychological finish line.

### User Intent

* “I’m done.”
* “Did this count?”

### What users can see

* “Session Complete” confirmation
* Updated streak number (e.g., 🔥 **4-day streak**)
* One primary action: **Done**

### What users can do

* Acknowledge completion
* Return to Home screen

### Wireframe (layout)

```text
┌──────────────────────────────────────────────┐
│ Screen C - Post Workout Summary               │
│                                              │
│                 ✓                            │
│             Task Complete                     │
│          You crush it today!                  │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │ Your 4-day streak                         │ │
│ │ ■ ■ ■ ■ □ □ □                             │ │
│ └──────────────────────────────────────────┘ │
│                                              │
│ Time: 30:02          KCal: 100                │
│                                              │
│                [   DONE   ]                   │
└──────────────────────────────────────────────┘
```
