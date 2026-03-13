# Diagram Reference

Three diagram families. Pick based on intent, not subject matter.

## Diagram types

Flowchart:

- use for steps in sequence or branching decisions
- good for workflows, pipelines, and lifecycles

Structural:

- use for containment and architecture
- good for nested systems, regions, and ownership

Illustrative:

- use to draw the mechanism itself
- good for physical systems and spatial metaphors
- default for "how does X work"

## Route on the verb

| User says | Type | What to draw |
|-----------|------|--------------|
| "how do LLMs work" | Illustrative | Token row, stacked layers, attention paths |
| "transformer architecture" | Structural | Labeled boxes for embeddings, attention, FFN |
| "how does attention work" | Illustrative | Query token and weighted fan-out |
| "training steps" | Flowchart | Forward, loss, backward, update |

## Flowchart rules

- at 14px, each character is about 8px wide
- keep about 60px between boxes
- keep 24px inner padding
- use one main direction of flow
- cap most diagrams at 4 or 5 nodes
- use L-bend paths if a straight connector would cross a box

Single-line node:

```svg
<g class="node c-blue" onclick="sendPrompt('Tell me about this')">
  <rect x="100" y="20" width="180" height="44" rx="8" stroke-width="0.5"/>
  <text class="th" x="190" y="42" text-anchor="middle" dominant-baseline="central">Label</text>
</g>
```

Two-line node:

```svg
<g class="node c-blue">
  <rect x="100" y="20" width="200" height="56" rx="8" stroke-width="0.5"/>
  <text class="th" x="200" y="38" text-anchor="middle" dominant-baseline="central">Title</text>
  <text class="ts" x="200" y="56" text-anchor="middle" dominant-baseline="central">Subtitle</text>
</g>
```

## Structural diagram rules

- large rounded rectangles for containers
- smaller rectangles inside for regions
- at least 20px inner padding
- at most 2 or 3 nesting levels
- external inputs and outputs should stay outside with arrows pointing in or out

Use different ramps for nested regions so the hierarchy remains visible.

For ERDs, prefer Mermaid rather than SVG.

## Illustrative diagram rules

Draw the mechanism, not a diagram about the mechanism.

- use freeform shapes when helpful
- let layout follow the system geometry
- use warm and cool color contrast for state or energy
- layer shapes when it clarifies the subject
- keep labels outside the main object with leader lines
- build in this order: silhouette, internal structure, external connections, state indicators

Prefer interactive visuals when the system has an obvious control.

## Common failures

1. arrow crosses a box
2. text overflows a box
3. viewBox clips the bottom or right edge
4. labels float without a leader or container
5. connector is missing `fill="none"`
6. centered text is missing `dominant-baseline="central"`
7. arrow marker is missing from `<defs>`
