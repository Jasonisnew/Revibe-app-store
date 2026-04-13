/**
 * angles.js — Geometry helpers operating on landmark-like { x, y, z? } objects.
 *
 * All angles are returned in **degrees** (0-180) so threshold constants are
 * human-readable and easy to tune.
 */

/**
 * Angle at vertex B formed by rays BA and BC (2-D, ignores z).
 *
 *   A
 *    \
 *     B --- C
 *
 * Uses atan2 so the result is always in [0, 180].
 */
export function angleBetween(a, b, c) {
  const ba = { x: a.x - b.x, y: a.y - b.y };
  const bc = { x: c.x - b.x, y: c.y - b.y };
  const dot = ba.x * bc.x + ba.y * bc.y;
  const magBA = Math.hypot(ba.x, ba.y);
  const magBC = Math.hypot(bc.x, bc.y);
  if (magBA === 0 || magBC === 0) return 0;
  const cosAngle = Math.max(-1, Math.min(1, dot / (magBA * magBC)));
  return Math.acos(cosAngle) * (180 / Math.PI);
}

/**
 * Signed angle of a segment relative to horizontal (0° = rightward).
 * Useful for torso lean and plank body-line checks.
 * Returns degrees in (-180, 180].
 */
export function segmentAngle(a, b) {
  return Math.atan2(b.y - a.y, b.x - a.x) * (180 / Math.PI);
}

/**
 * Euclidean distance between two points (2-D).
 */
export function distance(a, b) {
  return Math.hypot(a.x - b.x, a.y - b.y);
}

/**
 * Normalised distance: distance / reference length.
 * Removes camera-zoom dependency by expressing distances as a fraction of
 * a body-relative reference (e.g. shoulder width, torso length).
 */
export function normalisedDistance(a, b, refLength) {
  if (!refLength || refLength === 0) return 0;
  return distance(a, b) / refLength;
}
