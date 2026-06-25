---
name: tour-manager-design
description: Use this skill to generate well-branded interfaces and assets for Tour Manager, either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colors, type, fonts, assets, and UI kit components for prototyping.
user-invocable: true
---

Read the `readme.md` file within this skill, and explore the other available files.

Tour Manager is a logistics & collaboration app for music artists, tour managers and
production crew — "Day Sheet OS". The brand is a **screenprinted gig poster you can
click**: warm ink + day-sheet paper, electric Klein-blue brand mark, mono "data" type
for times/codes, and signal colors mapped to the run of show. Strict and informative,
but made for creatives.

Key files:
- `styles.css` — the only stylesheet to link; pulls in all tokens, fonts and the poster
  utility classes (`.tm-halftone`, `.tm-grain`, `.tm-duotone`, `.tm-misreg`, `.tm-ruled`).
- `tokens/` — color, type, spacing, effect, motion and poster CSS.
- `components/core/` — `Button`, `SignalChip`, `StampCard`, `Field`, `Tabs` (React).
  Read each `*.prompt.md` for usage.
- `ui_kits/app/` — full Day Sheet / Routing / Dashboard screens to copy from.
- `guidelines/*.card.html` — visual specimens.

If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy assets out
and create static HTML files for the user to view. If working on production code, copy
assets and read the rules here to become an expert in designing with this brand.

If the user invokes this skill without any other guidance, ask them what they want to
build or design, ask some questions, and act as an expert designer who outputs HTML
artifacts _or_ production code, depending on the need.
