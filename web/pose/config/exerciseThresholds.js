/**
 * exerciseThresholds.js — Centralised, tunable constants for every detector.
 *
 * All angles in degrees, times in milliseconds, ratios dimensionless.
 * Hysteresis pairs are [enterThreshold, exitThreshold] so a state is entered
 * at one value and only exited at a clearly different value — this prevents
 * flicker around a single boundary.
 */

export const SQUAT = Object.freeze({
  // Knee angle: < DOWN_ENTER → "down"; > UP_EXIT → "up"
  KNEE_DOWN_ENTER:    90,   // enter "down" when knee bends past this
  KNEE_UP_EXIT:       155,  // return to "up" when knee extends past this
  // Torso lean guard (absolute torso-to-vertical deviation)
  MAX_TORSO_LEAN:     45,   // degrees — flag "torso too forward" above this
  // Knee-over-toe: flag when knee x drifts beyond ankle x by this ratio of thigh length
  KNEE_DRIFT_RATIO:   0.15,
  MIN_REP_DWELL_MS:   300,  // minimum time in "down" before counting
  MIN_VISIBILITY:     0.5,
});

export const LUNGE = Object.freeze({
  FRONT_KNEE_DOWN:    100,  // front knee angle to enter "lowered"
  FRONT_KNEE_UP:      155,  // front knee angle to return to "standing"
  BACK_KNEE_MAX:      130,  // back knee should be bent below this in lowered
  // Flag when front knee x goes past front ankle x by this fraction of thigh
  KNEE_OVER_TOE_RATIO: 0.12,
  MIN_DEPTH_Y_RATIO:  0.05, // min hip drop as fraction of torso length
  MIN_REP_DWELL_MS:   350,
  MIN_VISIBILITY:     0.5,
});

export const PUSHUP = Object.freeze({
  ELBOW_BOTTOM_ENTER: 90,   // elbow angle to enter "bottom"
  ELBOW_TOP_EXIT:     155,  // elbow angle to return to "top"
  // Body-line: angle of shoulder→hip segment relative to horizontal
  // Good plank line ≈ 0-15°; sagging/piking beyond these thresholds triggers feedback
  MAX_HIP_SAG:        20,   // degrees below horizontal → "hips sagging"
  MAX_HIP_PIKE:       25,   // degrees above horizontal → "hips piking"
  MIN_REP_DWELL_MS:   250,
  MIN_VISIBILITY:     0.5,
});

export const JUMPING_JACK = Object.freeze({
  // Arm spread: ratio of wrist-to-wrist distance / shoulder width
  ARM_OPEN_RATIO:     2.2,  // arms considered "open" above this
  ARM_CLOSED_RATIO:   1.2,  // arms considered "closed" below this
  // Leg spread: ratio of ankle-to-ankle distance / hip width
  LEG_OPEN_RATIO:     1.8,
  LEG_CLOSED_RATIO:   1.0,
  // Both arm AND leg must agree for a valid open/closed state
  MIN_CYCLE_MS:       200,  // debounce: ignore cycles shorter than this
  MIN_VISIBILITY:     0.4,
});

export const PLANK = Object.freeze({
  // Acceptable body-line angle range (shoulder→hip→ankle alignment)
  GOOD_LINE_MIN:     -10,   // degrees deviation from straight
  GOOD_LINE_MAX:      10,
  // Hip sag/pike beyond these → feedback
  HIP_SAG_THRESHOLD:  15,
  HIP_PIKE_THRESHOLD: 15,
  // Head drop: nose y relative to shoulder midpoint y
  HEAD_DROP_RATIO:    0.08, // flag if nose drops below shoulders by this fraction of torso length
  MIN_HOLD_ENTRY_MS:  500,  // must hold good form for 500 ms before timer starts
  MIN_VISIBILITY:     0.5,
});

/**
 * Global smoothing alpha (EMA).  Lower = smoother but laggier.
 * Per-exercise overrides can be added later.
 */
export const SMOOTHING_ALPHA = 0.35;
