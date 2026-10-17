---
name: headless-tests-overwrite-real-save
description: Headless Godot runs in Succubus Shop write to the user's real %APPDATA% save — isolate or avoid code paths that call _save_game
metadata:
  type: feedback
---

Before running any headless Godot script in this project, check whether the code path calls `_save_game()` (or `ConfigFile.save`). Most gameplay functions end with `_save_game()`, so exercising one in a probe writes to the user's real progress at `%APPDATA%\Godot\app_userdata\Succubus Shop\succubus_shop_save.cfg` — and `audio.gd` similarly persists to `audio_settings.cfg`. Prefer: run pure logic checks (`--check-only`), or point the probe at a throwaway save path before calling into game code.

**Why:** On 2026-10-13 a probe that called `_activate_sector_feature` silently overwrote the user's save with test rewards (+6 XP, +1 reputation, +2 affection, -1 fury) and reset their volume to the probe's value. Recovery meant hand-computing the delta and reversing it, and it was only possible because no level-up occurred.

**How to apply:** Applies to every validation step here, including the pre-push stability check in [[feedback-github-sync-workflow]]. If a probe does touch a save, reverse the exact delta through a Godot script rather than editing the `.cfg` by hand — direct edits to files under `%APPDATA%` are blocked and bypass game semantics. - Related: [[project-succubus-shop-repo]].

**The routine that works:** run probes windowed with `APPDATA="D:\\Downloads\\tmp-userdata"` so `user://` resolves into `D:\Downloads\tmp-userdata\Godot\app_userdata\Succubus Shop\`, and `rm -f` that folder's `succubus_shop_save.cfg` before each run so a stale probe save is not read as real progress. Screenshots saved to `user://` land there and can be read back with the Read tool. Point the probe's own `OUT` constant at that same throwaway directory.

**Probe litter is not commit material:** probes are written as repo-root `_tmp_*.gd` (+ generated `.gd.uid`). They pile up fast — 22 of them were sitting in the checkout on 2026-10-15 — and must be deleted before any commit, since AGENTS.md forbids sweeping generated files into a push.

**Known baseline noise (not a regression):** every headless smoke prints `WARNING: 2 ObjectDB instances were leaked at exit` + `ERROR: 1 resources still in use at exit`, caused by `res://assets/shop_theme_loop.mp3` (an `AudioStreamMP3` still referenced at shutdown). A clean run is one whose only error output is that pair — do not chase it or "fix" it as part of unrelated work.

**Making an in-game A/B probe deterministic** (learned while measuring the ten talent specializations, when the control run kept producing different sales/gold each time):
- Never `await` a frame between `_on_customer_tick()` calls — the stage actor rotation consumes RNG driven by *real elapsed frames*, so frames rendered mid-loop change the outcome. Run all ticks back-to-back, then `await` ~40 frames once to settle.
- Call `_reset_run()` and clear the state that survives it (`regular_bonds`, `regular_orders_completed`, `regular_story_progress`, `regular_story_completed`, `regular_arc_seen`, `romance_stage`, `card_counts`, `faction_standing`, `season_baseline`) before each side of an A/B — those cross lives and shift prices.
- `game.spec_choice = some_dict` **aliases** it; `_reset_run()` does `spec_choice.clear()` and silently empties the caller's literal. Always `some_dict.duplicate(true)`.
- Flush `_check_achievements()` and run a throwaway warm-up round first, so achievement payouts don't land on only one side of the measurement; `unlocked_achievements` also persists across probe phases, so `.erase(id)` to re-test a staged condition.
- Print the expected-value lines with decimals (`%+.1f`) — rounding to whole gold hid a real +0.4 gain and read as "no effect".

**`user://` settings files are state too — and they outlive `_reset_run()`.** On
2026-10-16 the `filtro` probe reported the fury seal as `AUSENTE` in both modes with
every economic number matching. Root cause was not the game: `D:\Downloads\tmp-userdata\...\
locale_settings.cfg` still held `language="en"` from an earlier session, `_reset_run()`
does not touch it, and `main.gd` calls `tr()` *before* assigning `.text` on panel labels —
so a probe asserting a Portuguese substring reads absence with zero bug present. Fix
pattern: pin the locale in the probe's shop-building helper right after the `_ready()`
frames and before `_reset_run()` (`g.locale = Locales.DEFAULT`, `g.locale_confirmed =
true`, `TranslationServer.set_locale(Locales.DEFAULT)` in the real helper). General rule:
anything the engine persists under `user://` (locale, audio, any future preference file)
must be normalized before an A/B, or the measurement is locale-conditional.

**Count-coupled prose goes stale with the achievement table.** The probe headers and the
README quote the number of achievement definitions ("86 definições", "Oitenta e seis
conquistas"). Adding an achievement silently invalidates every header that states the old
count, so those probes have to be re-run and their header verdict rewritten in the *same*
commit as the new achievement — otherwise the committed header is a claim that no longer
matches the code.

**A moved baseline hash is not proof of a leak — check whether the user is playing.** On
2026-10-16 the real save's md5 did not match the value anchored at the start of the window,
with no probe run by me in between. The cause was the user's own session: `tasklist` showed
a live `Godot.exe`, and `%APPDATA%\Godot\app_userdata\Succubus Shop\` had a fresh `logs/godot.log`
plus a save mtime minutes old. Before reporting a write-through, run those two checks (process
list + save/log mtimes vs. the window's own commands) and say plainly which one explains it.
Two consequences: a user instance is up means **do not launch a probe at all** (the gate
assumes one process, and an autosave mid-run shifts the hash again), and the baseline has to
be re-anchored to the current value rather than treated as damage.

**One Godot process at a time.** A second headless instance over the same project races
on `.import`/`user://` writes and makes an isolation assertion meaningless; wait for the
background probe to finish before launching anything else. Same reason: do **not** edit a
`.gd` (even comment-only) while a multi-probe background battery is mid-run — touch only
the probes that already executed, or the next one may load a half-written file.

**Isolation proof does not need the save file to survive.** `tools/probes/fiado.gd` deletes
its own `user://succubus_shop_save.cfg` on exit, so right after a clean run the disposable
folder has no save at all. Assert `user://` resolution from the sibling files the engine
writes there anyway (`locale_settings.cfg`, `hall_of_fame.cfg`, `logs/` timestamps fresh in
this run) plus the real save's md5 being unchanged — an empty throwaway folder is not
evidence of a leak.

**Windowed is only for probes that photograph something.** `main.gd` opens the startup
language gate on `not locale_confirmed and DisplayServer.get_name() != "headless"`, so the
same probe reads two different starting states depending on the launch mode: windowed it
begins with a menu layer already up, and the first ESC *closes* it instead of opening the
menu. On 2026-10-17 that made the tracked `tools/probes/idioma.gd` crash on
`menu_box.get_child_count()` in a windowed battery — a launch-mode artifact, not a game
regression; the probe now closes the gate before measuring, and both modes report the same
numbers. Rule: run the battery `--headless`, and launch windowed only the probes that call
`get_root().get_texture()` (`cara`, `trajeto`, `galeria`, `elenco`) — those need the gate
dismissed too, or the screenshot shows the language chooser instead of the scene.

**A crashed probe does not exit.** When a probe's `_initialize()` dies on a script error,
`quit()` never runs and the process spins to `--quit-after 90000` — about 25 minutes of a
frozen window while a sequential battery stalls on probe #1. If a battery log shows only
one header after several minutes, check `Get-CimInstance Win32_Process -Filter
"Name='Godot.exe'"` for the command line, confirm it is the probe (not the editor) and
`taskkill` that PID; do not assume the battery is merely slow.

**Sealing gold sources means three, not one.** A probe that asserts "the till did not move"
has to lock every faucet that pays into `gold`, not just achievements: badges, level-up
(`gold += 20 + player_level*5`) and **the regular's arc ficha** — `_check_regular_acts`
pays `ARC_REWARDS[i-1].gold + player_level*4` on a regular's *first served visit*, which at
level 60 is +260 ouro and looked exactly like the credit feature leaking money into the till.
Seal `unlocked_achievements`, `player_level` and `regular_arc_seen`/`regular_story_completed`
for every measured name.
