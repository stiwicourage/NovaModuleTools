# Markdown Wrapper Enforcer (Strict)

## Purpose

Force ALL output to be wrapped in a Markdown code block using this exact format:

~~~markdown
<content>
~~~

## Rules (strict)

1. The response MUST start with exactly:

~~~markdown

2. The response MUST end with exactly:
~~~

3. There MUST be no text before or after the wrapper.

4. The entire response MUST be inside the wrapper.

5. If the format cannot be followed, DO NOT answer.

Inner content rules

- Inside the outer ~~~markdown block:
    - Use triple backticks (```) for code examples.
    - Always include language hints when relevant.

⸻

Example (correct nesting)

## Example Section

Run the build:

```zsh
% nova build
```

Or in PowerShell:

```powershell
PS> Invoke-NovaBuild
```

Self-check

Before returning:

-Starts with ~~~markdown?
-Ends with ~~~?
-Code blocks use triple backticks?

If any check fails → regenerate.

Expected behavior

- Safe nested Markdown (no fence collisions)
- Copy/paste ready
- Consistent formatting across all generated content