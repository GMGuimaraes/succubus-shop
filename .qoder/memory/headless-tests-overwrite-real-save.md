---
name: headless-tests-overwrite-real-save
description: Headless Godot probes overwrite the real save unless APPDATA is redirected; no tolerated leak baseline, and headless never starts audio playback
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

**Second leak, cut 2026-10-18 by never starting playback in headless.** A remnant,
intermittent (1 to 3 runs of 5) named `AudioStreamPlaybackMP3` + `AudioStreamMP3`
(`shop_theme_loop.mp3`). Root cause is not the file: `AudioStreamPlayer.stop()` only
*schedules* the playback's destruction on the audio thread, and a probe that calls `quit()`
in the same instant never hands over those frames — so stopping in `_exit_tree()` lowered the
rate (3/5 → 1/5) without curing it. What closes the account is not starting playback where
there is no ear: `_setup_background_music()` in `main.gd` and `play()` in `audio.gd` only call
`play()` when `DisplayServer.get_name() != "headless"`, and probes then read 0 in 6. Measured
and reproducible with `tools/probes/musica.gd` — its `tocando` mode forces the playback and is
the reproduction instrument, never part of the push battery. Shipped builds do play the trail,
so closing the real window can still print the two lines: console noise on a dying process, not
lost progress.

**Cured for real the same day, by dropping MP3.** The user chose WAV over OGG (no converter
exists in this environment and `tools/generate_audio.py` synthesizes WAV natively).
`assets/shop_theme_loop.mp3` is deleted; the trail is now `audio/shop_theme_loop.wav`
(`compress/mode=0` raw — the importer's default `mode=2` shrinks `data` ~5×, which silently
corrupts any sample-count arithmetic). Two engine facts measured, not guessed, by dumping
`get_property_list()` in a throwaway probe: the GDScript property is `format`, **not**
`mix_format` (accessing `mix_format` throws `SCRIPT ERROR: Invalid access to property or key`
and leaves the player half-built — that single error was the source of the 2 and 22 leaked
instances the battery was printing), and `AudioStreamWAV.loop_end = 0` is *not* "to the end":
with `LOOP_FORWARD` the playback wraps at sample 0 and stalls, so `main.gd` sets
`loop_end = floori(get_length() * mix_rate) - 1`. `tools/probes/musica.gd` now asserts the
loop point, so this class of bug cannot come back silently. After the fix, `musica`,
`contrato` and `idioma` all close with zero error lines **and** zero leak lines.
