---
name: headless-tests-overwrite-real-save
description: Headless Godot runs in Succubus Shop write to the user's real %APPDATA% save — isolate or avoid code paths that call _save_game
metadata:
  type: feedback
---

Before running any headless Godot script in this project, check whether the code path calls `_save_game()` (or `ConfigFile.save`). Most gameplay functions end with `_save_game()`, so exercising one in a probe writes to the user's real progress at `%APPDATA%\Godot\app_userdata\Succubus Shop\succubus_shop_save.cfg` — and `audio.gd` similarly persists to `audio_settings.cfg`. Prefer: run pure logic checks (`--check-only`), or point the probe at a throwaway save path before calling into game code.

**Why:** On 2026-10-13 a probe that called `_activate_sector_feature` silently overwrote the user's save with test rewards (+6 XP, +1 reputation, +2 affection, -1 fury) and reset their volume to the probe's value. Recovery meant hand-computing the delta and reversing it, and it was only possible because no level-up occurred.

**How to apply:** Applies to every validation step here, including the pre-push stability check in [[feedback-github-sync-workflow]]. If a probe does touch a save, reverse the exact delta through a Godot script rather than editing the `.cfg` by hand — direct edits to files under `%APPDATA%` are blocked and bypass game semantics. Related: [[project-succubus-shop-repo]].

**The routine that works:** run probes windowed with `APPDATA="D:\\Downloads\\tmp-userdata"` so `user://` resolves into `D:\Downloads\tmp-userdata\Godot\app_userdata\Succubus Shop\`, and `rm -f` that folder's `succubus_shop_save.cfg` before each run so a stale probe save is not read as real progress. Screenshots saved to `user://` land there and can be read back with the Read tool. Point the probe's own `OUT` constant at that same throwaway directory.

**Probe litter is not commit material:** probes are written as repo-root `_tmp_*.gd` (+ generated `.gd.uid`). They pile up fast — 22 of them were sitting in the checkout on 2026-10-15 — and must be deleted before any commit, since AGENTS.md forbids sweeping generated files into a push.

**Known baseline noise (not a regression):** every headless smoke prints `WARNING: 2 ObjectDB instances were leaked at exit` + `ERROR: 1 resources still in use at exit`, caused by `res://assets/shop_theme_loop.mp3` (an `AudioStreamMP3` still referenced at shutdown). A clean run is one whose only error output is that pair — do not chase it or "fix" it as part of unrelated work.

**Making an in-game A/B probe deterministic** (learned while measuring the ten talent specializations, when the control run kept producing different sales/gold each time):
- Never `await` a frame between `_on_customer_tick()` calls — the stage actor rotation consumes RNG driven by *real elapsed frames*, so frames rendered mid-loop change the outcome. Run all ticks back-to-back, then `await` ~40 frames once to settle.
- Call `_reset_run()` and clear the state that survives it (`regular_bonds`, `regular_orders_completed`, `regular_story_progress`, `regular_story_completed`, `regular_arc_seen`, `romance_stage`, `card_counts`, `faction_standing`, `season_baseline`) before each side of an A/B — those cross lives and shift prices.
- `game.spec_choice = some_dict` **aliases** it; `_reset_run()` does `spec_choice.clear()` and silently empties the caller's literal. Always `some_dict.duplicate(true)`.
- Flush `_check_achievements()` and run a throwaway warm-up round first, so achievement payouts don't land on only one side of the measurement; `unlocked_achievements` also persists across probe phases, so `.erase(id)` to re-test a staged condition.
- Print the expected-value lines with decimals (`%+.1f`) — rounding to whole gold hid a real +0.4 gain and read as "no effect".
