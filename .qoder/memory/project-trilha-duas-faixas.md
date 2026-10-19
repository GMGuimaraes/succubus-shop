---
name: project-trilha-duas-faixas
description: The shop's music is two tracks by user demand (classic MP3 as the daily theme, synthesized WAV for the three misfortunes); re-synthesizing away the MP3 is forbidden and shipping it is a licence decision the owner makes
metadata:
  type: project
---

From 2026-10-19 (commit `b369b15`) Succubus Shop has **two** trail tracks and the situation
picks the shift: the prototype-era `assets/shop_theme_loop.mp3` (91,64 s) plays the daily
salon and all four sectors; the project-synthesized `audio/shop_theme_loop.wav` (45,71 s)
plays only the three misfortunes (door alarm, ruin in the cash book, vicar on the sidewalk).
`_music_situation()` returns a `track` key; `_apply_situation_music()` swaps the stream only
when the shift crosses, so changing rooms moves pitch, never position.

**Why:** the user asked for it in their own words — "a anterior a essa era mais empolgante",
"deixe a musica atual para algumas situações a sua escolha", "essa é bem baixo astral". The
MP3 had been deleted on 2026-10-18 in `e63a5eb` on the theory that the MP3 container caused
the shutdown resource leak; that theory was wrong (the cause is `AudioStreamPlayer.stop()`
scheduling destruction on the audio thread — see [[headless-tests-overwrite-real-save]]), so
the file came back from the repo's own history, byte-identical, not re-recorded.

**How to apply:**
- Never "improve" the audio by replacing the classic MP3 with generated audio again. If a
  change to the trail is needed, keep both files and change only which shift plays which.
- The published pitch/dB table (`tools/probes/porta.gd`, README) must not move: new
  situations set `track`, not numbers.
- **Shipping the MP3 is a licence question, not a build detail.** It entered the repo in
  `cb5b641`, authored Manus (`Co-authored-by: Manus <dev-agent@manus.ai>`), with no recorded
  provenance, and the README still lists "arte, áudio e animação originais com licença
  verificada" as pending shop work. Surface this before any itch.io upload or new tag; the
  owner decides.
- No `alpha.7` tag was cut for this: the user must listen in the editor first. The published
  `v0.1.0-alpha.6` asset is the WAV-only build; the tree builds 2,20 MB heavier per target.
