const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const { computeLayout, shouldHide, inTrigger } = require('../src/main/layout');

// Simulated macOS display with Dock on the LEFT (like the user's setup).
const displayDockLeft = {
  bounds: { x: 0, y: 0, width: 1440, height: 900 },
  workArea: { x: 80, y: 25, width: 1360, height: 875 },
};

// Display with no Dock on the sides (Dock at bottom).
const displayDockBottom = {
  bounds: { x: 0, y: 0, width: 1440, height: 900 },
  workArea: { x: 0, y: 25, width: 1440, height: 805 },
};

const PANEL_W = 380;

describe('computeLayout: panel bounds', () => {
  test('top-left places panel flush with workArea left edge', () => {
    const { bounds, side } = computeLayout('top-left', displayDockLeft, PANEL_W);
    assert.equal(bounds.x, 80);
    assert.equal(bounds.y, 25);
    assert.equal(bounds.width, PANEL_W);
    assert.equal(side, 'left');
  });

  test('top-right places panel flush with workArea right edge', () => {
    const { bounds, side } = computeLayout('top-right', displayDockLeft, PANEL_W);
    assert.equal(bounds.x, 80 + 1360 - PANEL_W);
    assert.equal(side, 'right');
  });

  test('bottom-left / bottom-right still span full work-area height', () => {
    const bl = computeLayout('bottom-left', displayDockLeft, PANEL_W).bounds;
    const br = computeLayout('bottom-right', displayDockLeft, PANEL_W).bounds;
    assert.equal(bl.height, 875);
    assert.equal(br.height, 875);
  });
});

describe('computeLayout: trigger zone covers the intended corner', () => {
  test('top-left: (0, 0) is inside trigger', () => {
    const { triggerMin, triggerMax } = computeLayout('top-left', displayDockLeft, PANEL_W);
    assert.ok(inTrigger({ x: 0, y: 0 }, triggerMin, triggerMax));
  });

  test('top-left: (5, 5) — within menu-bar area — is inside trigger', () => {
    const { triggerMin, triggerMax } = computeLayout('top-left', displayDockLeft, PANEL_W);
    assert.ok(inTrigger({ x: 5, y: 5 }, triggerMin, triggerMax));
  });

  test('top-right: far-right corner is inside trigger', () => {
    const { triggerMin, triggerMax } = computeLayout('top-right', displayDockLeft, PANEL_W);
    assert.ok(inTrigger({ x: 1435, y: 2 }, triggerMin, triggerMax));
  });

  test('bottom-right: bottom-right corner is inside trigger', () => {
    const { triggerMin, triggerMax } = computeLayout('bottom-right', displayDockLeft, PANEL_W);
    assert.ok(inTrigger({ x: 1435, y: 895 }, triggerMin, triggerMax));
  });

  test('center of screen is NOT inside any trigger', () => {
    for (const c of ['top-left', 'top-right', 'bottom-left', 'bottom-right']) {
      const { triggerMin, triggerMax } = computeLayout(c, displayDockLeft, PANEL_W);
      assert.ok(!inTrigger({ x: 720, y: 450 }, triggerMin, triggerMax), `center inside ${c} trigger!`);
    }
  });
});

describe('shouldHide: prevents flicker loop by only checking the far side', () => {
  test('top-left panel visible — mouse in Dock area does NOT hide', () => {
    // Regression: earlier bug was `x < panelLeft - 20` → `x < 60` triggered hide for Dock mouse at x=30,
    // but (30, 5) is ALSO in the trigger zone → infinite flicker.
    const { bounds } = computeLayout('top-left', displayDockLeft, PANEL_W);
    assert.equal(shouldHide({ x: 30, y: 5 }, bounds, 'left'), false);
  });

  test('top-left panel visible — mouse far right DOES hide', () => {
    const { bounds } = computeLayout('top-left', displayDockLeft, PANEL_W);
    assert.equal(shouldHide({ x: 600, y: 100 }, bounds, 'left'), true);
  });

  test('top-right panel visible — mouse far left DOES hide', () => {
    const { bounds } = computeLayout('top-right', displayDockLeft, PANEL_W);
    assert.equal(shouldHide({ x: 100, y: 100 }, bounds, 'right'), true);
  });

  test('top-right panel visible — mouse inside panel does NOT hide', () => {
    const { bounds } = computeLayout('top-right', displayDockLeft, PANEL_W);
    assert.equal(shouldHide({ x: bounds.x + 100, y: 100 }, bounds, 'right'), false);
  });
});

describe('shouldHide: suppression grace period after corner switch', () => {
  test('within grace period, hide is suppressed even when mouse is in hide zone', () => {
    // Scenario: user was at top-left, panel visible. They click "右上" in settings.
    // Panel jumps to right side. Mouse is still around x=340 (old panel center).
    // For right-side panel on Dock-left display, bounds.x = 1060 → hide zone is x < 1040.
    // Mouse at x=340 → would hide immediately → bad UX.
    const { bounds, side } = computeLayout('top-right', displayDockLeft, PANEL_W);
    const now = 1_000_000;
    const suppressUntil = now + 2500;

    // Without suppression: would hide
    assert.equal(shouldHide({ x: 340, y: 100 }, bounds, side, now, 0), true);
    // With active suppression: does NOT hide
    assert.equal(shouldHide({ x: 340, y: 100 }, bounds, side, now, suppressUntil), false);
  });

  test('after grace period expires, hide behaves normally', () => {
    const { bounds, side } = computeLayout('top-right', displayDockLeft, PANEL_W);
    const now = 1_000_000;
    const suppressUntil = now - 1; // already expired
    assert.equal(shouldHide({ x: 340, y: 100 }, bounds, side, now, suppressUntil), true);
  });

  test('suppression does not force-show when mouse is in panel area', () => {
    // Even during suppression, a mouse already in the panel area isn't hidden anyway.
    const { bounds, side } = computeLayout('top-right', displayDockLeft, PANEL_W);
    const now = 1_000_000;
    assert.equal(shouldHide({ x: bounds.x + 50, y: 100 }, bounds, side, now, now + 2500), false);
  });

  for (const [from, to] of [
    ['top-left', 'top-right'],
    ['top-right', 'top-left'],
    ['bottom-left', 'bottom-right'],
    ['bottom-right', 'bottom-left'],
  ]) {
    test(`switch ${from} → ${to}: panel stays put during grace window`, () => {
      // Mouse assumed to be where the old panel's settings button was (approx top-right of old panel).
      const { bounds: oldBounds } = computeLayout(from, displayDockLeft, PANEL_W);
      const mouseX = oldBounds.x + 340;    // near the far-right edge of old panel
      const mouseY = 40;                    // near header
      const { bounds: newBounds, side } = computeLayout(to, displayDockLeft, PANEL_W);
      const now = 1_000_000;
      assert.equal(
        shouldHide({ x: mouseX, y: mouseY }, newBounds, side, now, now + 2500),
        false,
        'hide should be suppressed during grace window',
      );
    });
  }
});

describe('Invariant: trigger zone and hide zone do NOT overlap (no flicker loop possible)', () => {
  for (const corner of ['top-left', 'top-right', 'bottom-left', 'bottom-right']) {
    test(`${corner} on Dock-left display`, () => {
      const { bounds, triggerMin, triggerMax, side } = computeLayout(corner, displayDockLeft, PANEL_W);
      // Sample each corner of the trigger zone — none should be a "hide" zone when panel is visible.
      const samples = [
        triggerMin,
        triggerMax,
        { x: triggerMin.x, y: triggerMax.y },
        { x: triggerMax.x, y: triggerMin.y },
      ];
      for (const p of samples) {
        assert.equal(
          shouldHide(p, bounds, side), false,
          `point ${JSON.stringify(p)} is in trigger zone AND hide zone → would cause flicker`,
        );
      }
    });

    test(`${corner} on Dock-bottom display`, () => {
      const { bounds, triggerMin, triggerMax, side } = computeLayout(corner, displayDockBottom, PANEL_W);
      const samples = [triggerMin, triggerMax, { x: triggerMin.x, y: triggerMax.y }, { x: triggerMax.x, y: triggerMin.y }];
      for (const p of samples) {
        assert.equal(shouldHide(p, bounds, side), false,
          `point ${JSON.stringify(p)} overlaps in ${corner}`);
      }
    });
  }
});
