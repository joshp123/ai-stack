# Client Implementation Guide

The renderer that makes this skill work. Build this only when adding native client support for the `visualizer` fence.

## Architecture

```text
Model generates code guided by SKILL.md and references
        ↓
Code wrapped in a visualizer code fence
        ↓
Client detects the fence and strips it
        ↓
Sandboxed iframe created
        ↓
Theme CSS and widget code injected
        ↓
ResizeObserver keeps height in sync
        ↓
sendPrompt bridge connects clicks back to chat
```

## Renderer component

```tsx
import { useEffect, useRef, useState } from 'react';

export function VisualWidget({ code, title, onSendPrompt }) {
  const iframeRef = useRef(null);
  const [height, setHeight] = useState(200);
  const isDark = matchMedia('(prefers-color-scheme: dark)').matches;

  useEffect(() => {
    const iframe = iframeRef.current;
    if (!iframe) return;
    const doc = iframe.contentDocument;
    if (!doc) return;

    doc.open();
    doc.write(`<style>${getThemeCSS(isDark)}\n${SVG_CLASSES}</style>${code}`);
    doc.close();

    iframe.contentWindow.sendPrompt = (text) => onSendPrompt?.(text);
    iframe.contentWindow.openLink = (url) => window.open(url, '_blank');

    let timer;
    const ro = new ResizeObserver(([entry]) => {
      clearTimeout(timer);
      timer = setTimeout(() => setHeight(Math.ceil(entry.contentRect.height) + 16), 50);
    });
    if (doc.body) ro.observe(doc.body);
    return () => {
      ro.disconnect();
      clearTimeout(timer);
    };
  }, [code, isDark, onSendPrompt]);

  return (
    <iframe
      ref={iframeRef}
      title={title}
      sandbox="allow-scripts"
      style={{ width: '100%', height, border: 'none', display: 'block', overflow: 'hidden' }}
    />
  );
}
```

## Theme CSS

Return the host app's design tokens and switch on dark mode:

```typescript
function getThemeCSS(isDark: boolean): string {
  return isDark ? `
    :root {
      --color-text-primary: #E5E7EB;
      --color-text-secondary: #9CA3AF;
      --color-text-tertiary: #6B7280;
      --color-text-info: #60A5FA;
      --color-text-success: #34D399;
      --color-text-warning: #FBBF24;
      --color-text-danger: #F87171;
      --color-background-primary: #1A1A1A;
      --color-background-secondary: #262626;
      --color-background-tertiary: #111111;
      --color-border-tertiary: rgba(255,255,255,0.15);
      --color-border-secondary: rgba(255,255,255,0.3);
      --font-sans: system-ui, -apple-system, sans-serif;
      --font-mono: 'SF Mono', Menlo, monospace;
      --border-radius-md: 8px;
      --border-radius-lg: 12px;
    }` : `
    :root {
      --color-text-primary: #1F2937;
      --color-text-secondary: #6B7280;
      --color-text-tertiary: #9CA3AF;
      --color-text-info: #2563EB;
      --color-text-success: #059669;
      --color-text-warning: #D97706;
      --color-text-danger: #DC2626;
      --color-background-primary: #FFFFFF;
      --color-background-secondary: #F9FAFB;
      --color-background-tertiary: #F3F4F6;
      --color-border-tertiary: rgba(0,0,0,0.15);
      --color-border-secondary: rgba(0,0,0,0.3);
      --font-sans: system-ui, -apple-system, sans-serif;
      --font-mono: 'SF Mono', Menlo, monospace;
      --border-radius-md: 8px;
      --border-radius-lg: 12px;
    }`;
}
```

## SVG classes

Inject this alongside the theme CSS:

```typescript
const SVG_CLASSES = `
  .t { font: 400 14px var(--font-sans); fill: var(--color-text-primary); }
  .ts { font: 400 12px var(--font-sans); fill: var(--color-text-secondary); }
  .th { font: 500 14px var(--font-sans); fill: var(--color-text-primary); }
  .box { fill: var(--color-background-secondary); stroke: var(--color-border-tertiary); }
  .node { cursor: pointer; }
  .node:hover { opacity: 0.85; }
  .arr { stroke: var(--color-border-secondary); stroke-width: 1.5; fill: none; }
  .leader { stroke: var(--color-text-tertiary); stroke-width: 0.5; stroke-dasharray: 3 2; fill: none; }
`;
```

Extend the color ramps from `references/design-system.md` as needed.

## Message parsing

Split chat content on the `visualizer` fence:

```tsx
function ChatMessage({ content }) {
  const parts = content.split(/```visualizer\n([\s\S]*?)```/g);
  return (
    <div>
      {parts.map((part, i) => {
        if (i % 2 === 1) {
          return (
            <VisualWidget
              key={i}
              code={part}
              title={`visual-${i}`}
              onSendPrompt={(text) => sendMessage(text)}
            />
          );
        }
        return <Markdown key={i}>{part}</Markdown>;
      })}
    </div>
  );
}
```

## Streaming support

```typescript
function startStreaming(iframe, isDark) {
  const doc = iframe.contentDocument;
  doc.open();
  doc.write(`<style>${getThemeCSS(isDark)}\n${SVG_CLASSES}</style>`);
}

function appendChunk(iframe, chunk) {
  iframe.contentDocument.write(chunk);
}

function finishStreaming(iframe) {
  iframe.contentDocument.close();
}
```

## CSP

```text
default-src 'none';
script-src 'unsafe-inline' https://cdnjs.cloudflare.com https://esm.sh https://cdn.jsdelivr.net https://unpkg.com;
style-src 'unsafe-inline';
img-src data: blob:;
font-src https://cdnjs.cloudflare.com https://cdn.jsdelivr.net;
```
