---
name: markdown-authoring
description: Guidance for producing valid, copy-safe Markdown files and UI-ready Markdown output in NovaModuleTools.
---

# Skill: markdown authoring

## When to use

Use this skill when producing Markdown files in the repository or Markdown output that must be copied directly from the UI, such as release summaries, PR-template-shaped text, contributor docs, or reusable prompt output.

## Relevant files

- `.github/pull_request_template.md`
- `.github/prompts/*.md`
- `.github/copilot-instructions.md`
- `.github/instructions/*.instructions.md`
- `.github/agents/*.md`
- `.github/skills/*/SKILL.md`
- `README.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`
- `docs/NovaModuleTools/en-US/*.md`

## Expected practices

- Write valid Markdown that is easy to paste without cleanup.
- Use `~~~` as the outer wrapper when the task is producing one copy-ready Markdown block for release summaries, PR-template-shaped text, contributor docs, or reusable prompt output.
- Use triple backticks inside that wrapper for code examples.
- Keep headings, lists, and code fences balanced and readable.
- Prefer concise Markdown that fits the required template or document structure.

## Copy-safe fence rules

- Apply the `~~~` wrapper whenever the task is a release summary, PR-template-shaped text, contributor doc, or reusable prompt output. Do not apply it for conversational answers or inline file edits.
- When the `~~~` wrapper is required, start with a line containing exactly `~~~` and end with a line containing exactly `~~~`.
- **When the `~~~` wrapper is required, any text outside the `~~~` block is a rule violation.** This includes greetings, preambles, "here is the summary" lead-ins, observations appended after the block, and any other prose. In all other cases, normal prose responses are allowed.
- Inside the wrapped block, use normal Markdown.
- If contextual explanation is necessary alongside a copy-ready block, place it inside the `~~~` wrapper as a Markdown blockquote or comment rather than outside the block. Never emit prose outside the `~~~` block when the wrapper is required.
- For inner code examples, use triple backticks and always include a language identifier unless the content is plain text or has no established language identifier.
- Never use triple backticks as the outer wrapper when the content itself may already contain fenced code blocks.
- If the content to be wrapped itself contains a `~~~` fence, escape or represent it as a code span or indented block, and add a comment `<!-- original ~~~ escaped -->` so the author can restore it manually.

## Copy-safe wrapper example

Expected output shape when the entire response must be a single copy-ready Markdown block:

~~~
## Example

Run the build with:

```powershell
PS> Invoke-NovaBuild
```

Or from the CLI:

```zsh
% nova build
```
~~~

## Common pitfalls

- Breaking copy-paste output by mixing outer and inner triple-backtick fences
- Leaving unclosed code fences
- Adding explanation outside a required wrapped Markdown block
- Producing Markdown that does not match the authoritative template being used

## Verification

- Re-read the output as raw Markdown before finalizing it
- Check that every opening fence has a matching closing fence
- If a template is authoritative, verify the generated Markdown follows it exactly
- If the available information is insufficient to populate a required template field, insert a clearly marked placeholder such as `<!-- TODO: value needed -->` rather than omitting the field or inventing content, and note the missing fields inside the `~~~` block as a Markdown comment when the wrapper is required
