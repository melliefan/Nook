# melliefan.com

Static site for **melliefan** (personal landing) and **Nook** (macOS todo app).
Zero JS framework. One small CSS file. ~3 KB of inline JS for fade-ins.

## Structure

```
website/
├── index.html              # / (Chinese, default)
├── en/index.html           # /en/
├── nook/index.html         # /nook (Chinese)
├── en/nook/index.html      # /en/nook
├── assets/
│   ├── style.css
│   ├── main.js
│   └── favicon.svg
├── robots.txt
└── sitemap.xml
```

## Author assets to drop in (see brief §12)

| Path                                   | Notes                                    |
| -------------------------------------- | ---------------------------------------- |
| `assets/hero-demo.mp4`                 | Mouse-into-corner loop, ≤ 500 KB         |
| `assets/images/hero-screenshot.png`    | Hero still                               |
| `assets/images/screenshot-light-{1-4}.png` | Light-mode screens                   |
| `assets/images/screenshot-dark-{1-4}.png`  | Dark-mode screens                    |
| `assets/images/avatar.jpg`             | Author avatar                            |
| `assets/images/og-cover.png`           | 1200×630 OG card                         |
| `downloads/Nook-1.0.0.dmg`             | Real DMG                                 |

When you drop in real media, replace the `<div class="placeholder">…</div>` blocks
with `<img>` / `<video autoplay muted loop playsinline>` tags. The surrounding
`.hero__visual`, `.shot`, `.work-card__visual`, `.about__avatar` containers already
clip + size correctly.

## Deploy

Cloudflare Pages or Vercel — point the project root at `website/` and you're done.
Routing is filesystem-based so `/nook` and `/en/nook` work out of the box.

## Design rules (don't break)

- Single accent color: `#3A3A48`. Don't add a second.
- `system-ui` only. No web fonts.
- Don't add cookie banners, modals, exit-intent popups, or "trusted by" rows.
- New section copy: ≤ 2 lines of body. Cut hard.
