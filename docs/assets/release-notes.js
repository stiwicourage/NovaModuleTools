const releaseNotesSourceUrl = 'https://raw.githubusercontent.com/stiwicourage/NovaModuleTools/refs/heads/develop/CHANGELOG.md';

function getMarkedInstance() {
    return window.marked;
}

function requireMarked() {
    const marked = getMarkedInstance();

    if (!marked) {
        throw new Error('Marked is not available.');
    }

    return marked;
}

function createRenderer(marked) {
    const renderer = new marked.Renderer();

    renderer.link = function ({ tokens }) {
        return this.parser.parseInline(tokens ?? []);
    };

    return renderer;
}

function parseMarkdown(marked, markdown) {
    return marked.parse(markdown, {
        gfm: true,
        breaks: false,
        renderer: createRenderer(marked)
    });
}

function getPromotedHeadingLevel(level) {
    return Math.min(level + 1, 4);
}

function replaceElement(source, replacementTagName) {
    const replacement = document.createElement(replacementTagName);
    replacement.innerHTML = source.innerHTML;
    source.replaceWith(replacement);
}

function normalizeHeadingLevels(container) {
    const headings = [...container.querySelectorAll('h1, h2, h3, h4, h5, h6')];

    for (const heading of headings) {
        const currentLevel = Number.parseInt(heading.tagName.slice(1), 10);
        const promotedLevel = getPromotedHeadingLevel(currentLevel);

        replaceElement(heading, `h${promotedLevel}`);
    }
}

function unwrapLinks(container) {
    const links = [...container.querySelectorAll('a')];

    for (const link of links) {
        const text = document.createTextNode(link.textContent ?? '');
        link.replaceWith(text);
    }
}

function removeEmptyParagraphs(container) {
    const paragraphs = [...container.querySelectorAll('p')];

    for (const paragraph of paragraphs) {
        if (paragraph.textContent.trim() !== '') {
            continue;
        }

        paragraph.remove();
    }
}

function normalizeRenderedMarkup(container) {
    normalizeHeadingLevels(container);
    unwrapLinks(container);
    removeEmptyParagraphs(container);
}

function renderMarkdown(container, markdown) {
    const marked = requireMarked();
    const renderedHtml = parseMarkdown(marked, markdown);
    container.innerHTML = renderedHtml;
    normalizeRenderedMarkup(container);
}

async function initializeReleaseNotesPage() {
    const content = document.getElementById('release-notes-content');
    const status = document.getElementById('release-notes-status');

    if (!content || !status) {
        return;
    }

    try {
        const response = await fetch(releaseNotesSourceUrl, { cache: 'no-store' });

        if (!response.ok) {
            throw new Error(`GitHub returned ${response.status}`);
        }

        const markdown = await response.text();
        renderMarkdown(content, markdown);
        status.textContent = '';
        status.classList.add('release-notes-status--success');
    } catch {
        status.textContent = 'GitHub could not be reached, so the release notes are temporarily unavailable on this page.';
        status.classList.add('release-notes-status--error');
    }
}

initializeReleaseNotesPage();
