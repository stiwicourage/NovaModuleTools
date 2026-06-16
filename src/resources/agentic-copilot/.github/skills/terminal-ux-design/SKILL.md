---
name: terminal-ux-design
description: Guidance for designing terminal-first PowerShell cmdlets and CLI workflows with Atlassian's CLI principles and Jakob Nielsen's usability heuristics.
---

# Skill: terminal UX design

## When to use

Use this skill when:

- adding or changing a public PowerShell cmdlet
- adding or changing a CLI command/route or its help/output flow
- shaping prompts, progress, warnings, success messages, or error messages
- reviewing terminal-facing behavior in scaffolds, contributor docs, or command help

This skill applies even when the surface is not named "CLI". In {{ProjectName}}, PowerShell cmdlets are also terminal UX.

## Two surfaces, two conventions

The same underlying PowerShell code can present itself through two distinct user-facing surfaces, and each is held to its own conventions:

- **PowerShell cmdlet surface** — anything invoked as `Verb-Noun -Parameter` in a PowerShell session. Follow PowerShell conventions: approved verbs, `-Parameter` naming, `Write-*` streams, `Get-Help`, `-WhatIf` / `-Confirm`, pipeline-friendly output.
- **CLI alias surface** — anything invoked as a unix-style command, including PowerShell aliases or wrapper functions that emulate a CLI (for example `nova <subcommand> --flag`). Follow CLI conventions: `--flag` / `-f`, subcommands, `--help`, predictable exit codes, `Ctrl+C` cancellation, text-stream output.

Use this evaluation protocol before applying the per-principle guidance below:

1. Identify which surface the change touches: PowerShell cmdlet, CLI alias, or both.
2. For each identified surface, work through principles 1-10 using only the guidance for that surface.
3. Record any conflicts with Common Pitfalls and keep cmdlet and CLI evaluations as separate checklists; never merge their outputs.

If the surface cannot be determined from the available context, ask the requester to clarify before applying per-surface guidance. Do not default to either surface silently.

A single command may be reachable through both surfaces; in that case, evaluate each surface against its own conventions instead of blending them.

## Relevant surfaces

This skill is intentionally surface-based rather than path-based, so it applies the same way in this repository and in any project scaffolded by `nova init`, regardless of folder layout. Apply it to any change that touches:

- a public PowerShell cmdlet or its parameters, help, output, or error contract
- a CLI command/route, its help text, flags, exit codes, or output
- a helper that shapes terminal-visible help, prompts, progress, warnings, or errors
- command help authored for PlatyPS or equivalent help generators
- contributor-facing agent, instruction, or skill files that describe terminal-facing behavior

## Atlassian's 10 design principles for delightful CLIs

1. **Align with established conventions**  
   Use established PowerShell and terminal conventions so users do not have to relearn basic command behavior.  
   PowerShell cmdlets: prefer approved verbs, common parameter semantics, and standard streams.  
   CLI: prefer familiar `--flag` / `-f` patterns, standard help forms, and predictable exit codes.
2. **Build help into the CLI**  
   Help must be discoverable from the command itself, not only from external docs.  
   PowerShell cmdlets: keep comment-based help complete and `Get-Help -Full` useful.  
   CLI: keep `--help` and `<command> --help` accurate and task-focused.
3. **Show progress visually**  
   Long-running work should expose state, phases, and forward motion.  
   PowerShell cmdlets: use `Write-Progress` when an operation runs longer than approximately 3 seconds or has two or more discrete, nameable phases.  
   CLI: show clear step transitions and status lines instead of silent waiting.
4. **Create a reaction for every action**  
   Every meaningful user action should receive clear feedback.  
   PowerShell cmdlets: success, cancellation, and failure paths should be explicit.  
   CLI: commands should not silently succeed, silently cancel, or fail without context.
5. **Craft human-readable error messages**  
   Errors should explain what happened and what to do next.  
   PowerShell cmdlets: surface actionable `Stop-{{ShortName}}Operation` messages and preserve a stable `ErrorId`.  
   CLI: convert internal failures into user-readable guidance instead of raw backend output.
6. **Support your skim-readers**  
   Terminal output should be easy to scan under time pressure.  
   PowerShell cmdlets: prefer short paragraphs, focused bullets, and restrained output.  
   CLI: keep normal-path output minimal and make the important line easy to spot.
7. **Suggest the next best step**  
   After a successful action, guide the user to the most likely follow-up.  
   PowerShell cmdlets: mention the next cmdlet or validation step when it helps.  
   CLI: suggest the next subcommand instead of forcing the user back to docs.
8. **Consider your options**  
   Make common cases easy with prompts, defaults, and clear required inputs.  
   PowerShell cmdlets: use sensible defaults, parameter validation, and prompts only when the cmdlet is explicitly designed for interactive use and exposes a `-Interactive` switch or equivalent; never prompt when input can arrive from the pipeline or when no TTY is detected.  
   CLI: accept explicit flags for automation, but guide the user when required context is missing.
9. **Provide an easy way out**  
   Users need a clear cancellation and escape path.  
   PowerShell cmdlets: preserve native `-WhatIf`, `-Confirm`, and cancellation semantics.  
   CLI: make `Ctrl+C`, cancel choices, and non-destructive previews obvious.
10. **Flags over args**  
    Favor named inputs over memory-heavy positional usage.  
    PowerShell cmdlets: prefer explicit parameter names and sensible aliases over positional-only designs.  
    CLI: prefer `--environment production` over unlabeled ordered arguments.

## Jakob Nielsen's 10 usability heuristics for user interface design

1. **Visibility of system status**  
   Keep users informed about current state, current step, and recent outcome within a reasonable time.
2. **Match between the system and the real world**  
   Use the user's language, not internal implementation jargon, and order information the way users expect.
3. **User control and freedom**  
   Support cancel, undo, preview, and escape paths so users do not feel trapped in a workflow.
4. **Consistency and standards**  
   Use one meaning per word, one shape per interaction, and familiar platform conventions across cmdlets, CLI routes, and docs.
5. **Error prevention**  
   Prevent common mistakes with defaults, validation, confirmations, and constraints before the user commits.
6. **Recognition rather than recall**  
   Show the needed options, values, examples, and names instead of forcing the user to remember them from earlier output.
7. **Flexibility and efficiency of use**  
   Support both newcomers and experts with clear defaults plus shortcuts, aliases, and low-friction repeated flows.
8. **Aesthetic and minimalist design**  
   Every line in the terminal competes for attention. Keep normal-path output focused on what matters now.
9. **Help users recognize, diagnose, and recover from errors**  
   State the problem plainly, show where it happened, and suggest recovery steps that a user can act on immediately.
10. **Help and documentation**  
    Make help searchable, contextual, concise, and task-oriented. Users should not have to leave the workflow to understand the next step.

## Combined mapping table

| Concern                 | Concrete PowerShell / CLI mechanism                                                                                                                     | Atlassian principle(s) | Nielsen heuristic(s) |
|-------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------|----------------------|
| Surface routing         | Decide whether the command exposes a PowerShell cmdlet surface, a unix-style CLI alias surface, or both, and apply the matching conventions per surface | 1, 10                  | 2, 4                 |
| Status visibility       | `Write-Progress`, stage-by-stage status lines, clear completion/cancel summaries                                                                        | 3, 4, 7                | 1                    |
| Familiar language       | Approved PowerShell verbs, user-facing terminology, surface-specific wording in docs and help                                                           | 1                      | 2, 4                 |
| Safe exits              | `-WhatIf`, `-Confirm`, `SupportsShouldProcess`, explicit cancel choices, `Ctrl+C` support                                                               | 9                      | 3, 5                 |
| Error prevention        | Parameter validation, pre-flight checks, sensible defaults, explicit `-OverrideWarning` / `--override-warning` gates                                    | 8                      | 5                    |
| Recognition over recall | Comment-based help, CLI `--help`, examples, prompts that show available choices, discoverable defaults                                                  | 2, 8, 10               | 6, 10                |
| Expert efficiency       | Parameter aliases, short CLI flags, repeatable subcommand flows, next-step hints for common sequences                                                   | 7, 10                  | 7                    |
| Minimal output          | Short paragraphs, focused bullets, no decorative banners in normal mode, use `-Verbose` for detail                                                      | 6                      | 8                    |
| Recoverable errors      | `Stop-{{ShortName}}Operation` with stable `ErrorId`, plain language, and actionable recovery guidance                                                            | 5                      | 9                    |
| Help quality            | Accurate `Get-Help`, accurate CLI `<command> --help`, related links, task-oriented examples                                                             | 2                      | 10                   |
| Consistent surfaces     | Do not mix cmdlet `-Parameter` syntax into CLI guidance or CLI `--flag` syntax into cmdlet help                                                         | 1, 10                  | 2, 4                 |

## Expected practices

- Keep PowerShell cmdlet UX and CLI UX distinct, but hold both to the same terminal UX bar.
- Tell users what happened, especially after mutating, long-running, or risky operations.
- Prefer visible choices, examples, and defaults over forcing users to remember values from prior steps.
- Prevent high-cost mistakes before execution; recover clearly when prevention is not enough.
- Keep normal-path output concise, with optional detail on demand through the appropriate verbose/help surface.
- When a next step is common and useful, suggest it explicitly.
- When the host is non-interactive (no TTY, CI environment variable set, or `-NonInteractive` / `--no-interactive` flag present), suppress all prompts, suppress `Write-Progress` output, and ensure the command can complete using only supplied parameters or fail with a non-zero exit code and a machine-readable error message.

## Common pitfalls

- leaking internal jargon, object names, or backend wording into user-facing messages
- returning success with no visible reaction
- printing raw exception text without recovery guidance
- forcing users to remember flag names, route names, IDs, or paths from earlier output
- mixing cmdlet syntax and CLI syntax in the same always-visible guidance
- using large banner-style output where one clear status line would do
- adding confirmations or prompts in a way that breaks automation

## Definition of done

- The user can discover how to invoke the command from the terminal surface they are using.
- Long-running, risky, and error paths expose enough state to keep the user oriented.
- The command uses user language, not internal implementation language.
- The normal path is concise and scannable.
- The user has a clear recovery path after errors and a clear exit path during risky or interactive flows.
- For commands exposed through both surfaces, the review or generated output contains two clearly labeled sections: one for the PowerShell cmdlet surface and one for the CLI alias surface, each evaluated independently against its own conventions.
