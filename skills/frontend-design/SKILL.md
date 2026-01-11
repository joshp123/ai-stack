---
name: frontend-design
description: Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components, pages, or applications. Generates creative, polished code that avoids generic AI aesthetics.
---

# Frontend Design Skill

This skill guides creation of frontend interfaces that are both **well-designed** (usable, clear, appropriate) and **visually distinctive** (memorable, polished, intentional).

## Core Principle

Good frontend work requires two things that are often conflated:
1. **Design** — solving the right problem with appropriate structure, flow, and hierarchy
2. **Aesthetics** — making it visually compelling and memorable

Most AI-generated frontends fail at #1 and are mediocre at #2. This skill fixes both.

---

## Phase 1: Understand Before Building

**Do not write any code until you have internally answered:**

### What problem are we solving?
- What is the user trying to accomplish? (their goal, not the feature)
- What context are they in? (rushed? relaxed? expert? novice?)
- What does success look like for them?

### What are the constraints?
- Technical: framework, performance requirements, browser support
- Content: what information must be shown? what actions available?
- Scope: is this a full page, a component, a flow?

**CHECKPOINT**: If the goal is unclear, ASK. Do not guess and build the wrong thing.

---

## Phase 2: Structure the Information

**Before visual design, establish the bones:**

### What entities/objects exist?
- List the "things" being displayed or manipulated
- How do they relate to each other?

### What's the navigation/flow model?
- Is this a single screen or multi-step flow?
- What's the entry point? Exit points?
- If multi-step: what's the sequence? where can it branch?

### What are the states?
- Empty state (no data yet)
- Loading state
- Populated state (happy path)
- Error state (what can go wrong?)
- Edge cases (one item? thousands?)

**Apply**: Information architecture principles. Consider how Rosenfeld would organise this.

---

## Phase 3: Establish Hierarchy

**For each screen/view, determine what matters most:**

### The squint test
- If you blur the screen, what stands out?
- Is that the right thing?

### Rank every element
- **Primary**: The main event. What the user came for. ONE thing.
- **Secondary**: Supporting context. Needed but not the focus.
- **Tertiary**: Available if needed. Settings, help, edge cases.
- **Hidden**: Accessed via explicit action. Progressive disclosure.

### Visual hierarchy tools (in order of impact)
1. **Position**: Top-left (LTR) and above-fold gets seen first
2. **Size**: Bigger = more important
3. **Contrast**: High contrast = attention
4. **Whitespace**: Isolation increases prominence
5. **Colour**: Use sparingly for emphasis

**Apply**: Progressive disclosure, Miller's Law (chunk information), Fitts's Law (important actions should be large and reachable).

**CHECKPOINT**: Can you state the ONE primary thing per screen? If not, simplify.

---

## Phase 4: Select Patterns

**Match problems to established solutions. Don't reinvent.**

### Navigation
- < 5 sections → tabs or top nav
- 5-15 sections → sidebar
- Deep hierarchy → breadcrumbs required
- Task-focused → wizard/stepper

### Data display
- < 10 items → list or cards
- 10-100 items → table with sort/filter
- > 100 items → pagination or virtual scroll + search
- Comparison needed → table
- Visual/scannable → cards

### Forms
- < 5 fields → single section
- 5-15 fields → logical groupings
- > 15 fields → multi-step wizard
- High stakes → confirmation step

### Feedback
- Instant action result → inline feedback or toast
- Background process → progress indicator
- Error → inline at source, specific message, recovery path
- Success → confirmation + clear next action

### States (always design these)
- **Empty**: Explain value, single CTA to get started
- **Loading**: Skeleton or spinner, never blank
- **Error**: What went wrong, how to fix it
- **Partial**: Some data loaded, some failed

**Apply**: Jakob's Law — users expect conventions. Check how Polaris, Carbon, or Material solve this problem.

---

## Phase 5: Visual Design

**Now — and only now — make it visually distinctive.**

### Commit to an aesthetic direction
Don't be generic. Pick a clear tone:
- Brutally minimal / Maximalist rich
- Editorial / Magazine / Luxury
- Playful / Toy-like / Rounded
- Industrial / Utilitarian / Dense
- Retro / Nostalgic / Period-specific
- Organic / Natural / Soft
- Technical / Data-heavy / Dashboard
- Brutalist / Raw / Exposed

The direction should match the context. A legal document tool shouldn't look like a children's game.

### Typography
- **Never use**: Inter, Roboto, Arial, system-ui as display fonts. These are AI slop defaults.
- **Do use**: Distinctive, characterful fonts appropriate to the aesthetic
- **Pair intentionally**: Display font for headings + readable body font
- **Establish scale**: Clear hierarchy through size (use a ratio: 1.2, 1.25, 1.333)

### Colour
- **Commit to a palette**: 1-2 dominant colours, 1 accent, semantic colours for states
- **Avoid**: Purple-to-blue gradients on white (AI cliché), evenly-distributed rainbow palettes
- **Ensure contrast**: 4.5:1 minimum for text, 3:1 for UI elements
- **Use colour meaningfully**: Not just decoration — colour should communicate

### Spacing
- **Use a consistent scale**: Base unit of 4px or 8px
- **Spacing communicates grouping**: Related things are closer together
- **Generous whitespace beats cramming**: Let elements breathe

### Visual details (use intentionally, not by default)
- **Depth**: Shadows, layering, overlaps — but only if it serves hierarchy
- **Texture**: Noise, grain, patterns — but only if it matches aesthetic
- **Motion**: Transitions, micro-interactions — but purposeful, not gratuitous
- **Effects**: Gradients, glows, blurs — but cohesive with overall design

### Layout
- Break the grid occasionally — asymmetry creates interest
- Full-bleed moments for impact
- Consistent alignment creates calm; intentional breaks create focus

**CRITICAL**: Match complexity to vision. Maximalist designs need elaborate implementation. Minimalist designs need restraint and precision. Both require intention.

---

## Phase 6: Verify Before Output

**Do not output code until you have checked:**

### Usability (Nielsen's heuristics)
- [ ] System status visible (loading, errors, success)
- [ ] Uses familiar language and conventions
- [ ] User can undo/escape/go back
- [ ] Consistent patterns throughout
- [ ] Errors are prevented where possible
- [ ] Recognition over recall (options visible)
- [ ] Primary actions are obvious
- [ ] No unnecessary elements
- [ ] Error messages are helpful and specific
- [ ] Help is available if needed

### Accessibility (minimum)
- [ ] Interactive elements are keyboard accessible
- [ ] Focus states are visible
- [ ] Colour contrast meets ratios
- [ ] Images have alt text
- [ ] Form inputs have labels
- [ ] Not relying on colour alone

### Completeness
- [ ] Empty state designed
- [ ] Loading state designed
- [ ] Error state designed
- [ ] All interactive states (hover, active, disabled)

---

## Anti-Patterns (Never Do These)

### UX failures
- ❌ Modal for non-blocking information
- ❌ Infinite scroll without position indicator
- ❌ Form with no validation feedback
- ❌ Generic "Something went wrong" errors
- ❌ Actions with no confirmation on destructive operations
- ❌ Hiding primary actions in menus
- ❌ Requiring hover to discover functionality (breaks touch)

### Visual failures
- ❌ Placeholder text as the only label
- ❌ Colour as the only differentiator
- ❌ Low contrast text
- ❌ Tiny click targets (minimum 44px)
- ❌ Custom controls that break keyboard navigation
- ❌ Text over busy images without treatment

### AI slop indicators
- ❌ Inter/Roboto/Arial as display fonts
- ❌ Purple-blue gradient on white background
- ❌ Generic "hero with text left, image right" without purpose
- ❌ Overly rounded corners on everything
- ❌ Shadows on every element
- ❌ Stock illustration style (Undraw, etc.) without customisation
- ❌ "Lorem ipsum" in final output

---

## Quick Reference: The Process
```
1. UNDERSTAND → What's the goal? What are constraints?
2. STRUCTURE  → What entities? What flow? What states?
3. HIERARCHY  → What's primary? Secondary? Hidden?
4. PATTERNS   → What established solutions apply?
5. VISUAL     → What aesthetic? Execute with intention.
6. VERIFY     → Heuristics pass? States complete? Accessible?
```

All phases happen internally before code output. User sees only the final, considered result.

---

## Implementation Notes

- Output production-ready code (HTML/CSS/JS, React, Vue, etc.)
- Use CSS variables for theming
- Prefer CSS for animation where possible; use Motion library for React when needed
- Include responsive considerations
- Comment complex visual techniques
