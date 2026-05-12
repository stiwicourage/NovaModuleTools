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
- Use `~~~` as the outer wrapper when the whole response must be one copy-ready Markdown block.
- Use triple backticks inside that wrapper for code examples.
- Keep headings, lists, and code fences balanced and readable.
- Prefer concise Markdown that fits the required template or document structure.

## Copy-safe fence rules

- When the entire response must be wrapped, start with a line containing exactly `~~~` and end with a line containing exactly `~~~`.
- Do not place prose before or after that outer wrapper.
- Inside the wrapped block, use normal Markdown.
- For inner code examples, use triple backticks and include a language when helpful.
- Never use triple backticks as the outer wrapper when the content itself may already contain fenced code blocks.

## Common pitfalls

- Breaking copy-paste output by mixing outer and inner triple-backtick fences
- Leaving unclosed code fences
- Adding explanation outside a required wrapped Markdown block
- Producing Markdown that does not match the authoritative template being used

## Verification

- Re-read the output as raw Markdown before finalizing it
- Check that every opening fence has a matching closing fence
- If a template is authoritative, verify the generated Markdown follows it exactly
