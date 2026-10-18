---
name: project-opt-in-ladder-inertia
description: Succubus Shop progression features ship as purchasable ladders whose rank 0 is byte-inert — no extra randi() consumed, no field mutated — so all previously measured numbers stay identical; the probe must A/B rank 0 vs rank N to prove it
metadata:
  type: project
---

Every new progression feature in Succubus Shop is built as an **opt-in ladder bought in the
reception/forge panel, where degrau 0 is total inertia**. Concretely, with the feature at
rank 0 the code must return before touching anything: no additional `randi()` drawn, no
profile stamped, no counter mutated, no gold or reputation moved — so every number the
README already quotes stays byte-identical. The rank-0 branch is what makes the feature
additive rather than a re-tune of the economy.

**Why:** the game's economy is a measurement contract ([[project-readme-is-measured-contract]])
— dozens of published figures come from tick simulations that consume the RNG stream. A
feature that draws one extra `randi()` per visit silently re-rolls every downstream curve and
invalidates other AIs' published numbers. The pattern was established by the fiado ladder
(#75) and reused for the bancada (#76) and the salão das capas finas / VIP ladder (#78,
`vip_rank == 0` → `_maybe_vip()` returns the profile untouched).

**How to apply:** when adding a feature, add the rank-0 early-return *first*, then write the
probe to A/B rank 0 against rank N on the same seed: assert the rank-0 side produces zero
feature activity *and* that an untouched-baseline probe battery (dificuldade, despensa, fiado,
bancada) still prints its old numbers. Also blind the measurement: mark all achievements
unlocked and park `player_level` away from the next step, because badge payouts and level-up
gold otherwise land inside the number being measured. Remaining backlog items #79 (reputação
negativa) and #80 (combos diários) are expected to follow the same shape. Beware the
empty-shelf corridor trap in [[project-probe-measurement-validity]].
