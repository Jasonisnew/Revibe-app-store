import {
  createExerciseTracker,
  processPoseFrame,
  resetTracker,
  EXERCISE_NAMES,
} from './index.js';

/**
 * Mounts a lightweight UI block to test detector states, rep counts, hold time,
 * and feedback in real time.
 *
 * The block is intentionally data-only: you feed landmarks in from your existing
 * MediaPipe callback via `panel.ingestLandmarks(landmarks, timestampMs)`.
 */
export function mountPoseTestBlock(container) {
  if (!container) {
    throw new Error('mountPoseTestBlock requires a container element');
  }

  container.innerHTML = `
    <section style="font-family: system-ui, sans-serif; border: 1px solid #ddd; border-radius: 12px; padding: 16px; max-width: 560px;">
      <h2 style="margin: 0 0 12px;">Pose Test Block</h2>
      <p style="margin: 0 0 12px; color: #555;">
        Select an exercise, then pass MediaPipe pose landmarks to <code>pushPoseLandmarks()</code>.
      </p>
      <div style="display: flex; gap: 8px; align-items: center; margin-bottom: 12px;">
        <label for="exerciseSelect">Exercise:</label>
        <select id="exerciseSelect"></select>
        <button id="resetTrackerBtn" type="button">Reset</button>
      </div>
      <div style="display: grid; grid-template-columns: 140px 1fr; row-gap: 6px; column-gap: 8px; margin-bottom: 12px;">
        <strong>Phase</strong><span id="phaseValue">-</span>
        <strong>Rep Count</strong><span id="repValue">-</span>
        <strong>Hold Time (s)</strong><span id="holdValue">-</span>
        <strong>Pose Valid</strong><span id="validValue">-</span>
        <strong>Feedback</strong><span id="feedbackValue">-</span>
      </div>
      <details>
        <summary>Live Metrics (debug)</summary>
        <pre id="metricsValue" style="background: #f7f7f7; border-radius: 8px; padding: 10px; overflow: auto; margin-top: 8px;">{}</pre>
      </details>
    </section>
  `;

  const select = container.querySelector('#exerciseSelect');
  const resetBtn = container.querySelector('#resetTrackerBtn');
  const phaseValue = container.querySelector('#phaseValue');
  const repValue = container.querySelector('#repValue');
  const holdValue = container.querySelector('#holdValue');
  const validValue = container.querySelector('#validValue');
  const feedbackValue = container.querySelector('#feedbackValue');
  const metricsValue = container.querySelector('#metricsValue');

  for (const exerciseName of EXERCISE_NAMES) {
    const option = document.createElement('option');
    option.value = exerciseName;
    option.textContent = exerciseName;
    select.appendChild(option);
  }

  createExerciseTracker(select.value);

  select.addEventListener('change', () => {
    createExerciseTracker(select.value);
    renderEmpty();
  });

  resetBtn.addEventListener('click', () => {
    resetTracker();
    renderEmpty();
  });

  function renderEmpty() {
    phaseValue.textContent = '-';
    repValue.textContent = '-';
    holdValue.textContent = '-';
    validValue.textContent = '-';
    feedbackValue.textContent = '-';
    metricsValue.textContent = '{}';
  }

  function renderStatus(status) {
    phaseValue.textContent = status.phase ?? '-';
    repValue.textContent = status.repCount ?? '-';
    holdValue.textContent = status.holdTimeMs != null ? (status.holdTimeMs / 1000).toFixed(2) : '-';
    validValue.textContent = String(status.isPoseValid);
    feedbackValue.textContent = status.feedback?.length ? status.feedback.join(', ') : 'Good form';
    metricsValue.textContent = JSON.stringify(status.metrics ?? {}, null, 2);
  }

  function ingestLandmarks(landmarks, timestampMs = performance.now()) {
    const status = processPoseFrame(landmarks, timestampMs);
    renderStatus(status);
    return status;
  }

  renderEmpty();
  return { ingestLandmarks };
}
