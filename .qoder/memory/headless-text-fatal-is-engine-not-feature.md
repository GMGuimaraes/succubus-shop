---
name: headless-text-fatal-is-engine-not-feature
description: The intermittent FATAL text-shaping crash in Windows headless probes is an engine issue, not a bug in the font chain — triage by frequency with controls before touching the feature
metadata:
  type: project
---

In `D:\Downloads\succubus-shop`, adding a fresh `Label` of rare glyphs (arrows, box-drawing,
emoji) to a **live game tree** under Windows headless crashes intermittently with a text
shaping FATAL. Measured 2026-10-18: `flat` chain 4/8, `nested` 5/8, `emoji`-only 5/8, **no
font chain at all 5/12** — while ASCII text 0/12 and no-game-scene 0/12 stayed clean. The
shipping route (game + real UI + 200 ticks with the embedded chain) ran 6/6 clean with
`MEDIDA` byte-identical to the clean control. Harness: `tools/probes/fonte_frequencia.gd`
(env `VARIO=none|flat|nested|emoji`).

**Why:** I first "found" a root cause (the flat two-font chain) and was about to rewire it.
The frequency matrix disproved it — the crash reproduces with the feature *off*. Changing
working code to fix an engine flake would have cost the approved color-emoji route.

**How to apply:** One headless process = one sample; never conclude from a single run. Build
a control matrix (feature on/off × benign payload) and count crash rates before editing the
feature. Related: [[probes-are-assets-not-junk]], [[headless-tests-overwrite-real-save]].
