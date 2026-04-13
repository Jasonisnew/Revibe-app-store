/**
 * smoothing.js — Exponential Moving Average (EMA) filter for landmark angles.
 *
 * Raw MediaPipe landmarks jitter frame-to-frame. Smoothing the *computed
 * angles/distances* (not raw x/y) keeps the signal stable without delaying
 * spatial data that later thresholds rely on.
 *
 * Usage:
 *   const s = createSmoother(0.35);
 *   const smoothedKneeAngle = s.next('leftKnee', rawKneeAngle);
 */

/**
 * Create an EMA smoother.
 * @param {number} alpha  Smoothing factor in (0, 1]. Higher = less smoothing.
 *                        0.3–0.4 is a good starting point for 30 fps pose data.
 */
export function createSmoother(alpha = 0.35) {
  const state = {};

  return {
    /**
     * Feed a new raw value for a named channel and get the smoothed result.
     * On the first call for a channel the raw value is returned as-is.
     */
    next(channel, rawValue) {
      if (!(channel in state)) {
        state[channel] = rawValue;
        return rawValue;
      }
      const smoothed = state[channel] + alpha * (rawValue - state[channel]);
      state[channel] = smoothed;
      return smoothed;
    },

    /** Get the last smoothed value without advancing. */
    peek(channel) {
      return state[channel] ?? null;
    },

    /** Reset all channels (e.g. on exercise switch). */
    reset() {
      for (const key of Object.keys(state)) delete state[key];
    },
  };
}
