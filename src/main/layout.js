/**
 * Pure layout math — no Electron dependency, fully testable.
 *
 * computeLayout(corner, display, panelWidth, triggerSize) → { bounds, triggerMin, triggerMax, side }
 *
 * corner: 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right'
 * display: { bounds: {x,y,width,height}, workArea: {x,y,width,height} }
 *   - bounds = full screen
 *   - workArea = screen minus menu bar and Dock
 */
function computeLayout(corner, display, panelWidth = 380, triggerSize = 8, heightRatio = 1) {
  const work = display.workArea;
  const full = display.bounds;

  const side = corner.endsWith('-right') ? 'right' : 'left';
  const isBottom = corner.startsWith('bottom');
  const h = Math.max(300, Math.round(work.height * Math.min(1, Math.max(0.2, heightRatio))));

  const bounds = {
    x: side === 'left' ? work.x : work.x + work.width - panelWidth,
    y: isBottom ? work.y + work.height - h : work.y,
    width: panelWidth,
    height: h,
  };

  // Trigger zones extend inward from workArea corners.
  // This keeps them within the display, avoiding overlap with adjacent monitors.
  let triggerMin, triggerMax;
  if (corner === 'top-left') {
    triggerMin = { x: full.x, y: full.y };
    triggerMax = { x: work.x + triggerSize, y: work.y + triggerSize };
  } else if (corner === 'top-right') {
    triggerMin = { x: work.x + work.width - triggerSize, y: full.y };
    triggerMax = { x: full.x + full.width, y: work.y + triggerSize };
  } else if (corner === 'bottom-left') {
    triggerMin = { x: full.x, y: work.y + work.height - triggerSize };
    triggerMax = { x: work.x + triggerSize, y: full.y + full.height };
  } else {
    triggerMin = { x: work.x + work.width - triggerSize, y: work.y + work.height - triggerSize };
    triggerMax = { x: full.x + full.width, y: full.y + full.height };
  }

  return { bounds, triggerMin, triggerMax, side };
}

/**
 * Should hide the panel given current mouse position?
 */
function shouldHide(point, bounds, side, nowMs = Date.now(), suppressUntilMs = 0) {
  if (nowMs < suppressUntilMs) return false;
  if (side === 'left') {
    return point.x > bounds.x + bounds.width + 20;
  } else {
    return point.x < bounds.x - 20;
  }
}

/**
 * Is the point inside the trigger zone?
 */
function inTrigger(point, triggerMin, triggerMax) {
  return point.x >= triggerMin.x && point.x <= triggerMax.x &&
         point.y >= triggerMin.y && point.y <= triggerMax.y;
}

module.exports = { computeLayout, shouldHide, inTrigger };
