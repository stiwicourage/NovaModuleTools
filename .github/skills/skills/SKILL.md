---
name: skills
description: Index folder for vendored shared skills used by NovaModuleTools scaffolding and local guidance.
---

# Skill: skills

## When to use

Use this folder only as a container for nested shared skills that are maintained separately from the repository-local skill entry points.

## Relevant files

- `.github/skills/skills/*`

## Expected practices

- Do not reference this container skill directly from prompts or agents.
- Keep nested shared skills organized beneath this folder when they are intentionally vendored for local reuse.
- Prefer the repository-local top-level skills under `.github/skills/*/SKILL.md` for normal NovaModuleTools task routing.
