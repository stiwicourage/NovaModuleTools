# Design a NovaModuleTools change

> Invoke with `@.github/prompts/design-change.prompt.md`. Delegates to the `architect` agent.

Use this prompt with `architect.agent.md` when a change still needs analysis, scoping, and issue drafting before anyone starts editing files. Do not treat invoking this prompt by itself as a request for the full final design package in the first response.

This is a discussion-first prompt. The default behavior is to hold a short design conversation with the user before producing a final scoped solution, implementation handoff, or GitHub issue draft. If the user's first message already confirms the scope and leaves no open questions, you may skip the discussion phase and proceed directly to the readiness summary and finalization choices.

Scope is not final until the user confirms it. That includes anything you think should be treated as out of scope, deferred, split into follow-up work, or excluded from the first implementation pass. For this prompt, the user selecting a finalization option after the readiness summary counts as confirming the current scope.

## Required inputs

- The requested change, problem statement, or rough idea
- Relevant issue, discussion, or bug context if it already exists
- Known constraints, deadlines, or rollout concerns if they matter

## Required process

### Before first response

1. Clarify the real problem first. Ask at most 2 focused follow-up questions per turn, prioritizing the question most likely to change the scope or approach.
2. Read only the minimum repository context needed to ask informed questions. Start with the most relevant of `README.md`, `CONTRIBUTING.md`, `.github/copilot-instructions.md`, the relevant `.github/instructions/*.instructions.md` files, and the most relevant skill definitions under `.github/skills/*/SKILL.md`.
   If any of these files are missing or inaccessible, note which ones could not be read, proceed with the information available, and flag the missing context to the user in your first response.
3. Inspect only the most directly affected public command, private helper domain, test, doc, workflow, or release surface without editing files.

### Before finalization

4. Before producing final output, read the remaining relevant repository guidance from `README.md`, `CONTRIBUTING.md`, `.github/copilot-instructions.md`, the relevant `.github/instructions/*.instructions.md` files, and the most relevant `.github/skills/*/SKILL.md` definitions.
5. Inspect the affected public command, private helper domain, tests, docs, workflows, or release files without editing them.
6. Decide whether the request affects public cmdlets, `% nova` CLI behavior, `project.json`, CI/workflows, command help, website docs, `CHANGELOG.md`, or `RELEASE_NOTE.md`. Preserve the distinction between public PowerShell cmdlets and `% nova` CLI behavior, and keep contributor docs, command help, website docs, changelog entries, and release notes separated by audience.
7. Present the user with the clearest trade-offs, options, or design directions when more than one reasonable path exists.
8. When choices exist, present 2-3 concrete solution directions when the approaches differ in public API surface, implementation complexity, or rollout risk.
9. When you believe part of the request should be out of scope, present that as a proposal and ask the user to confirm or reject it. Do not silently narrow the task.
10. After each response, if the user has not yet confirmed scope, end your turn with either the next most important design question or, if you have no remaining questions and at least the core scope and problem statement are settled, even if secondary questions remain open, a readiness summary followed by these three finalization choices:
    - finalize with design package and GitHub issue draft
    - finalize with design package only
    - keep discussing
11. Do not produce final output until the user selects a finalization option from those choices. If the user has declined finalization or continued the discussion for more than three turns after the readiness summary was first offered, restate the readiness summary and say: "We can keep refining, but I want to flag that we have already covered the core design decisions. Would you like to finalize now, or is there a specific blocker preventing finalization?"
12. Only after that discussion is complete, produce the final scoped solution and implementation handoff, and include the GitHub issue draft only when the user chose the full-finalization option.
13. Do not edit repository files unless the user explicitly switches from design to implementation. If the user requests a switch to implementation before scope is finalized, produce the design package only, without a GitHub issue draft, as the handoff record, then defer to the implementation agent. Do not begin editing files until the design package has been produced.

## Discussion-phase output

Use the first response and follow-up design turns to drive a conversation, not to dump a finished solution. Prefer:

- a short restatement of the problem
- the most important design questions
- 2-3 concrete solution directions when the approaches differ in public API surface, implementation complexity, or rollout risk
- clear trade-offs
- a recommendation when one option is strongest
- proposed scope and out-of-scope boundaries clearly marked as proposals until the user confirms them
- when unresolved items remain, a readiness summary before any finalization question so the user knows what is still open

Do not produce the full final design package in the first response unless the user explicitly asks for it or their first message already confirms scope and requests finalization. Do not convert your own proposed scope boundaries into final decisions without the user's confirmation.

## Finalization output

All finalization output is copy-ready Markdown. Apply the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`) for copy-safe UI output, including any required wrapping, and do not add prose outside the final output.

Draft issue text in English unless the user explicitly asks for another language.

If the user chooses **design package and GitHub issue draft**, return:

- a short usage note that explains:
    - the sections before `GitHub issue draft` are design/handoff notes
    - only the `GitHub issue draft` section is paste-ready GitHub text
- Problem
- Why it matters
- Scope
- Out of scope
- Affected areas and likely files
- Validation and documentation impact
- Proposed implementation approach
- Open questions
- Recommended follow-on agent
- GitHub issue draft

If unresolved questions still remain, keep them under `Open questions` in the design package and add a short `Open questions` section inside the GitHub issue draft too.

If the user chooses **design package only**, return:

- Problem
- Why it matters
- Scope
- Out of scope
- Affected areas and likely files
- Validation and documentation impact
- Proposed implementation approach
- Open questions / resume here
- Recommended follow-on agent

In design-package-only mode:

- do not include a GitHub issue draft
- preserve the settled decisions clearly enough that the user can resume later
- end with the next unresolved design decision or a short resume prompt the user can reuse later
- still apply the `markdown-authoring` skill to the final response
