---
name: visualise
description: "Render inline interactive visuals — SVG diagrams, HTML widgets, charts, and explainers — directly in the conversation. Use this skill whenever the user asks to visualize, diagram, chart, illustrate, or explain something visually, or when an explanation would genuinely benefit from a spatial or interactive diagram rather than text. Also triggers for flowcharts, architecture diagrams, data visualizations, interactive explainers, comparison layouts, UI mockups, and requests containing 'show me', 'draw', 'map out', 'visualize', or 'diagram'."
---

# Inline Visualizer

Render rich visual content: SVG diagrams, HTML interactive widgets, charts, and explainers. Keep visuals tight, native-looking, and directly useful to the current explanation.

## How it works

Generate raw HTML or SVG fragments. A compatible client can render the fragment inside a sandboxed iframe with injected theme variables.

Two output modes:

- SVG mode: output starts with `<svg>`. Best for static diagrams.
- HTML mode: output is a raw HTML fragment. Best for interactive controls, charts, and side-by-side explainers.

Do not emit `<html>`, `<head>`, or `<body>` tags.

## Codex note

This Codex setup may not have a `visualizer` renderer installed. Still generate standards-compliant HTML or SVG in the `visualizer` fence described below. If inline rendering is unavailable, say so briefly and keep the fragment usable as standalone HTML or SVG.

For client work to add native rendering support, read `references/client-implementation.md`.

## Before generating any visual

Read the design system reference before the first visual in a conversation:

1. Always read `references/design-system.md`.
2. Then read only the relevant module:
   - `references/diagrams.md` for flowcharts, structural diagrams, and illustrative diagrams
   - `references/components.md` for comparisons, cards, steppers, and interactive explainers
   - `references/charts.md` for charts and quantitative displays

Read `design-system.md` once per conversation. Read the module files only as needed.

## Streaming constraints

If the client streams visual output token by token, structure it in this order:

1. `<style>` first and keep it short
2. visible HTML or SVG next
3. `<script>` last

Because of streaming:

- avoid gradients, blur, glow, and shadows
- avoid hidden content and `display:none`
- avoid HTML and CSS comments
- prefer inline styles for first-paint correctness
- avoid tabs or carousels that start hidden

## Iframe sandbox rules

Assume the visual runs in a sandboxed iframe:

- no localStorage or sessionStorage
- no `position: fixed`
- no external fetches
- use only CDN assets from `cdnjs.cloudflare.com`, `esm.sh`, `cdn.jsdelivr.net`, or `unpkg.com`
- keep state in memory
- keep the background transparent

## The `sendPrompt` bridge

If the client exposes a global `sendPrompt(text)` function, use it for follow-up actions that should hand control back to the model. Keep filtering, sorting, toggling, and simple calculations in local JS instead.

## Choosing the right visual type

Route on the verb, not the noun:

| User says | Type | What to build |
|-----------|------|---------------|
| "how does X work" | Illustrative diagram | Spatial metaphor showing the mechanism |
| "what are the components of X" | Structural diagram | Labeled boxes showing containment |
| "walk me through the steps" | Flowchart | Sequential boxes and arrows |
| "compare X vs Y" | Comparison layout | Side-by-side cards with metrics |
| "show me the data" | Chart | Chart.js or inline data visualization |
| "explain X" when spatial | Interactive explainer | Controls and live state |

Default to illustrative for "how does X work". Do not flatten a visual idea into a safer flowchart unless the concept is genuinely sequential.

## Multiple visuals per response

Interleave prose and visuals:

1. short text block
2. visual
3. short transition
4. next visual if needed

Do not stack visuals back to back without explanatory text between them.

## Output wrapper

Wrap visual output in a `visualizer` code fence:

````markdown
```visualizer
<svg width="100%" viewBox="0 0 680 400">
  ...
</svg>
```
````

The fence content must be directly renderable as HTML or SVG.

## Quick reference

| Rule | Value |
|------|-------|
| SVG viewBox width | 680px |
| Label font | 14px |
| Subtitle font | 12px |
| Stroke width | 0.5px for borders and edges |
| Max colors per diagram | 2 to 3 ramps |
| Box subtitle length | 5 words max |
| SVG corner radius | `rx="4"` default, `rx="8"` for emphasis |
| HTML corner radius | `var(--border-radius-md)` or `var(--border-radius-lg)` |
| Min font size | 11px |
| Text weights | 400 and 500 only |

---

Source adapted from [bentossell/visualise](https://github.com/bentossell/visualise).
