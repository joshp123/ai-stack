# Design System Reference

The core design tokens and rules for every visual. Read this once per conversation before generating visual output.

## Philosophy

- Seamless: match the host app
- Flat: no gradients, noise, or decorative effects
- Compact: show the key idea inline
- Put explanations in prose and visuals in the visual block

## CSS variables

Use injected CSS variables. Do not hardcode host colors.

Backgrounds:

- `--color-background-primary`
- `--color-background-secondary`
- `--color-background-tertiary`
- `--color-background-info`
- `--color-background-danger`
- `--color-background-success`
- `--color-background-warning`

Text:

- `--color-text-primary`
- `--color-text-secondary`
- `--color-text-tertiary`
- `--color-text-info`
- `--color-text-danger`
- `--color-text-success`
- `--color-text-warning`

Borders:

- `--color-border-tertiary`
- `--color-border-secondary`
- `--color-border-primary`

Typography:

- `--font-sans`
- `--font-serif`
- `--font-mono`

Layout:

- `--border-radius-md`
- `--border-radius-lg`
- `--border-radius-xl`

## Color ramps

Use named ramps for categorical meaning:

| Name | 50 | 100 | 200 | 400 | 600 | 800 | 900 |
|------|-----|-----|-----|-----|-----|-----|-----|
| purple | #EEEDFE | #CECBF6 | #AFA9EC | #7F77DD | #534AB7 | #3C3489 | #26215C |
| teal | #E1F5EE | #9FE1CB | #5DCAA5 | #1D9E75 | #0F6E56 | #085041 | #04342C |
| coral | #FAECE7 | #F5C4B3 | #F0997B | #D85A30 | #993C1D | #712B13 | #4A1B0C |
| pink | #FBEAF0 | #F4C0D1 | #ED93B1 | #D4537E | #993556 | #72243E | #4B1528 |
| gray | #F1EFE8 | #D3D1C7 | #B4B2A9 | #888780 | #5F5E5A | #444441 | #2C2C2A |
| blue | #E6F1FB | #B5D4F4 | #85B7EB | #378ADD | #185FA5 | #0C447C | #042C53 |
| green | #EAF3DE | #C0DD97 | #97C459 | #639922 | #3B6D11 | #27500A | #173404 |
| amber | #FAEEDA | #FAC775 | #EF9F27 | #BA7517 | #854F0B | #633806 | #412402 |
| red | #FCEBEB | #F7C1C1 | #F09595 | #E24B4A | #A32D2D | #791F1F | #501313 |

## Color assignment

- use color for meaning, not sequence
- group related nodes by category
- use gray for neutral or structural nodes
- keep most diagrams to 2 or 3 ramps
- reserve blue, green, amber, and red for semantic states

Text on colored fills should come from the darker stop of the same ramp.

## SVG setup

```svg
<svg width="100%" viewBox="0 0 680 H">
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5"
      markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M2 1L8 5L2 9" fill="none" stroke="context-stroke"
        stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
    </marker>
  </defs>
</svg>
```

Rules:

- viewBox width is always 680
- safe area is x=40 to x=640
- background stays transparent
- arrow marker should inherit stroke color

## SVG classes

Text:

- `t` for 14px primary
- `ts` for 12px secondary
- `th` for 14px weight 500

Shapes:

- `box`
- `node`
- `arr`
- `leader`

Colors:

- `c-purple`
- `c-teal`
- `c-coral`
- `c-pink`
- `c-gray`
- `c-blue`
- `c-green`
- `c-amber`
- `c-red`

Apply color classes to groups or basic shapes, not connector paths.

## Font width calibration

- 14px text: about 8px per character
- 12px text: about 7px per character
- `box_width = max(title_chars * 8, subtitle_chars * 7) + 24`

If subtitle text needs wrapping, shorten it instead.

## Text positioning

For text centered in boxes, use `dominant-baseline="central"`.

## viewBox checklist

1. find the lowest visible element
2. add 40px bottom padding
3. keep the right edge within x=640
4. avoid negative coordinates

## HTML rules

- no emoji
- no font size below 11px
- sentence case only
- no mid-sentence bolding
- round displayed numbers
- keep colored text within the same color family
- avoid rounded corners on single-sided borders
