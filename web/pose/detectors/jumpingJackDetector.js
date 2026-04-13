/**
 * jumpingJackDetector.js — Rep-counting detector for jumping jacks.
 *
 * ── Landmarks used ──
 *   LEFT/RIGHT_SHOULDER (11, 12) — shoulder width reference
 *   LEFT/RIGHT_WRIST    (15, 16) — arm spread measurement
 *   LEFT/RIGHT_HIP      (23, 24) — hip width reference
 *   LEFT/RIGHT_ANKLE    (27, 28) — leg spread measurement
 *
 * ── Detection strategy ──
 *   Rather than absolute distances (which vary with camera zoom), we use
 *   normalised *ratios*:
 *     armRatio  = wrist-to-wrist distance / shoulder width
 *     legRatio  = ankle-to-ankle distance / hip width
 *
 *   Both ratios must independently agree on "open" or "closed" for a valid
 *   state.  This rejects partial motions (e.g. only arms, no legs).
 *
 * ── State machine ──
 *   CLOSED → OPEN → CLOSED  (rep counted on OPEN→CLOSED transition)
 *
 *   A minimum cycle time debounces very fast oscillations that could
 *   double-count.
 *
 * ── Form feedback ──
 *   • "Raise arms higher"   — arms not reaching open threshold
 *   • "Spread feet wider"   — legs not reaching open threshold
 */

import { POSE, getLandmark } from '../core/landmarks.js';
import { distance } from '../core/angles.js';
import { createSmoother } from '../core/smoothing.js';
import { allVisible, dwellElapsed } from '../core/qualityGuards.js';
import { JUMPING_JACK, SMOOTHING_ALPHA } from '../config/exerciseThresholds.js';

const CRITICAL_LANDMARKS = [
  POSE.LEFT_SHOULDER, POSE.RIGHT_SHOULDER,
  POSE.LEFT_WRIST, POSE.RIGHT_WRIST,
  POSE.LEFT_HIP, POSE.RIGHT_HIP,
  POSE.LEFT_ANKLE, POSE.RIGHT_ANKLE,
];

const PHASE = Object.freeze({ CLOSED: 'closed', OPEN: 'open' });

export function createJumpingJackDetector() {
  const smoother = createSmoother(SMOOTHING_ALPHA);
  let phase = PHASE.CLOSED;
  let repCount = 0;
  let lastTransitionAt = null;

  function reset() {
    smoother.reset();
    phase = PHASE.CLOSED;
    repCount = 0;
    lastTransitionAt = null;
  }

  function update(landmarks, timestampMs) {
    const feedback = [];
    const isPoseValid = allVisible(landmarks, CRITICAL_LANDMARKS, JUMPING_JACK.MIN_VISIBILITY);

    if (!isPoseValid) {
      feedback.push('Body not fully visible');
      return _result(feedback, {}, isPoseValid);
    }

    const lShoulder = getLandmark(landmarks, POSE.LEFT_SHOULDER);
    const rShoulder = getLandmark(landmarks, POSE.RIGHT_SHOULDER);
    const lWrist    = getLandmark(landmarks, POSE.LEFT_WRIST);
    const rWrist    = getLandmark(landmarks, POSE.RIGHT_WRIST);
    const lHip      = getLandmark(landmarks, POSE.LEFT_HIP);
    const rHip      = getLandmark(landmarks, POSE.RIGHT_HIP);
    const lAnkle    = getLandmark(landmarks, POSE.LEFT_ANKLE);
    const rAnkle    = getLandmark(landmarks, POSE.RIGHT_ANKLE);

    const shoulderWidth = distance(lShoulder, rShoulder) || 1;
    const hipWidth      = distance(lHip, rHip) || 1;
    const wristDist     = distance(lWrist, rWrist);
    const ankleDist     = distance(lAnkle, rAnkle);

    const rawArmRatio = wristDist / shoulderWidth;
    const rawLegRatio = ankleDist / hipWidth;

    const armRatio = smoother.next('arm', rawArmRatio);
    const legRatio = smoother.next('leg', rawLegRatio);

    const metrics = { armRatio, legRatio };

    // Determine per-channel open/closed
    const armsOpen   = armRatio >= JUMPING_JACK.ARM_OPEN_RATIO;
    const armsClosed = armRatio <= JUMPING_JACK.ARM_CLOSED_RATIO;
    const legsOpen   = legRatio >= JUMPING_JACK.LEG_OPEN_RATIO;
    const legsClosed = legRatio <= JUMPING_JACK.LEG_CLOSED_RATIO;

    const bothOpen   = armsOpen && legsOpen;
    const bothClosed = armsClosed && legsClosed;

    // --- Form feedback (only in transitional/partial states) ---
    if (phase === PHASE.CLOSED && !bothOpen) {
      if (legsOpen && !armsOpen)  feedback.push('Raise arms higher');
      if (armsOpen && !legsOpen)  feedback.push('Spread feet wider');
    }

    // --- State transitions with cycle debounce ---
    const canTransition = lastTransitionAt === null ||
      dwellElapsed(timestampMs, lastTransitionAt, JUMPING_JACK.MIN_CYCLE_MS);

    if (phase === PHASE.CLOSED && bothOpen && canTransition) {
      phase = PHASE.OPEN;
      lastTransitionAt = timestampMs;
    } else if (phase === PHASE.OPEN && bothClosed && canTransition) {
      phase = PHASE.CLOSED;
      repCount++;
      lastTransitionAt = timestampMs;
    }

    return _result(feedback, metrics, isPoseValid);
  }

  function _result(feedback, metrics, isPoseValid) {
    return {
      exercise: 'jumpingJack',
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
