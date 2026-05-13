# Copy-safe Markdown wrapper

## Purpose

Use this prompt when the output must be copied directly as Markdown without breaking inner code blocks.

## Required wrapper

Wrap the entire response in this exact outer fence:

~~~
<markdown content>
~~~

The first line must be exactly `~~~`. The last line must be exactly `~~~`. Do not add any text before or after that wrapper.

## Inner Markdown rules

Inside the wrapped block:

- write normal Markdown
- use triple backticks for code examples
- include a language tag when useful
- keep headings, bullets, and fences balanced

## Why this wrapper is required

Using `~~~` for the outer wrapper keeps copy-paste output stable when the Markdown itself contains triple-backtick code blocks.

## Do not

- do not use triple backticks as the outer wrapper
- do not leave any code fence unclosed
- do not add explanation outside the wrapped block
- do not return malformed Markdown

## Example

Expected output shape:

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
