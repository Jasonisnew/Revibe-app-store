/**
 * web/pose/index.js — Public entry point for the MediaPipe exercise tracker.
 *
 * Thin wrapper that manages the active detector and exposes two functions:
 *
 *   createExerciseTracker(exerciseName)
 *     → Initialises (or switches) the active detector.
 *
 *   processPoseFrame(landmarks, timestampMs)
 *     → Feeds one MediaPipe Pose result into the active detector and returns
 *       the uniform payload { exercise, repCount, holdTimeMs, phase, feedback,
 *       metrics, isPoseValid }.
 *
 * Integration example (inside a MediaPipe onResults callback):
 *
 *   import { createExerciseTracker, processPoseFrame } from './web/pose/index.js';
 *
 *   createExerciseTracker('squat');
 *
 *   function onPoseResults(results) {
 *     const landmarks = results.poseLandmarks;  // 33-element array
 *     const status = processPoseFrame(landmarks, performance.now());
 *     console.log(status.repCount, status.phase, status.feedback);
 *   }
 */

import { createDetector, EXERCISE_NAMES } from './detectors/createDetector.js';

let activeDetector = null;
let activeExercise = null;

/**
 * Create (or replace) the active exercise detector.
 * Calling with the same exercise name resets the detector.
 *
 * @param {string} exerciseName  One of: squat, lunge, pushUp, jumpingJack, plank
 * @returns {string} The canonical exercise name now active.
 */
export function createExerciseTracker(exerciseName) {
  activeDetector = createDetector(exerciseName);
  activeExercise = exerciseName;
  return activeExercise;
}

/**
 * Feed one frame of MediaPipe Pose landmarks into the active detector.
 *
 * @param {Array<{x:number, y:number, z?:number, visibility?:number}>} landmarks
 *   The 33-element poseLandmarks array from MediaPipe Pose.
 * @param {number} timestampMs
 *   Frame timestamp (use performance.now() or the MediaPipe result timestamp).
 * @returns {object} Uniform status payload from the active detector.
 * @throws {Error} If no tracker has been created yet.
 */
export function processPoseFrame(landmarks, timestampMs) {
  if (!activeDetector) {
    throw new Error(
      'No exercise tracker active. Call createExerciseTracker(name) first.'
    );
  }
  return activeDetector.update(landmarks, timestampMs);
}

/**
 * Reset the active detector's state (reps, hold time, phase) without
 * switching exercises.
 */
export function resetTracker() {
  if (activeDetector) activeDetector.reset();
}

/** Returns the currently active exercise name, or null. */
export function getActiveExercise() {
  return activeExercise;
}

/** Re-export the list of supported exercise names for UI consumption. */
export { EXERCISE_NAMES };
