---
name: project-succubus-shop-repo
description: Succubus Shop (Godot 4.7) — GitHub repo GMGuimaraes/succubus-shop, cloned at D:\Downloads\succubus-shop, outside this workspace
metadata:
  type: project
---

The user's Godot project "Succubus Shop" is at `https://github.com/GMGuimaraes/succubus-shop`, cloned locally at `D:\Downloads\succubus-shop`. The clone lives outside this session's workspace, so repo files are never auto-indexed here — always work against the D: path.

Multiple agents/people push to this repo: branches carry `claude/*` and `improve/*` prefixes and the clone was previously using the identity `Manus <dev-agent@manus.ai>`. Since 2026-10-13 the clone's **local** git identity is set to the user (`GMGuimaraes`), so commits are authored by them rather than by another agent's bot account.

Environment facts that are not derivable from the code:
- `gh` CLI is **not** installed; push/pull go through plain `git` over HTTPS with a cached credential helper (works non-interactively).
- Godot 4.7.2 CLI is at `C:\Users\gmore\godot\godot`; `--headless --path . --check-only --script res://X.gd` and `--import` both work for validation.
- Running `--headless --import` rewrites tracked `*.import` files with LF, producing ~17 files of pure CRLF churn. **Always** verify with `git diff --ignore-cr-at-eol` and discard that churn before committing (AGENTS.md forbids committing auto-generated changes).
- A newly added PNG/SVG is invisible to `ResourceLoader.exists()` until `--headless --path . --import` has run, so frame/asset detection in probes returns nothing right after dropping art in.

**Why:** The user treats GitHub as the single source of truth so everyone gets the newest version.

**How to apply:** Target `D:\Downloads\succubus-shop`, expect the checkout to be behind `origin/main` with stray local WIP, and follow [[feedback-github-sync-workflow]] plus [[feedback-main-branch-only]].
