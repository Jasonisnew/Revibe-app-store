/**
 * pushUpDetector.js — Rep-counting detector for push-ups.
 *
 * ── Landmarks used ──
 *   LEFT/RIGHT_SHOULDER (11, 12) — body-line reference
 *   LEFT/RIGHT_ELBOW    (13, 14) — primary bend angle
 *   LEFT/RIGHT_WRIST    (15, 16) — elbow angle endpoint
 *   LEFT/RIGHT_HIP      (23, 24) — body-line sag/pike check
 *   LEFT/RIGHT_ANKLE    (27, 28) — full body-line reference
 *
 * ── Angle rule ──
 *   Elbow angle = angle at elbow formed by shoulder → elbow → wrist.
 *   Body-line angle = deviation of shoulder→hip segment from shoulder→ankle line.
 *
 * ── Best camera angle ──
 *   Side view (perpendicular to the body) gives the clearest elbow bend signal.
 *   Frontal view compresses the depth axis and makes push-up depth harder to read.
 *
 * ── State machine ──
 *   TOP → BOTTOM → TOP  (rep counted on BOTTOM→TOP transition)
 *
 * ── Form feedback ──
 *   • "Go lower"      — elbow angle only partially past threshold
 *   • "Hips sagging"  — hip drops below shoulder-ankle line
 *   • "Hips piking"   — hip rises above shoulder-ankle line
 */

import { POSE, getLandmark, midpoint } from '../core/landmarks.js';
import { angleBetween, segmentAngle } from '../core/angles.js';
import { createSmoother } from '../core/smoothing.js';
import { allVisible, dwellElapsed } from '../core/qualityGuards.js';
import { PUSHUP, SMOOTHING_ALPHA } from '../config/exerciseThresholds.js';

const CRITICAL_LANDMARKS = [
  POSE.LEFT_SHOULDER, POSE.RIGHT_SHOULDER,
  POSE.LEFT_ELBOW, POSE.RIGHT_ELBOW,
  POSE.LEFT_WRIST, POSE.RIGHT_WRIST,
  POSE.LEFT_HIP, POSE.RIGHT_HIP,
];

const PHASE = Object.freeze({ TOP: 'top', BOTTOM: 'bottom' });

export function createPushUpDetector() {
  const smoother = createSmoother(SMOOTHING_ALPHA);
  let phase = PHASE.TOP;
  let repCount = 0;
  let bottomEnteredAt = null;

  function reset() {
    smoother.reset();
    phase = PHASE.TOP;
    repCount = 0;
    bottomEnteredAt = null;
  }

  function update(landmarks, timestampMs) {
    const feedback = [];
    const isPoseValid = allVisible(landmarks, CRITICAL_LANDMARKS, PUSHUP.MIN_VISIBILITY);

    if (!isPoseValid) {
      feedback.push('Body not fully visible');
      return _result(feedback, {}, isPoseValid);
    }

    const lShoulder = getLandmark(landmarks, POSE.LEFT_SHOULDER);
    const rShoulder = getLandmark(landmarks, POSE.RIGHT_SHOULDER);
    const lElbow    = getLandmark(landmarks, POSE.LEFT_ELBOW);
    const rElbow    = getLandmark(landmarks, POSE.RIGHT_ELBOW);
    const lWrist    = getLandmark(landmarks, POSE.LEFT_WRIST);
    const rWrist    = getLandmark(landmarks, POSE.RIGHT_WRIST);
    const lHip      = getLandmark(landmarks, POSE.LEFT_HIP);
    const rHip      = getLandmark(landmarks, POSE.RIGHT_HIP);
    const lAnkle    = getLandmark(landmarks, POSE.LEFT_ANKLE);
    const rAnkle    = getLandmark(landmarks, POSE.RIGHT_ANKLE);

    const shoulderMid = midpoint(lShoulder, rShoulder);
    const hipMid      = midpoint(lHip, rHip);
    const ankleMid    = midpoint(lAnkle, rAnkle);

    // Average elbow angles (left + right)
    const rawLeftElbow  = angleBetween(lShoulder, lElbow, lWrist);
    const rawRightElbow = angleBetween(rShoulder, rElbow, rWrist);
    const rawElbow = (rawLeftElbow + rawRightElbow) / 2;
    const elbowAngle = smoother.next('elbow', rawElbow);

    // Body-line check: compare shoulder→hip angle with shoulder→ankle angle.
    // If hip deviates significantly from the shoulder→ankle line, form is off.
    const shoulderToAnkle = segmentAngle(shoulderMid, ankleMid);
    const shoulderToHip   = segmentAngle(shoulderMid, hipMid);
    const bodyLineDev = shoulderToHip - shoulderToAnkle; // positive = hip below line (sag)

    const metrics = { elbowAngle, bodyLineDev, rawLeftElbow, rawRightElbow };

    // --- Form feedback ---
    if (bodyLineDev > PUSHUP.MAX_HIP_SAG) {
      feedback.push('Hips sagging');
    } else if (bodyLineDev < -PUSHUP.MAX_HIP_PIKE) {
      feedback.push('Hips piking');
    }

    // --- State transitions ---
    if (phase === PHASE.TOP) {
      if (elbowAngle < PUSHUP.ELBOW_BOTTOM_ENTER) {
        phase = PHASE.BOTTOM;
        bottomEnteredAt = timestampMs;
      }
    } else if (phase === PHASE.BOTTOM) {
      if (elbowAngle > PUSHUP.ELBOW_TOP_EXIT &&
          dwellElapsed(timestampMs, bottomEnteredAt, PUSHUP.MIN_REP_DWELL_MS)) {
        phase = PHASE.TOP;
        repCount++;
        bottomEnteredAt = null;
      } else if (elbowAngle > PUSHUP.ELBOW_BOTTOM_ENTER && elbowAngle < PUSHUP.ELBOW_TOP_EXIT) {
        feedback.push('Go lower');
      }
    }

    return _result(feedback, metrics, isPoseValid);
  }

  function _result(feedback, metrics, isPoseValid) {
    return {
      exercise: 'pushUp',
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
