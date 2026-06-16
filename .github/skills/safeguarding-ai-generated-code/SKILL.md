---
name: safeguarding-ai-generated-code
description: Use when AI-generated or AI-modified changes need a Code Health gate before commit, handoff, or pull request.
---

# Safeguarding AI-Generated Code

## Overview

Use Code Health safeguards before declaring AI-touched code ready. The goal is to catch maintainability regressions early and prevent agents from normalizing technical debt.

## When to use

- The agent changed code and is about to suggest a commit.
- The user asks whether a branch or staged changes are safe to merge.
- The workflow needs a quality gate for AI-generated code.

Do not use this skill for broad refactoring discovery or project-level prioritization.

## Quick reference

- `code_health_review`: Review each AI-modified file immediately after the change.
- `pre_commit_code_health_safeguard`: Check staged or modified files before commit.
- `analyze_change_set`: Check a branch or PR-style change set against a base ref.

## Implementation

1. After each AI modification to a file, run `code_health_review` on that file.
2. Treat any CodeScene score degradation, any new code smell flagged as high-severity, or any function exceeding the configured complexity ceiling as a regression requiring remediation before proceeding. If the review reports maintainability problems or regression risk, refactor the file in small steps and review it again. If `code_health_review` returns an error or cannot analyse the file, such as an unsupported language or tool failure, notify the user, skip that file's automated gate, and flag it for manual review before commit.
3. If local CodeScene tooling is available, use this decision flow:
	- For commit-oriented recommendations, run `pre_commit_code_health_safeguard`. If it reports a regression, enter the regression loop below.
	- For PR-oriented recommendations, run `analyze_change_set`. If it reports a regression, enter the regression loop below.
4. If local CodeScene tooling is unavailable, do not warn the user or alter the recommendation flow; proceed as if the CodeScene step does not exist. If the user asks whether CodeScene was run, state that local tooling was unavailable and the check was skipped.
5. Regression loop: run `code_health_review` on each flagged file, refactor in small steps, and re-run the triggering gate. Repeat until the issue is removed or the user responds with a clear acknowledgement such as "I accept this risk" or "proceed despite the regression" after you have named the specific file and regression type. If the same regression persists after three consecutive refactor-and-review cycles without improvement, stop iterating, summarize the unresolved issue to the user, and ask whether to accept the risk or escalate.

## Common mistakes

- Waiting until commit time to run the first Code Health check.
- Treating safeguard output as optional guidance instead of a release gate.
- Declaring work done after a failing safeguard.
- Jumping straight to broad rewrites instead of inspecting the flagged files first.
- Treating an accepted risk as invisible; call it out explicitly.
