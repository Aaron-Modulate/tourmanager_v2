# Tour Manager — Design System

> **Day Sheet OS.** A logistics & collaboration app for music artists, tour managers,
> production crew and gig personnel. The promise: *come gig-day, everything you need
> to know is right in front of you.*

This project IS the design system. An automated compiler reads it and ships the
tokens, fonts and components to consuming projects. Consumers link one file: `styles.css`.

## Sources
No codebase, Figma, or brand assets were provided — this system was authored from the
written brief (product description + tone notes). Visuals, names and copy below are an
**original brand direction** proposed for Tour Manager, not a recreation of an existing
product. If real brand materials exist, attach them and we'll reconcile.

---

## The idea: "Day Sheet"
The whole language is built from the artifacts of a touring day: **call sheets, day
sheets, run-of-show, road cases, laminated passes, set lists.** Strict and informative
(times, codes, statuses) but made for creatives — so it's also bold, high-contrast and
a little bit poster. Two worlds:
- **Paper** — warm off-white day-sheet stock for the working app (schedules, lists).
- **Stage** — warm near-black "flight-case" panels for headers, hero moments, live/show states.

---

## CONTENT FUNDAMENTALS — how Tour Manager writes
**Voice:** the calm, exact production manager who's run a thousand shows. Authoritative
and specific, never bossy. Strict about *facts* (times, places, names), warm about *people*.

- **Person:** Address the user as **you**; the app speaks as the crew ("we"), not a faceless brand.
- **Casing:** Sentence case for sentences. **ALL-CAPS MONO** for labels, statuses,
  codes and overlines only (`LOAD IN`, `DAY 014/060`, `AAA`). Never all-caps a full sentence.
- **Times & data are sacred:** 24-hour clock (`19:45`, not 7:45 PM). Always show the
  unit/zone when ambiguous. Numbers are mono.
- **Brevity:** Imperative and short on action surfaces — "Add stop", "Confirm call",
  "Mark loaded". Schedules read like a call sheet, not prose.
- **Tone examples:**
  - Empty state: *"No stops yet. Add the first venue to start the routing."*
  - Confirmation: *"Call time locked for 12:00. Crew notified."*
  - Warning: *"Soundcheck overlaps doors by 15 min. Tighten the run of show?"*
  - Hero/marketing: *"Show night. Everything, front of house."*
- **Emoji:** none. The texture comes from **mono labels, codes and signal chips**, not emoji.
- **Don't:** exclaim, hype, or get cute on operational surfaces. No "Oops!", no "🎉".

---

## VISUAL FOUNDATIONS
**Color.** Warm near-black **Ink** (`--ink-900 #14110F`) and warm **Paper**
(`--paper-100 #F5F1E8`) carry everything. One brand mark: **Marker**, an electric screenprint
**blue** (`--marker-500 #2B4FF0`, Klein-blue energy), used for the primary action, the
logo, and poster ink. A **Signal** set maps the run of show and doubles as the semantic system:
Load-in blue (info), Soundcheck amber (warning), Doors violet (accent), Show green
(success/go), Curfew red (danger). Imagery, when used, should feel **warm, slightly
filmic / low-light** (stage and backstage), not cool or clinical.

**Type.** Three voices — Display **Bricolage Grotesque** (800/700) for poster-loud
headlines; **Archivo** (400–600) for all UI and body; **Space Mono** for the data voice
(times, codes, stamps, overlines). Tight display tracking (`-0.02em`); wide mono tracking
on labels (`0.12–0.24em`).

**Spacing.** 4px grid, gridded and dense like a printed sheet. Generous screen padding
(`--pad-screen 32px`), tight inline gaps.

**Backgrounds.** Flat Paper or Stage color, dressed with the **poster layer**:
halftone dot fields (`.tm-halftone`), subtle paper **grain** (`.tm-grain`), **ruled**
call-sheet hairlines (`.tm-ruled`) and **misregistered** ink type (`.tm-misreg`).
Photography is **duotone** (`.tm-duotone`, ink → brand-blue), warm and filmic. The feel
is a screenprinted gig poster you can click — *balanced*: bold textures and type
throughout, but never at the cost of legibility. No purple/blue web gradients.

**Borders & cards.** Structure comes from **lines, not shadow**. Default border is a
crisp 2px (`--border-2`) on strong elements, 1px hairline on paper. Radii are low and
hardware-ish: **2px stamp** (labels/chips/codes), 8px default (cards/inputs/buttons),
up to 18px for large sheets. Cards are flat with a hairline + tiny `--shadow-sm`.

**The "stamp" / pass motif.** Key brand moments use a **hard offset shadow**
(`--shadow-hard 3px 3px 0 ink`) and occasional slight rotation (laminated-pass energy).
Use deliberately, not everywhere.

**Shadows.** Restrained, warm-tinted (`rgba(20,17,15,…)`). Elevation ladder
xs→pop for menus/dialogs only. Most surfaces sit flat on Paper.

**Motion.** Quick and mechanical — like a board flipping or a stamp landing.
`--dur-fast 140ms` for most UI on `--ease-standard`; `--ease-stamp` for emphatic
confirmations. No idle/looping decoration. Respects `prefers-reduced-motion`.

**Hover / press.** Hover = one step darker (`--brand-hover`, ink lifts) or paper sinks
to `--paper-200`; never opacity-only on text. Press = darker still (`--brand-press`)
plus a 1px translate on stamp-style elements (the "stamp lands"). Focus = 3px
`--marker-500` ring, always visible.

**Transparency / blur.** Sparingly — only for overlays/scrims behind dialogs
(ink at ~55% with light blur). Surfaces are opaque.

---

## ICONOGRAPHY
- **No brand icon set was provided.** The system uses **[Lucide](https://lucide.dev)**
  via CDN as a stand-in — its thin, even ~2px stroke matches the industrial-line feel.
  **Flagged substitution:** swap for the real set when available.
- Style rules: **line icons only**, ~2px stroke, square-ish, no filled/duotone glyphs,
  no color fills (icons inherit text color). Pair icons with mono labels on dense surfaces.
- **No emoji** anywhere. The expressive layer is **signal chips + mono codes**, not pictograms.
- Unicode is fine for true symbols where appropriate (·, →, ✕ for close), kept monospace.

---

## INDEX / manifest
**Foundations**
- `styles.css` — root entry (consumers link this). `@import` list only.
- `tokens/` — `fonts.css`, `colors.css`, `typography.css`, `spacing.css`, `effects.css`, `motion.css`.
- `guidelines/*.card.html` — Design System tab specimen cards (Brand, Colors, Type, Spacing).

**Status of remaining work** (built):
- `components/core/` — reusable React primitives: `Button`, `SignalChip`, `StampCard`,
  `Field`, `Tabs` (each with `.jsx` / `.d.ts` / `.prompt.md`; demo in `core.card.html`).
- `ui_kits/app/` — Tour Manager app screens: `DaySheet`, `RoutingMap`, `Dashboard`
  + `AppShell`, shared `parts.jsx`, `data.js`; interactive `index.html`.
- `SKILL.md` — Agent-Skills wrapper (download to use in Claude Code).
- `tokens/poster.css` — the poster utility layer (halftone / grain / duotone / misreg / ruled).

*Not built (no source provided):* sample slide deck — ask if you want one.

**Namespace** for `@dsCard` / component HTML: `window.TourManagerDesignSystem_de0276`.

## CAVEATS
- **Fonts are Google Fonts stand-ins** (Bricolage Grotesque / Archivo / Space Mono),
  loaded via CDN `@import` in `tokens/fonts.css`. Because they load remotely, the
  compiler reports **0 local font-face files** — that's expected. Supply licensed brand
  fonts to replace them.
- **Icons** are Lucide (CDN) as a substitution — see ICONOGRAPHY.
- Entire brand (name lockup, colors, copy) is a **proposed original direction**, pending
  your real assets.
