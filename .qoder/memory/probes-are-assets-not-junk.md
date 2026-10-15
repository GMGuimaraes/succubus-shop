---
name: probes-are-assets-not-junk
description: Never delete the _tmp_*.gd probe scripts in Succubus Shop — promote useful ones to res://tools/ or fold their logic into the game instead
metadata:
  type: project
---

The ~21 `_tmp_*.gd` (+ `.uid`) probe scripts sitting untracked at `D:\Downloads\succubus-shop` are the user's, not trash. Asked whether the pre-push gate should purge them (2026-10-15), the user answered: "ao invés de limpar, dá um jeito de conectá-las ao jogo ou melhorar o que já existe mantendo todas as funcionalidades".

**Why:** Each probe already encodes a verified answer about the game's economy, queue, arcs, endings or stage animation. Deleting one throws away tested knowledge; the user wants that knowledge either committed as a dev tool or turned into real in-game behavior.

**How to apply:** Before writing a new probe, `ls _tmp_*.gd` and extend an existing one. When a probe is done, either move it to `res://tools/probes/<name>.gd` (tracked, with the exact CLI invocation in its header, the way `res://tools/split_poses.gd` documents itself) or implement what it measured in `main.gd` and retire it. Only delete probes the current round created — and never as a side effect of someone else's push. This is step 9 of the `godot-headless-probe-and-push-gate` skill. Related: [[headless-tests-overwrite-real-save]], [[feedback-github-sync-workflow]].
