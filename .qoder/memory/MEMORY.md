# Project memory index

- [Succubus Shop repo](project-succubus-shop-repo.md) — Godot 4.7 at `D:\Downloads\succubus-shop`, remote `GMGuimaraes/succubus-shop`, `.import` CRLF churn; `.qoder/` copies of skill+memory live in-repo and must be mirrored
- [GitHub sync workflow](feedback-github-sync-workflow.md) — fetch/compare before editing, push after every change, never commit stray local WIP or generated files
- [Main branch only](feedback-main-branch-only.md) — work directly on `main`, no feature branches, but prove stability before pushing
- [Headless tests overwrite the real save](headless-tests-overwrite-real-save.md) — isolate probes with `APPDATA=D:\Downloads\tmp-userdata`; the MP3 leak at exit is expected baseline
- [ImageGen quota block](imagegen-quota-block.md) — 403 code 112 means the account's image quota is spent; switch to the code-only backlog instead of retrying
- [Probes are assets, not junk](probes-are-assets-not-junk.md) — never delete `_tmp_*.gd`; extend them, promote to `res://tools/`, or fold them into the game
