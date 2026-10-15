---
name: feedback-main-branch-only
description: Keep all Succubus Shop work directly on main — no feature branches — as long as main stays stable
metadata:
  type: feedback
---

Work directly on `main` in the Succubus Shop repo; do not create feature branches. The user's condition is that `main` must remain stable.

**Why:** The user wants one visible line of work on GitHub so collaborators never have to hunt across `claude/*` and `improve/*` branches.

**How to apply:** Commit and push to `origin/main` after each validated change. Before pushing, prove stability (headless script checks + a short `--quit-after` smoke run) instead of assuming it; if a change cannot be made stable quickly, say so rather than pushing it. Related: [[project-succubus-shop-repo]], [[feedback-github-sync-workflow]].
