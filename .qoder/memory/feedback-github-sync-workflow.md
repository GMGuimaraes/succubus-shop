---
name: feedback-github-sync-workflow
description: Always `git fetch` + compare with origin before editing, and `git push` after changes so everyone gets the latest version
metadata:
  type: feedback
---

Before touching any file: `git fetch origin` and compare `HEAD` with `origin/main`; if the remote has new commits, inspect and sync first while preserving existing local changes. After making changes: commit only that task's changes and `git push origin main`. Report both the remote-check result and the push result. Never sweep pre-existing local edits or auto-generated files (`.import`, `.uid`, `.godot/`) into a commit without explicit authorization.

**Why:** The user wants GitHub to hold the newest version so all collaborators have access; the rules are also written in the repo's own `AGENTS.md`.

**How to apply:** Applies to every work session in this project, on the first command of a session and after inactivity. Ask before pushing if the sync would require a rebase/merge with real conflict risk. Related: [[project-succubus-shop-repo]].
