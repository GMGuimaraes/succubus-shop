---
name: headless-tests-overwrite-real-save
description: Headless Godot probes overwrite the real save unless APPDATA is redirected; since 2026-10-17 there is no tolerated leak baseline any more
metadata:
  type: project
---

Running the Succubus Shop scene headless (`main.tscn` instantiated by a probe) calls
`_save_game()` and writes the real save. Every probe must therefore run with
`APPDATA=D:\Downloads\tmp-userdata` so the save lands under
`D:/Downloads/tmp-userdata/Godot/app_userdata/Succubus Shop/` instead of
`%APPDATA%/Godot/app_userdata/Succubus Shop/`.

**Why:** the user plays this game and a probe silently rolling back their progress is
unrecoverable work loss. The hash of the real save is recorded before the first probe of a
session and re-checked at the end.

**How to apply:** before any command that instantiates the game, capture
`md5sum "$APPDATA/Godot/app_userdata/Succubus Shop/succubus_shop_save.cfg"`; run the probe
with the disposable APPDATA; assert the new save appeared under `D:/Downloads/tmp-userdata/`
(the gate fails open — if it did not, stop and redo the isolation before continuing);
re-check the real hash at the end. If the hash moved, do not hand-edit the `.cfg`: revert
through the game itself and report the deviation.

**No tolerated error baseline since 2026-10-17.** Every smoke used to print
`WARNING: 2 ObjectDB instances were leaked at exit` + `ERROR: 1 resources still in use at
exit`, blamed on `res://assets/shop_theme_loop.mp3`. That attribution was wrong: run the
probe with `--verbose` and it prints the actual names — `res://audio/rare.wav` plus its
`AudioStreamPlaybackWAV`, left alive because the tree died with an effect still playing.
Fixed by `_exit_tree()` in `audio.gd` (stops the SFX pool and clears the stream cache).
A clean run is now a run with **zero** error lines, no `grep -v` exceptions. If a leak line
comes back, treat it as a real regression and re-measure with `--verbose` instead of
re-adding a filter.
