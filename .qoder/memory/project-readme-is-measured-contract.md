---
name: project-readme-is-measured-contract
description: Succubus Shop's README quotes live probe measurements — any change to the sale/tick path invalidates other features' published numbers and forces a regression battery plus number reconciliation in the same commit
metadata:
  type: project
---

Every feature bullet in `README.md` (and every probe header in `tools/probes/*.gd`) quotes
*measured* numbers from a headless probe run — the README is treated as a measurement
contract ("README sem desvio"), not as marketing prose.

**Why:** On 2026-10-16, fixing an honest-money bug in the sale path (`main.gd`: the
favourite override used to sell an unaffordable item at full price) moved the #56 invasion
claim from "4 portas seguradas e 4 arrombadas, chance em 26%" to **5 / 8, 25%**, while the
#60 filter A/B totals (caixa 2277, afeição 49, 12/12 seduções, placar 2741) and every
#66/#74 number stayed byte-identical. The invasion curve is computed from *simulated cash*,
so an honest cash-flow fix legitimately re-draws another feature's published curve. Nobody
declared that coupling; it only shows up when the probes are re-run.

**How to apply:** After touching `_on_customer_tick`'s sale/credit/affordability path (or
anything that changes gold, reputation, heat or bonds per visit), re-run the tick-simulating
battery before pushing: `dificuldade`, `despensa`, `porta`, `filtro`, `cara`, `rival`,
`tempo`, `idioma`. Then reconcile, in the *same* commit: any README figure that moved, the
probe header that quotes it, and the achievement-definition count that appears in several
headers. A number that moved because the old one was measured over invented money is a
correction — say so in the README prose instead of silently republishing the new count. See
also [[headless-tests-overwrite-real-save]] and [[feedback-github-sync-workflow]].
