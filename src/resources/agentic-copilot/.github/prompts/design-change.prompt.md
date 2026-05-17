# Design a {{ProjectName}} change

> Invoke with `@.github/prompts/design-change.prompt.md`. Delegates to the `architect` agent.

Use this prompt with `architect.agent.md` when a change still needs analysis, scoping, and issue/work item drafting before anyone starts editing files.

This is a discussion-first prompt. The default behavior is to hold a short design conversation with the user before producing a final scoped solution, implementation handoff, or issue/work item draft.

Scope is not final until the user confirms it. That includes anything you think should be treated as out of scope, deferred, split into follow-up work, or excluded from the first implementation pass.

## Required inputs

- The requested change, problem statement, or rough idea
- Relevant issue, discussion, or bug context if it already exists
- Known constraints, deadlines, or rollout concerns if they matter

## Required process

1. Clarify the real problem first. Ask focused follow-up questions when scope, public-surface impact, ownership, or rollout direction is unclear.
2. Read `README.md`, `CONTRIBUTING.md`, `.github/copilot-instructions.md`, the relevant
   `.github/instructions/*.instructions.md` files, and the most relevant skill definitions under
   `.github/skills/*/SKILL.md`.
3. Inspect the affected public command, private helper domain, tests, docs, workflows, or release files without editing them.
4. Decide whether the request affects public cmdlets, `% nova` CLI behavior, `project.json`, CI/workflows, command help, project docs, `CHANGELOG.md`, or `RELEASE_NOTE.md`.
5. Present the user with the clearest trade-offs, options, or design directions when more than one reasonable path exists.
6. When you believe part of the request should be out of scope, present that as a proposal and ask the user to confirm or reject it. Do not silently narrow the task.
7. If unresolved questions still remain but the discussion is far enough along to consider finalization, pause for a short readiness check before asking to finalize:
    - list what is already settled
    - list what is still unresolved
    - offer three explicit choices:
        - finalize with design package and issue/work item draft
        - finalize with design package only
        - keep discussing
8. Keep the conversation interactive until the user explicitly confirms the scope is correct and says the task is clear enough to finalize, or until you explicitly ask whether you should now draft the final output and the user chooses one of those options.
9. Only after that discussion is complete, produce the final scoped solution and implementation handoff, and include the issue/work item draft only when the user chose the full-finalization option.
10. Do not edit repository files unless the user explicitly switches from design to implementation.

## Discussion-phase output

Use the first response and follow-up design turns to drive a conversation, not to dump a finished solution. Prefer:

- a short restatement of the problem
- the most important design questions
- 2-3 concrete solution directions when choices exist
- clear trade-offs
- a recommendation when one option is strongest
- proposed scope and out-of-scope boundaries clearly marked as proposals until the user confirms them
- when unresolved items remain, a readiness summary before any finalization question so the user knows what is still open

Do not produce the full final design package in the first response unless the user explicitly asks for it. Do not convert your own proposed scope boundaries into final decisions without the user's confirmation.

## Finalization output

All finalization output is copy-ready Markdown. Apply the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`) for copy-safe UI output, including any required wrapping, and do not add prose outside the final output.

If the user chooses **design package and issue/work item draft**, return:

- a short usage note that explains:
    - the sections before `issue/work item draft` are design/handoff notes
    - only the `issue/work item draft` section is paste-ready tracker text
- Problem
- Why it matters
- Scope
- Out of scope
- Affected areas and likely files
- Validation and documentation impact
- Proposed implementation approach
- Open questions
- Recommended follow-on agent
- issue/work item draft

If unresolved questions still remain, keep them under `Open questions` in the design package and add a short `Open questions` section inside the issue/work item draft too.

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

- do not include an issue/work item draft
- preserve the settled decisions clearly enough that the user can resume later
- end with the next unresolved design decision or a short resume prompt the user can reuse later
- still apply the `markdown-authoring` skill to the final response

## Repository-specific reminders

- Keep contributor docs, command help, project docs, changelog entries, and release notes separated by audience.
- Final design summaries and issue/work item drafts are always copy-ready Markdown output; apply the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`).
- Draft issue text in English unless the user explicitly asks for another language.
- If the task still has unresolved choices, end the turn with the next best question or the next design decision the user should make.
- If unresolved choices remain and you offer finalization anyway, explain what is settled, what is unresolved, and what each finalization option will produce.
- If you return both design notes and an issue/work item draft, explicitly tell the user how to use each part.
- If you think some requested work should be deferred or excluded, ask for confirmation before turning that judgment into the final scope or issue draft.
