# Project memory index

- [Succubus Shop repo](project-succubus-shop-repo.md) — Godot 4.7 at `D:\Downloads\succubus-shop`, remote `GMGuimaraes/succubus-shop`, `.import` CRLF churn; `.qoder/` copies of skill+memory live in-repo and must be mirrored
- [GitHub sync workflow](feedback-github-sync-workflow.md) — fetch/compare before editing, push after every change, never commit stray local WIP or generated files
- [Main branch only](feedback-main-branch-only.md) — work directly on `main`, no feature branches, but prove stability before pushing
- [Headless tests overwrite the real save](headless-tests-overwrite-real-save.md) — isolate probes with `APPDATA=D:\Downloads\tmp-userdata`; no leak tolerance, and headless never starts audio playback
- [ImageGen quota block](imagegen-quota-block.md) — 403 code 112 means the account's image quota is spent; switch to the code-only backlog instead of retrying
- [Probes are assets, not junk](probes-are-assets-not-junk.md) — never delete `_tmp_*.gd`; extend them, promote to `res://tools/`, or fold them into the game
- [Content boundary: no nudity](project-content-boundary-nudity.md) — suggestive tone behind the adult toggle, never explicit; toggle must not change any number
- [README is a measured contract](project-readme-is-measured-contract.md) — sale-path changes move other features' quoted numbers; re-run the tick battery and reconcile README+headers same commit
- [Opt-in ladder inertia](project-opt-in-ladder-inertia.md) — new purchasable ladders must be byte-inert at rank 0; prove it by A/B rank 0 vs rank N
- [Probe measurement validity](project-probe-measurement-validity.md) — four traps that made probes print confident nonsense (empty shelves, rounding floors, skipped --check-only, unmet gate preconditions)
- [Headless text FATAL is engine, not feature](headless-text-fatal-is-engine-not-feature.md) — triage intermittent headless crashes by crash-rate matrix with controls before rewiring working code
