/**
 * lungeDetector.js — Rep-counting detector for alternating lunges.
 *
 * ── Landmarks used ──
 *   LEFT/RIGHT_HIP   (23, 24) — vertical hip travel & torso reference
 *   LEFT/RIGHT_KNEE  (25, 26) — front/back knee bend
 *   LEFT/RIGHT_ANKLE (27, 28) — knee-over-toe guard
 *   LEFT/RIGHT_SHOULDER (11, 12) — torso length reference
 *
 * ── Detection strategy ──
 *   The detector does NOT require knowing which leg is forward in advance.
 *   It picks the leg with the smaller (more bent) knee angle as the "front"
 *   leg each frame, then applies the front-knee hysteresis rule.
 *
 * ── State machine ──
 *   STANDING → LOWERED → STANDING  (rep counted on LOWERED→STANDING)
 *
 * ── Form feedback ──
 *   • "Go lower"              — front knee barely past entry threshold
 *   • "Front knee past toes"  — front knee x extends beyond ankle x
 */

import { POSE, getLandmark, midpoint } from '../core/landmarks.js';
import { angleBetween, distance } from '../core/angles.js';
import { createSmoother } from '../core/smoothing.js';
import { allVisible, dwellElapsed } from '../core/qualityGuards.js';
import { LUNGE, SMOOTHING_ALPHA } from '../config/exerciseThresholds.js';

const CRITICAL_LANDMARKS = [
  POSE.LEFT_HIP, POSE.RIGHT_HIP,
  POSE.LEFT_KNEE, POSE.RIGHT_KNEE,
  POSE.LEFT_ANKLE, POSE.RIGHT_ANKLE,
];

const PHASE = Object.freeze({ STANDING: 'standing', LOWERED: 'lowered' });

export function createLungeDetector() {
  const smoother = createSmoother(SMOOTHING_ALPHA);
  let phase = PHASE.STANDING;
  let repCount = 0;
  let loweredAt = null;
  let standingHipY = null; // baseline hip-midpoint Y captured in first standing frame

  function reset() {
    smoother.reset();
    phase = PHASE.STANDING;
    repCount = 0;
    loweredAt = null;
    standingHipY = null;
  }

  function update(landmarks, timestampMs) {
    const feedback = [];
    const isPoseValid = allVisible(landmarks, CRITICAL_LANDMARKS, LUNGE.MIN_VISIBILITY);

    if (!isPoseValid) {
      feedback.push('Body not fully visible');
      return _result(feedback, {}, isPoseValid);
    }

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
    const torsoLen    = distance(shoulderMid, hipMid) || 1;

    // Capture standing baseline on first valid frame
    if (standingHipY === null) standingHipY = hipMid.y;

    // Compute both knee angles
    const rawLeftKnee  = angleBetween(lHip, lKnee, lAnkle);
    const rawRightKnee = angleBetween(rHip, rKnee, rAnkle);

    // The more-bent knee is the "front" leg
    const leftIsFront = rawLeftKnee <= rawRightKnee;
    const rawFrontKnee = leftIsFront ? rawLeftKnee : rawRightKnee;
    const rawBackKnee  = leftIsFront ? rawRightKnee : rawLeftKnee;

    const frontKneeAngle = smoother.next('frontKnee', rawFrontKnee);
    const backKneeAngle  = smoother.next('backKnee', rawBackKnee);

    // Hip drop ratio (positive = dropped relative to standing baseline)
    // In image coords, larger Y = lower on screen
    const hipDropRatio = (hipMid.y - standingHipY) / torsoLen;

    const metrics = { frontKneeAngle, backKneeAngle, hipDropRatio, frontLeg: leftIsFront ? 'left' : 'right' };

    // --- Form feedback ---
    const frontKnee  = leftIsFront ? lKnee : rKnee;
    const frontAnkle = leftIsFront ? lAnkle : rAnkle;
    const frontHip   = leftIsFront ? lHip : rHip;
    const thighLen   = distance(frontHip, frontKnee) || 1;
    const kneeDrift  = (frontKnee.x - frontAnkle.x) / thighLen;

    if (Math.abs(kneeDrift) > LUNGE.KNEE_OVER_TOE_RATIO) {
      feedback.push('Front knee past toes');
    }

    // --- State transitions ---
    if (phase === PHASE.STANDING) {
      if (frontKneeAngle < LUNGE.FRONT_KNEE_DOWN) {
        phase = PHASE.LOWERED;
        loweredAt = timestampMs;
      }
    } else if (phase === PHASE.LOWERED) {
      if (frontKneeAngle > LUNGE.FRONT_KNEE_UP &&
          dwellElapsed(timestampMs, loweredAt, LUNGE.MIN_REP_DWELL_MS)) {
        phase = PHASE.STANDING;
        repCount++;
        loweredAt = null;
        standingHipY = hipMid.y; // re-calibrate baseline
      } else if (frontKneeAngle > LUNGE.FRONT_KNEE_DOWN && frontKneeAngle < LUNGE.FRONT_KNEE_UP) {
        feedback.push('Go lower');
      }
    }

    return _result(feedback, metrics, isPoseValid);
  }

  function _result(feedback, metrics, isPoseValid) {
    return {
      exercise: 'lunge',
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
