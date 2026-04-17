const releaseNotesSourceUrl = 'https://raw.githubusercontent.com/stiwicourage/NovaModuleTools/refs/heads/develop/CHANGELOG.md';

function stripMarkdownLinks(text) {
    return text
        .replace(/\[([^\]]+)\]\([^\)]+\)/g, '$1')
        .replace(/\[([^\]]+)\]\[[^\]]*\]/g, '$1');
}

function appendInlineMarkdown(container, text) {
    const normalizedText = stripMarkdownLinks(text);
    const tokens = normalizedText.split(/(`[^`]+`|\*\*[^*]+\*\*)/g).filter(Boolean);

    for (const token of tokens) {
        if (token.startsWith('`') && token.endsWith('`')) {
            const code = document.createElement('code');
            code.textContent = token.slice(1, -1);
            container.appendChild(code);
            continue;
        }

        if (token.startsWith('**') && token.endsWith('**')) {
            const strong = document.createElement('strong');
            strong.textContent = token.slice(2, -2);
            container.appendChild(strong);
            continue;
        }

        container.appendChild(document.createTextNode(token));
    }
}

function createHeading(level, text) {
    const headingLevel = Math.min(Math.max(level + 1, 2), 4);
    const heading = document.createElement(`h${headingLevel}`);
    appendInlineMarkdown(heading, text);
    return heading;
}

function createParagraph(lines) {
    const paragraph = document.createElement('p');
    appendInlineMarkdown(paragraph, lines.join(' ').trim());
    return paragraph;
}

function createList(items) {
    const list = document.createElement('ul');

    for (const itemText of items) {
        const item = document.createElement('li');
        appendInlineMarkdown(item, itemText);
        list.appendChild(item);
    }

    return list;
}

function createCodeBlock(lines) {
    const pre = document.createElement('pre');
    const code = document.createElement('code');
    code.textContent = lines.join('\n').replace(/\s+$/, '');
    pre.appendChild(code);
    return pre;
}

function createMarkdownState() {
    return {
        fragment: document.createDocumentFragment(),
        paragraphLines: [],
        listItems: [],
        codeLines: [],
        inCodeBlock: false
    };
}

function flushParagraph(state) {
    if (state.paragraphLines.length === 0) {
        return;
    }

    state.fragment.appendChild(createParagraph(state.paragraphLines));
    state.paragraphLines = [];
}

function flushList(state) {
    if (state.listItems.length === 0) {
        return;
    }

    state.fragment.appendChild(createList(state.listItems));
    state.listItems = [];
}

function flushCodeBlock(state) {
    if (state.codeLines.length === 0) {
        return;
    }

    state.fragment.appendChild(createCodeBlock(state.codeLines));
    state.codeLines = [];
}

function flushOpenBlocks(state) {
    flushParagraph(state);
    flushList(state);
}

function normalizeMarkdownLine(originalLine) {
    const line = originalLine.replace(/\t/g, '    ');
    return {
        line,
        trimmedLine: line.trim()
    };
}

function isReferenceLine(trimmedLine) {
    return /^\[[^\]]+\]:\s*https?:\/\//.test(trimmedLine);
}

function isFenceLine(trimmedLine) {
    return trimmedLine.startsWith('```');
}

function isBlankLine(trimmedLine) {
    return trimmedLine === '';
}

function getHeadingMatch(trimmedLine) {
    return trimmedLine.match(/^(#{1,3})\s+(.*)$/);
}

function getListMatch(trimmedLine) {
    return trimmedLine.match(/^-\s+(.*)$/);
}

function isListContinuation(state, line) {
    return state.listItems.length > 0 && /^\s{2,}\S/.test(line);
}

function toggleCodeBlock(state) {
    flushOpenBlocks(state);

    if (state.inCodeBlock) {
        flushCodeBlock(state);
    }

    state.inCodeBlock = !state.inCodeBlock;
}

function appendCodeLine(state, line) {
    state.codeLines.push(line);
}

function appendHeading(state, headingMatch) {
    flushOpenBlocks(state);
    state.fragment.appendChild(createHeading(headingMatch[1].length, headingMatch[2]));
}

function appendListItem(state, listMatch) {
    flushParagraph(state);
    state.listItems.push(listMatch[1]);
}

function appendListContinuation(state, trimmedLine) {
    const lastIndex = state.listItems.length - 1;
    state.listItems[lastIndex] = `${state.listItems[lastIndex]} ${trimmedLine}`;
}

function appendParagraphLine(state, trimmedLine) {
    state.paragraphLines.push(trimmedLine);
}

function processMarkdownLine(state, originalLine) {
    const { line, trimmedLine } = normalizeMarkdownLine(originalLine);

    if (isReferenceLine(trimmedLine)) {
        return;
    }

    if (isFenceLine(trimmedLine)) {
        toggleCodeBlock(state);
        return;
    }

    if (state.inCodeBlock) {
        appendCodeLine(state, line);
        return;
    }

    if (isBlankLine(trimmedLine)) {
        flushOpenBlocks(state);
        return;
    }

    const headingMatch = getHeadingMatch(trimmedLine);
    if (headingMatch) {
        appendHeading(state, headingMatch);
        return;
    }

    const listMatch = getListMatch(trimmedLine);
    if (listMatch) {
        appendListItem(state, listMatch);
        return;
    }

    if (isListContinuation(state, line)) {
        appendListContinuation(state, trimmedLine);
        return;
    }

    appendParagraphLine(state, trimmedLine);
}

function renderMarkdown(container, markdown) {
    const state = createMarkdownState();
    const lines = markdown.replace(/\r\n/g, '\n').split('\n');

    for (const line of lines) {
        processMarkdownLine(state, line);
    }

    flushParagraph(state);
    flushList(state);
    flushCodeBlock(state);
    container.replaceChildren(state.fragment);
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


