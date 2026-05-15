applyTo: "src/**/*.ps1,scripts/**/*.ps1,run.ps1,reload.ps1"
---

# Agentic code quality matrix

## Purpose

Use this file as the best-effort maintainability guidance for PowerShell source and helper scripts in this repository.

This file tells Agentic Copilot how to shape source code from the start; Test-specific guidance belongs in `.github/instructions/testing-policy.instructions.md` and the `pester-testing` skill.

## How to apply this guidance

- Use these rules when writing or reviewing `src/**/*.ps1`, `scripts/**/*.ps1`, `run.ps1`, and `reload.ps1`.
- Prefer these patterns in new or heavily changed code instead of leaving cleanup for later.
- If a change must violate one of these rules, keep the exception narrow and explain the trade-off clearly in the handoff.
- Favor small refactors that remove the smell at the source over comments, suppressions, or wrappers that only hide it.

## Function-level guidance

- Keep functions short and single-purpose. If a function starts mixing validation, branching, transformation, and output, extract named helpers instead of growing one long scriptblock.
- Replace long `switch` statements or `if`/`elseif` chains with lookup hashtables, dispatch tables, or focused strategy helpers when behavior varies by key, state, provider, or mode.
- Flatten nested control flow early. Extract decision helpers such as `Get-*Action`, `Resolve-*Context`, or `Test-*Condition` instead of building indentation towers.
- Keep interfaces small. When several inputs always travel together, bundle them into a `[pscustomobject]`, ordered hashtable, or small class instead of growing long parameter lists.
- Avoid copy/paste. If two flows share the same steps with only small differences, extract the shared helper and pass the variation explicitly.
- Prefer small helper chains with clear names over one function that tries to do everything.

## File and module guidance

- Keep each file focused on one externally owned behavior.
- Split multi-responsibility private files before they turn into catch-all helpers that mix lookup, mutation, formatting, validation, and transport logic.
- Hide provider-specific or platform-specific details behind adapters or focused helper boundaries so callers depend on a small common surface instead of scattering provider branches everywhere.
- Avoid pass-through helpers that only forward parameters to another function without adding policy, validation, translation, or abstraction.
- Keep private domains balanced. If one `src/private/<domain>/` area keeps absorbing unrelated responsibilities, split by workflow concern before that folder becomes the default dumping ground.
- Prefer existing platform/library capabilities or approved repository helpers over custom utility layers when the custom code adds no durable value.

## Codebase hygiene

- Leave the file cleaner than you found it.
- Remove dead code, commented-out code, and obsolete helpers instead of leaving them behind "just in case."
- Use concise, specific names that reflect one responsibility.
- Replace unexplained literals with named constants, lookup tables, or variables that reveal intent.
- Add comments only when names and structure cannot make the intent obvious on their own.
- Catch specific exceptions only where the layer can add useful context; otherwise let failures surface clearly instead of hiding them behind broad catch blocks or silent fallbacks.

## Review expectations

- Flag long mixed-responsibility functions, deep nesting, copy/paste blocks, long parameter lists, pass-through helpers, provider-specific branching spread across callers, dead/commented-out code, magic values, and broad or hidden exception handling.
- When the code smell is test-specific, route that feedback through `.github/instructions/testing-policy.instructions.md` and the `pester-testing` skill instead of stretching this file to cover test-only patterns.
