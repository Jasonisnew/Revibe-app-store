/**
 * qualityGuards.js — Visibility and plausibility checks on raw landmarks.
 *
 * When critical landmarks are occluded or the user is partially out-of-frame,
 * the detectors should pause counting rather than produce wrong data.
 */

/**
 * Minimum visibility score (0-1) for a landmark to be considered reliable.
 * MediaPipe reports per-landmark visibility; ~0.5 is a reasonable gate.
 */
const DEFAULT_MIN_VISIBILITY = 0.5;

/**
 * Check whether *all* listed landmarks pass the visibility threshold.
 * @param {Array}  landmarks     Full 33-element landmark array.
 * @param {number[]} indices     Landmark indices to check.
 * @param {number} [minVis]      Override the default visibility threshold.
 * @returns {boolean}
 */
export function allVisible(landmarks, indices, minVis = DEFAULT_MIN_VISIBILITY) {
  if (!landmarks) return false;
  for (const idx of indices) {
    const lm = landmarks[idx];
    if (!lm || (lm.visibility ?? 0) < minVis) return false;
  }
  return true;
}

/**
 * Return the lowest visibility among the listed landmarks.
 * Useful for debug overlays and adaptive threshold relaxation.
 */
export function minVisibility(landmarks, indices) {
  if (!landmarks) return 0;
  let worst = 1;
  for (const idx of indices) {
    const v = landmarks[idx]?.visibility ?? 0;
    if (v < worst) worst = v;
  }
  return worst;
}

/**
 * Debounce helper: returns true only if `conditionMs` milliseconds have
 * elapsed since `sinceTs`.  Used to enforce minimum dwell time in a phase
 * before allowing a state transition (prevents double-counting fast reps).
 */
export function dwellElapsed(nowMs, sinceTs, conditionMs) {
  if (sinceTs == null) return false;
  return (nowMs - sinceTs) >= conditionMs;
}
