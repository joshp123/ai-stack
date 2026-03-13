# UI Components Reference

Patterns for interactive explainers, comparisons, data records, metric cards, and steppers. All use HTML mode.

## Core aesthetic

Flat, clean surfaces. Minimal 0.5px borders. Generous whitespace. No gradients. No decorative shadows.

## Tokens

- Borders: `0.5px solid var(--color-border-tertiary)` or `-secondary` for emphasis
- Corner radius: `var(--border-radius-md)` for most elements, `var(--border-radius-lg)` for cards
- Cards: primary background, 0.5px border, large radius, `1rem 1.25rem` padding
- Spacing: rem for vertical rhythm, px for internal gaps

## Form elements

Inputs, selects, buttons, and sliders should be written as bare tags and styled by the host CSS. Override only what is necessary.

Buttons that trigger `sendPrompt` should append a `↗` arrow.

## Metric cards

```html
<div style="background: var(--color-background-secondary); border-radius: var(--border-radius-md); padding: 1rem;">
  <p style="font-size: 13px; color: var(--color-text-secondary); margin: 0 0 2px;">Label</p>
  <p style="font-size: 24px; font-weight: 500; margin: 0;">$3,870</p>
</div>
```

Use these in grids of 2 to 4 items:

```css
display: grid;
grid-template-columns: repeat(3, minmax(0, 1fr));
gap: 12px;
```

## Interactive explainer

```html
<div style="display: flex; align-items: center; gap: 12px; margin: 0 0 1.5rem;">
  <label style="font-size: 14px; color: var(--color-text-secondary);">Years</label>
  <input type="range" min="1" max="40" value="20" style="flex: 1;" oninput="update(this.value)"/>
  <span style="font-size: 14px; font-weight: 500; min-width: 24px;" id="out">20</span>
</div>
<div style="display: flex; align-items: baseline; gap: 8px;">
  <span style="font-size: 14px; color: var(--color-text-secondary);">£1,000 →</span>
  <span style="font-size: 24px; font-weight: 500;" id="result">£3,870</span>
</div>
```

## Comparison layout

```html
<div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px;">
  <div style="background: var(--color-background-primary); border: 0.5px solid var(--color-border-tertiary); border-radius: var(--border-radius-lg); padding: 1rem 1.25rem;">
    <p style="font-weight: 500; font-size: 15px; margin: 0 0 12px; color: var(--color-text-info);">Option A</p>
  </div>
  <div style="background: var(--color-background-primary); border: 0.5px solid var(--color-border-tertiary); border-radius: var(--border-radius-lg); padding: 1rem 1.25rem;">
    <p style="font-weight: 500; font-size: 15px; margin: 0 0 12px; color: var(--color-text-warning);">Option B</p>
  </div>
</div>
```

Recommended option:

- use `border: 2px solid var(--color-border-info)`
- add a small badge using `var(--color-background-info)` and `var(--color-text-info)`

## Data record card

```html
<div style="background: var(--color-background-primary); border-radius: var(--border-radius-lg); border: 0.5px solid var(--color-border-tertiary); padding: 1rem 1.25rem;">
  <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 16px;">
    <div style="width: 44px; height: 44px; border-radius: 50%; background: var(--color-background-info); display: flex; align-items: center; justify-content: center; font-weight: 500; font-size: 14px; color: var(--color-text-info);">MR</div>
    <div>
      <p style="font-weight: 500; font-size: 15px; margin: 0;">Name</p>
      <p style="font-size: 13px; color: var(--color-text-secondary); margin: 0;">Role</p>
    </div>
  </div>
</div>
```

## Stepper

Use for cyclical processes such as event loops or garbage collection:

```html
<div id="step-content" style="min-height: 200px; padding: 1rem 0;"></div>
<div style="display: flex; align-items: center; justify-content: space-between; padding-top: 12px; border-top: 0.5px solid var(--color-border-tertiary);">
  <button onclick="prev()">← Previous</button>
  <div style="display: flex; gap: 6px;" id="dots"></div>
  <button onclick="next()">Next →</button>
</div>
<script>
const steps = [{ title: 'Step 1', content: '...' }];
let current = 0;
function render() {
  document.getElementById('step-content').innerHTML =
    `<h3 style="font-size:16px;font-weight:500;margin:0 0 8px">${steps[current].title}</h3>
     <p style="font-size:14px;color:var(--color-text-secondary);margin:0">${steps[current].content}</p>`;
  document.getElementById('dots').innerHTML = steps.map((_, i) =>
    `<div style="width:8px;height:8px;border-radius:50%;background:${i===current?'var(--color-text-info)':'var(--color-border-tertiary)'}"></div>`
  ).join('');
}
function next() { current = (current + 1) % steps.length; render(); }
function prev() { current = (current - 1 + steps.length) % steps.length; render(); }
render();
</script>
```

## Mockups

Contained mockups should sit inside a secondary surface:

```html
<div style="background: var(--color-background-secondary); border-radius: var(--border-radius-lg); padding: 2rem; display: flex; justify-content: center;">
  <!-- mockup -->
</div>
```

Modal mockups should use a faux viewport instead of `position: fixed`.

## Grid overflow fix

Use `minmax(0, 1fr)` instead of plain `1fr`.
