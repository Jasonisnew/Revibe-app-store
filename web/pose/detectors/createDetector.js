/**
 * createDetector.js — Factory that returns the correct detector instance
 * for a given exercise name.
 *
 * Usage:
 *   import { createDetector } from './createDetector.js';
 *   const detector = createDetector('squat');
 *   // per frame:
 *   const result = detector.update(landmarks, performance.now());
 */

import { createSquatDetector } from './squatDetector.js';
import { createLungeDetector } from './lungeDetector.js';
import { createPushUpDetector } from './pushUpDetector.js';
import { createJumpingJackDetector } from './jumpingJackDetector.js';
import { createPlankDetector } from './plankDetector.js';

const REGISTRY = {
  squat:       createSquatDetector,
  lunge:       createLungeDetector,
  pushUp:      createPushUpDetector,
  pushup:      createPushUpDetector,    // alias for convenience
  jumpingJack: createJumpingJackDetector,
  jumpingjack: createJumpingJackDetector,
  plank:       createPlankDetector,
};

/**
 * @param {string} exerciseName  One of: squat, lunge, pushUp, jumpingJack, plank
 * @returns {{ reset(): void, update(landmarks, timestampMs): object }}
 * @throws {Error} if exerciseName is not recognised
 */
export function createDetector(exerciseName) {
  const factory = REGISTRY[exerciseName];
  if (!factory) {
    const valid = Object.keys(REGISTRY).join(', ');
    throw new Error(`Unknown exercise "${exerciseName}". Valid names: ${valid}`);
  }
  return factory();
}

/** List of canonical exercise names (without aliases). */
export const EXERCISE_NAMES = Object.freeze([
  'squat', 'lunge', 'pushUp', 'jumpingJack', 'plank',
]);
