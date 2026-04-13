/**
 * plankDetector.js — Hold-time + posture quality detector for plank.
 *
 * ── Landmarks used ──
 *   LEFT/RIGHT_SHOULDER (11, 12) — body-line start + head-drop reference
 *   LEFT/RIGHT_HIP      (23, 24) — body-line midpoint (sag/pike)
 *   LEFT/RIGHT_KNEE     (25, 26) — extended body-line
 *   LEFT/RIGHT_ANKLE    (27, 28) — body-line end
 *   LEFT/RIGHT_ELBOW    (13, 14) — forearm plank alignment (optional check)
 *   NOSE                (0)      — head drop check
 *
 * ── Detection strategy ──
 *   The plank is an isometric hold, so there are no reps.
 *   Instead we track:
 *     • holdTimeMs   — total milliseconds with acceptable posture
 *     • qualityRatio — goodFrames / totalFrames (0-1)
 *
 *   "Body line" is measured as the deviation of hip-midpoint from the
 *   straight line between shoulder-midpoint and ankle-midpoint.  When
 *   deviation stays within ±GOOD_LINE_MAX° the frame is "good".
 *
 * ── State machine ──
 *   IDLE → ENTERING → HOLD ↔ BAD_FORM
 *
 *   IDLE:      pose not detected / not in plank position
 *   ENTERING:  good form detected, waiting MIN_HOLD_ENTRY_MS to confirm
 *   HOLD:      confirmed good form, timer actively counting
 *   BAD_FORM:  form broke mid-hold, timer paused until corrected
 *
 * ── Form feedback ──
 *   • "Hips too low"    — sag beyond HIP_SAG_THRESHOLD
 *   • "Hips too high"   — pike beyond HIP_PIKE_THRESHOLD
 *   • "Head dropping"   — nose y well below shoulder midpoint y
 *   • "Get into position" — pose not resembling plank yet
 */

import { POSE, getLandmark, midpoint } from '../core/landmarks.js';
import { segmentAngle, distance } from '../core/angles.js';
import { createSmoother } from '../core/smoothing.js';
import { allVisible } from '../core/qualityGuards.js';
import { PLANK, SMOOTHING_ALPHA } from '../config/exerciseThresholds.js';

const CRITICAL_LANDMARKS = [
  POSE.LEFT_SHOULDER, POSE.RIGHT_SHOULDER,
  POSE.LEFT_HIP, POSE.RIGHT_HIP,
  POSE.LEFT_ANKLE, POSE.RIGHT_ANKLE,
];

const PHASE = Object.freeze({ IDLE: 'idle', ENTERING: 'entering', HOLD: 'hold', BAD_FORM: 'badForm' });

export function createPlankDetector() {
  const smoother = createSmoother(SMOOTHING_ALPHA);
  let phase = PHASE.IDLE;
  let holdTimeMs = 0;
  let totalFrames = 0;
  let goodFrames = 0;
  let goodFormSince = null;   // timestamp when continuous good form began (for entry delay)
  let lastFrameAt = null;

  function reset() {
    smoother.reset();
    phase = PHASE.IDLE;
    holdTimeMs = 0;
    totalFrames = 0;
    goodFrames = 0;
    goodFormSince = null;
    lastFrameAt = null;
  }

  function update(landmarks, timestampMs) {
    const feedback = [];
    const isPoseValid = allVisible(landmarks, CRITICAL_LANDMARKS, PLANK.MIN_VISIBILITY);

    if (!isPoseValid) {
      feedback.push('Body not fully visible');
      goodFormSince = null;
      if (phase === PHASE.HOLD) phase = PHASE.BAD_FORM;
      return _result(feedback, {}, isPoseValid);
    }

    const lShoulder = getLandmark(landmarks, POSE.LEFT_SHOULDER);
    const rShoulder = getLandmark(landmarks, POSE.RIGHT_SHOULDER);
    const lHip      = getLandmark(landmarks, POSE.LEFT_HIP);
    const rHip      = getLandmark(landmarks, POSE.RIGHT_HIP);
    const lAnkle    = getLandmark(landmarks, POSE.LEFT_ANKLE);
    const rAnkle    = getLandmark(landmarks, POSE.RIGHT_ANKLE);
    const nose      = getLandmark(landmarks, POSE.NOSE);

    const shoulderMid = midpoint(lShoulder, rShoulder);
    const hipMid      = midpoint(lHip, rHip);
    const ankleMid    = midpoint(lAnkle, rAnkle);

    // Body-line deviation: compare shoulder→hip angle vs shoulder→ankle angle.
    const shoulderToAnkle = segmentAngle(shoulderMid, ankleMid);
    const shoulderToHip   = segmentAngle(shoulderMid, hipMid);
    const rawDev = shoulderToHip - shoulderToAnkle;
    const bodyLineDev = smoother.next('bodyLine', rawDev);

    // Head drop: nose y relative to shoulder midpoint, normalised by torso length.
    const torsoLen = distance(shoulderMid, hipMid) || 1;
    let headDrop = 0;
    if (nose) {
      headDrop = (nose.y - shoulderMid.y) / torsoLen;
    }

    const metrics = { bodyLineDev, headDrop };

    totalFrames++;

    // Classify this frame
    const isSagging = bodyLineDev > PLANK.HIP_SAG_THRESHOLD;
    const isPiking  = bodyLineDev < -PLANK.HIP_PIKE_THRESHOLD;
    const isHeadDrop = headDrop > PLANK.HEAD_DROP_RATIO;
    const isGoodForm = !isSagging && !isPiking && !isHeadDrop;

    if (isSagging) feedback.push('Hips too low');
    if (isPiking)  feedback.push('Hips too high');
    if (isHeadDrop) feedback.push('Head dropping');

    if (isGoodForm) {
      goodFrames++;

      if (goodFormSince === null) {
        goodFormSince = timestampMs;
      }

      if (phase === PHASE.IDLE || phase === PHASE.ENTERING) {
        // Must hold good form for MIN_HOLD_ENTRY_MS before timer starts
        const heldFor = timestampMs - goodFormSince;
        if (heldFor >= PLANK.MIN_HOLD_ENTRY_MS) {
          phase = PHASE.HOLD;
          lastFrameAt = timestampMs;
        } else {
          phase = PHASE.ENTERING;
        }
      } else if (phase === PHASE.BAD_FORM || phase === PHASE.HOLD) {
        if (phase === PHASE.BAD_FORM) {
          // Returning from bad form — anchor lastFrameAt so we don't
          // count the time spent in bad form
          lastFrameAt = timestampMs;
        }
        phase = PHASE.HOLD;

        // Accumulate hold time based on actual elapsed time since last frame
        if (lastFrameAt !== null) {
          const dt = timestampMs - lastFrameAt;
          if (dt > 0 && dt < 200) {
            holdTimeMs += dt;
          }
        }
        lastFrameAt = timestampMs;
      }
    } else {
      // Bad form — pause the timer and reset the entry gate
      goodFormSince = null;

      if (phase === PHASE.HOLD) {
        phase = PHASE.BAD_FORM;
      } else if (totalFrames <= 5) {
        phase = PHASE.IDLE;
        feedback.push('Get into position');
      } else if (phase !== PHASE.BAD_FORM) {
        phase = PHASE.BAD_FORM;
      }
    }

    return _result(feedback, metrics, isPoseValid);
  }

  function _result(feedback, metrics, isPoseValid) {
    const qualityRatio = totalFrames > 0 ? goodFrames / totalFrames : 0;
    return {
      exercise: 'plank',
      repCount: null,
      holdTimeMs,
      qualityRatio: Math.round(qualityRatio * 100) / 100,
      phase,
      feedback,
      metrics,
      isPoseValid,
    };
  }

  return { reset, update };
}
