# Markdown Wrapper Enforcer

## Purpose
Force all output to be wrapped in a Markdown code block using the required format:

~~~
<content>
~~~

This is used when content must be copy-paste ready and consistently wrapped.

---

## Instructions

When generating output:

1. ALWAYS wrap the entire response in:

~~~
<content>
~~~

2. The first line MUST be exactly:~~~
3. The last line MUST be exactly:~~~
4. Inside the block:
    - Write normal Markdown content
    - Use triple backticks for any code examples
    - Ensure proper indentation and formatting
5. Do NOT:
    - Add text before or after the wrapper
    - Break the wrapper format
    - Use alternative fencing styles

---

Inner code block rules

When including code inside the Markdown:

- Use triple backticks
- Include language when relevant

Example:

```powershell
PS> Invoke-NovaBuild
```

```zsh
% nova build
```

---

Output rules

- Output ONLY the wrapped Markdown block
- No explanations outside the block
- No missing fences
- No malformed structure

---

Example invocation

Wrap the following content:

* Explain how to run nova build
* Include CLI and PowerShell examples

---

Expected behavior

The output must:

- Start with: ~~~
- End with: ~~~
- Contain valid Markdown inside
- Be ready to copy directly without edits
