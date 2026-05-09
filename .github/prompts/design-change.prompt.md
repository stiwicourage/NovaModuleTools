# Design a NovaModuleTools change

Use this prompt with `architect.agent.md` when a change still needs analysis, scoping, and issue drafting before anyone
starts editing files.

This is a discussion-first prompt. The default behavior is to hold a short design conversation with the user before
producing a final scoped solution, implementation handoff, or GitHub issue draft.

Scope is not final until the user confirms it. That includes anything you think should be treated as out of scope,
deferred, split into follow-up work, or excluded from the first implementation pass.

## Required inputs

- The requested change, problem statement, or rough idea
- Relevant issue, discussion, or bug context if it already exists
- Known constraints, deadlines, or rollout concerns if they matter

## Required process

1. Clarify the real problem first. Ask focused follow-up questions when scope, public-surface impact, ownership, or
   rollout direction is unclear.
2. Read `README.md`, `CONTRIBUTING.md`, `.github/instructions/*.md`, and the most relevant `.github/skills/*.md` files.
3. Inspect the affected public command, private helper domain, tests, docs, workflows, or release files without editing
   them.
4. Decide whether the request affects public cmdlets, `% nova` CLI behavior, `project.json`, CI/workflows, command
   help, website docs, `CHANGELOG.md`, or `RELEASE_NOTE.md`.
5. Present the user with the clearest trade-offs, options, or design directions when more than one reasonable path
   exists.
6. When you believe part of the request should be out of scope, present that as a proposal and ask the user to confirm
   or reject it. Do not silently narrow the task.
7. Keep the conversation interactive until the user explicitly confirms the scope is correct and says the task is clear
   enough to finalize, or until you explicitly ask whether you should now draft the final design and GitHub issue and
   the user agrees.
8. Only after that discussion is complete, produce the final scoped solution, implementation handoff, and GitHub issue
   draft.
9. Do not edit repository files unless the user explicitly switches from design to implementation.

## Discussion-phase output

Use the first response and follow-up design turns to drive a conversation, not to dump a finished solution. Prefer:

- a short restatement of the problem
- the most important design questions
- 2-3 concrete solution directions when choices exist
- clear trade-offs
- a recommendation when one option is strongest
- proposed scope and out-of-scope boundaries clearly marked as proposals until the user confirms them

Do not produce the full final design package in the first response unless the user explicitly asks for it.
Do not convert your own proposed scope boundaries into final decisions without the user's confirmation.

## Finalization output

Once the user confirms the scope and says the discussion is done, or explicitly asks for the final design, return:

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

## Repository-specific reminders

- Preserve the distinction between public PowerShell cmdlets and `% nova` CLI behavior.
- Keep contributor docs, command help, website docs, changelog entries, and release notes separated by audience.
- If the final design summary or GitHub issue draft is returned as Markdown or copy-ready UI output, format it according
  to `markdown-authoring.skill.md`.
- Draft issue text in English unless the user explicitly asks for another language.
- If the task still has unresolved choices, end the turn with the next best question or the next design decision the
  user should make.
- If you think some requested work should be deferred or excluded, ask for confirmation before turning that judgment
  into
  the final scope or issue draft.
