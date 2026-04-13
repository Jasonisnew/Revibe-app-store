/**
 * squatDetector.js — Rep-counting detector for bodyweight squats.
 *
 * ── Landmarks used ──
 *   LEFT/RIGHT_SHOULDER (11, 12) — torso lean reference
 *   LEFT/RIGHT_HIP      (23, 24) — torso angle + depth reference
 *   LEFT/RIGHT_KNEE     (25, 26) — primary bend angle
 *   LEFT/RIGHT_ANKLE    (27, 28) — knee-over-toe guard
 *
 * ── Angle rule ──
 *   Knee angle = angle at knee formed by hip → knee → ankle.
 *   Smaller angle = deeper squat.
 *
 * ── State machine ──
 *   READY → UP → DOWN → UP  (rep counted on DOWN→UP transition)
 *
 *   Hysteresis prevents flicker:
 *     Enter DOWN when kneeAngle < KNEE_DOWN_ENTER (90°)
 *     Return to UP when kneeAngle > KNEE_UP_EXIT  (155°)
 *
 * ── Form feedback ──
 *   • "Squat deeper"          — entered DOWN but angle barely passed threshold
 *   • "Torso too far forward" — shoulder-hip segment leans > MAX_TORSO_LEAN°
 *   • "Knees drifting forward" — knee x beyond ankle x by KNEE_DRIFT_RATIO
 */

import { POSE, getLandmark, midpoint } from '../core/landmarks.js';
import { angleBetween, segmentAngle, distance } from '../core/angles.js';
import { createSmoother } from '../core/smoothing.js';
import { allVisible, dwellElapsed } from '../core/qualityGuards.js';
import { SQUAT, SMOOTHING_ALPHA } from '../config/exerciseThresholds.js';

const CRITICAL_LANDMARKS = [
  POSE.LEFT_HIP, POSE.RIGHT_HIP,
  POSE.LEFT_KNEE, POSE.RIGHT_KNEE,
  POSE.LEFT_ANKLE, POSE.RIGHT_ANKLE,
  POSE.LEFT_SHOULDER, POSE.RIGHT_SHOULDER,
];

const PHASE = Object.freeze({ READY: 'ready', UP: 'up', DOWN: 'down' });

export function createSquatDetector() {
  const smoother = createSmoother(SMOOTHING_ALPHA);
  let phase = PHASE.READY;
  let repCount = 0;
  let downEnteredAt = null;

  function reset() {
    smoother.reset();
    phase = PHASE.READY;
    repCount = 0;
    downEnteredAt = null;
  }

  function update(landmarks, timestampMs) {
    const feedback = [];
    const isPoseValid = allVisible(landmarks, CRITICAL_LANDMARKS, SQUAT.MIN_VISIBILITY);

    if (!isPoseValid) {
      feedback.push('Body not fully visible');
      return _result(feedback, {}, isPoseValid);
    }

    // --- Compute key angles ---
    const lHip   = getLandmark(landmarks, POSE.LEFT_HIP);
    const rHip   = getLandmark(landmarks, POSE.RIGHT_HIP);
    const lKnee  = getLandmark(landmarks, POSE.LEFT_KNEE);
    const rKnee  = getLandmark(landmarks, POSE.RIGHT_KNEE);
    const lAnkle = getLandmark(landmarks, POSE.LEFT_ANKLE);
    const rAnkle = getLandmark(landmarks, POSE.RIGHT_ANKLE);
    const lShoulder = getLandmark(landmarks, POSE.LEFT_SHOULDER);
    const rShoulder = getLandmark(landmarks, POSE.RIGHT_SHOULDER);

    const hipMid      = midpoint(lHip, rHip);
    const shoulderMid = midpoint(lShoulder, rShoulder);

    // Average left/right knee angles for symmetry
    const rawLeftKnee  = angleBetween(lHip, lKnee, lAnkle);
    const rawRightKnee = angleBetween(rHip, rKnee, rAnkle);
    const rawKnee = (rawLeftKnee + rawRightKnee) / 2;

    const kneeAngle = smoother.next('knee', rawKnee);

    // Torso lean: angle of shoulder→hip segment relative to vertical (90° = vertical in image space)
    const rawTorsoAngle = Math.abs(segmentAngle(shoulderMid, hipMid) - (-90));
    const torsoLean = smoother.next('torso', rawTorsoAngle);

    const metrics = { kneeAngle, torsoLean, rawLeftKnee, rawRightKnee };

    // --- Form feedback ---
    if (torsoLean > SQUAT.MAX_TORSO_LEAN) {
      feedback.push('Torso too far forward');
    }

    // Knee-over-toe check (average of both sides)
    const thighLen = (distance(lHip, lKnee) + distance(rHip, rKnee)) / 2;
    const leftDrift  = (lKnee.x - lAnkle.x) / (thighLen || 1);
    const rightDrift = (rKnee.x - rAnkle.x) / (thighLen || 1);
    if (Math.abs(leftDrift) > SQUAT.KNEE_DRIFT_RATIO ||
        Math.abs(rightDrift) > SQUAT.KNEE_DRIFT_RATIO) {
      feedback.push('Knees drifting forward');
    }

    // --- State transitions ---
    if (phase === PHASE.READY || phase === PHASE.UP) {
      if (kneeAngle < SQUAT.KNEE_DOWN_ENTER) {
        phase = PHASE.DOWN;
        downEnteredAt = timestampMs;
      }
    } else if (phase === PHASE.DOWN) {
      if (kneeAngle > SQUAT.KNEE_UP_EXIT &&
          dwellElapsed(timestampMs, downEnteredAt, SQUAT.MIN_REP_DWELL_MS)) {
        phase = PHASE.UP;
        repCount++;
        downEnteredAt = null;
      } else if (kneeAngle > SQUAT.KNEE_DOWN_ENTER && kneeAngle < SQUAT.KNEE_UP_EXIT) {
        feedback.push('Squat deeper');
      }
    }

    return _result(feedback, metrics, isPoseValid);
  }

  function _result(feedback, metrics, isPoseValid) {
    return {
      exercise: 'squat',
      repCount,
      holdTimeMs: null,
      phase,
      feedback,
      metrics,
      isPoseValid,
    };
  }

  return { reset, update };
}
