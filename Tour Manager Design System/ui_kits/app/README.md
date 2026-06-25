# Tour Manager — App UI Kit

High-fidelity recreation of the **Tour Manager** day-of-show app for tour managers and
production crew. Three core surfaces, click-through between them via the left rail.

> Note: no production codebase or Figma was provided — these screens realize the
> **proposed** Tour Manager brand direction (see root `readme.md`). They are visual
> recreations meant to compose the design-system primitives, not a copy of a shipped app.

## Screens
- **`DaySheet.jsx`** — the day sheet: run-of-show timeline, crew tab, production notes,
  a "next up" pass card and live alerts. The default screen.
- **`RoutingMap.jsx`** — the tour route as a vertical "road" with a poster map panel and
  a next-move brief. (Map is a stylized node strip, not a real geographic map.)
- **`Dashboard.jsx`** — management overview: tour-wide metric tiles, advancing progress
  bars, crew-on-duty and a priority alert.

## Composition
- Shell + chrome: `AppShell.jsx` (left rail + stage topbar).
- Shared bits: `parts.jsx` (`Icon` via Lucide CDN, `Overline`, `Display`, `Pass`).
- Fake data: `data.js` (`window.TOUR`).
- Primitives come from the design-system bundle: `Button`, `SignalChip`, `StampCard`,
  `Tabs`, `Field` via `window.TourManagerDesignSystem_de0276`.

## Run
Open `index.html`. It loads React + Babel + `_ds_bundle.js` + Lucide, then the sibling
JSX screens (each registers on `window`). `Boot` waits for them before rendering.

## Icons
Lucide (`lucide@0.460.0` UMD) — **flagged substitution**; swap for the real set when
provided. Stroke-only, 2px, inherit `currentColor`.
