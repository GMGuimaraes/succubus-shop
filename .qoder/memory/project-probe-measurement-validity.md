---
name: project-probe-measurement-validity
description: Four traps that made Succubus Shop headless probes print confident nonsense — empty-shelf tick corridors, percentage floors, --check-only missing runtime errors, and gates whose precondition was never met
metadata:
  type: project
---

A probe that runs and prints is not a probe that measures. Four traps found in the same
validation window (2026-10-16, `tools/probes/salao.gd` for the VIP salon):

1. **A tick corridor with an empty shelf proves nothing.** An unstocked fresh run goes down
   the "prateleira vazia" branch, which returns *before* `_flood_service_queue()` /
   `_draw_visitor_profile()`. Over 200 ticks only 4 sales happened and both sides of the A/B
   printed `capa servida 0 • recusada 0 • gorjeta 0` — identical, so the "rank 0 is inert"
   line was true by absence of any visit, not by the feature. Stock the shelf the same way on
   every side so the only variable is the feature's rank.
2. **Measure a percentage above its floor.** The gorjeta is `maxi(4, round(tabela * 0.15))`;
   on the 15-gold potion that is 3 → the floor 4 at *every* rank, so the probe would have
   "proved" 15% while only proving the `maxi`. The measurement subject has to be expensive
   enough for the formula to output distinct numbers per step.
3. **`--check-only` does not execute anything.** `%r` is not a valid GDScript format
   specifier: the parse gate stayed green and the smoke died mid-run with 7×
   `String formatting error: unsupported format character`. Only the log grep catches these,
   so a green `--check-only` is never evidence the probe runs.
4. **Verify the precondition before crediting the gate.** The third ladder node was silently
   refused by the fama gate (reputation 25 < 45), so the "fourth click at the ceiling" print
   was actually measuring the reputation refusal, not the ceiling. Set every input the step
   under test requires (and print it) before claiming the boundary was probed.

**Why:** the README and every probe header publish these numbers as a measurement contract
([[project-readme-is-measured-contract]]), so a confidently-worded zero is worse than no
measurement — it becomes the project's recorded truth.

**How to apply:** before writing a probe verdict into a header or the README, ask what the
numbered path actually executed: was the branch reached, was the value above any clamp, did
the gate under test really have its inputs? Re-run after fixing; the error grep is part of
the answer, not a formality. See also [[godot-headless-probe-and-push-gate]] skill and
[[headless-tests-overwrite-real-save]].
