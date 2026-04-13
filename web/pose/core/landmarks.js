/**
 * landmarks.js — Named indices for MediaPipe Pose's 33-landmark model.
 *
 * Reference: https://developers.google.com/mediapipe/solutions/vision/pose_landmarker
 * The index numbers correspond to the official BlazePose topology.
 * Only the landmarks actually used by the exercise detectors are exported,
 * but the full enum is kept here so new detectors can reference any point.
 */

export const POSE = Object.freeze({
  NOSE:               0,
  LEFT_EYE_INNER:     1,
  LEFT_EYE:           2,
  LEFT_EYE_OUTER:     3,
  RIGHT_EYE_INNER:    4,
  RIGHT_EYE:          5,
  RIGHT_EYE_OUTER:    6,
  LEFT_EAR:           7,
  RIGHT_EAR:          8,
  MOUTH_LEFT:         9,
  MOUTH_RIGHT:       10,
  LEFT_SHOULDER:     11,
  RIGHT_SHOULDER:    12,
  LEFT_ELBOW:        13,
  RIGHT_ELBOW:       14,
  LEFT_WRIST:        15,
  RIGHT_WRIST:       16,
  LEFT_PINKY:        17,
  RIGHT_PINKY:       18,
  LEFT_INDEX:        19,
  RIGHT_INDEX:       20,
  LEFT_THUMB:        21,
  RIGHT_THUMB:       22,
  LEFT_HIP:          23,
  RIGHT_HIP:         24,
  LEFT_KNEE:         25,
  RIGHT_KNEE:        26,
  LEFT_ANKLE:        27,
  RIGHT_ANKLE:       28,
  LEFT_HEEL:         29,
  RIGHT_HEEL:        30,
  LEFT_FOOT_INDEX:   31,
  RIGHT_FOOT_INDEX:  32,
});

/**
 * Helper to retrieve a landmark object { x, y, z, visibility } by index.
 * Returns null when the landmark array is too short or the entry is missing.
 */
export function getLandmark(landmarks, index) {
  if (!landmarks || index < 0 || index >= landmarks.length) return null;
  return landmarks[index] ?? null;
}

/**
 * Midpoint between two landmark objects (useful for hip/shoulder centre).
 */
export function midpoint(a, b) {
  if (!a || !b) return null;
  return {
    x: (a.x + b.x) / 2,
    y: (a.y + b.y) / 2,
    z: ((a.z ?? 0) + (b.z ?? 0)) / 2,
    visibility: Math.min(a.visibility ?? 0, b.visibility ?? 0),
  };
}
