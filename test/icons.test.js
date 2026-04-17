const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// Load icons.js in a Node env that simulates a browser `window`
// (the module assigns Icons to window at the bottom).
global.window = {};
require('../src/renderer/icons.js');
const { icon, ICON_PATHS } = global.window.Icons;

/**
 * Scan HTML and JS sources for every `data-icon="..."` / `Icons.icon('...')` reference,
 * then assert every referenced name exists in ICON_PATHS.
 *
 * This would have caught the missing `settings` icon before ship.
 */
function collectReferencedIconNames() {
  const names = new Set();
  const srcDir = path.join(__dirname, '..', 'src', 'renderer');
  const files = [
    'index.html', 'app.js',
  ].map(f => path.join(srcDir, f));

  for (const file of files) {
    const src = fs.readFileSync(file, 'utf-8');
    // data-icon="foo"
    for (const m of src.matchAll(/data-icon=["']([a-z-]+)["']/g)) names.add(m[1]);
    // Icons.icon('foo', ...)
    for (const m of src.matchAll(/Icons\.icon\(['"]([a-z-]+)['"]/g)) names.add(m[1]);
  }
  return [...names];
}

describe('Icon registry', () => {
  test('every icon referenced in UI is registered in ICON_PATHS', () => {
    const referenced = collectReferencedIconNames();
    const missing = referenced.filter(n => !(n in ICON_PATHS));
    assert.deepEqual(missing, [], `Missing icons: ${missing.join(', ')}`);
  });

  test('icon() returns a valid <svg> string for registered names', () => {
    for (const name of Object.keys(ICON_PATHS)) {
      const out = icon(name, 16);
      assert.match(out, /^<svg[^>]*>.*<\/svg>$/s, `${name} did not render as SVG`);
      assert.match(out, /viewBox="0 0 24 24"/);
    }
  });

  test('icon() returns empty string for unknown name', () => {
    assert.equal(icon('does-not-exist', 16), '');
  });
});
