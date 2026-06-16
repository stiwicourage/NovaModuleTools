---
applyTo: "**"
---

# Terminal UX design

Use the `terminal-ux-design` skill when a change touches any user-facing command, terminal output, prompt, help surface, progress indicator, warning, error message, or scaffold guidance for those surfaces. If a change touches both terminal-facing and non-terminal surfaces, apply the skill only to the terminal-facing portions of that change; leave non-terminal surfaces out of scope.

This applies to:

- PowerShell cmdlets
- `% nova` CLI routes
- internal functions or modules whose return values or side-effects are directly rendered as terminal output by a public command or route
- contributor docs, command help, and scaffold content that teach those workflows

Keep PowerShell cmdlet UX and `% nova` CLI UX distinct, but apply both Atlassian's 10 CLI design principles and Nielsen's 10 usability heuristics equally to PowerShell cmdlet UX and `% nova` CLI UX; when the two frameworks conflict, prefer the Atlassian CLI principle as the more domain-specific guidance.

The skill is authoritative for:

- Atlassian's 10 design principles for delightful CLIs
- Jakob Nielsen's 10 usability heuristics for user interface design

When invoked, review the change against each of Atlassian's 10 CLI design principles and each of Nielsen's 10 usability heuristics. For every principle or heuristic that is violated or at risk, cite it by name, explain the specific violation in the change, and propose a concrete corrective rewrite.
