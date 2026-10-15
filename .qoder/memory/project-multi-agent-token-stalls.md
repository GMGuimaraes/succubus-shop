---
name: project-multi-agent-token-stalls
description: Succubus Shop work repeatedly stalls on the account's daily token limit and other AI agents continue the same repo — verify what's already done before implementing
metadata:
  type: project
---

On 2026-10-15 the user twice sent the same instruction into the Succubus Shop session: finish every request that was left pending because of the **daily token limit**, and "always check whether it wasn't already done by another AI". Concurrent sessions on the same repo were observed running and queueing turns at the same time.

**Why:** Several agents work this repo in parallel (see [[project-succubus-shop-repo]]), so a feature the user asked for may already exist in code or in a local commit — and a token cap cuts sessions off mid-backlog, leaving an unfinished list that resumes later.

**How to apply:** On resume, do not re-implement from the remembered ask. First sync with `origin/main` ([[feedback-github-sync-workflow]]) and inspect the working tree / recent commits to see which backlog items already landed, then report which ones were already done by someone else before starting the remainder. Expect the backlog to be long — the user keeps asking to "continue proposing improvements until the final game", so unfinished items are normal, not a failure.
