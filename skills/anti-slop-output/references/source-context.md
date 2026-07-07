---
written_by: ai
---

# Source context

This reference exists for future edits to the skill. Ordinary writing tasks should use `SKILL.md` only.

## Source material pulled

- @fofrAI, 26 June 2026: original tweet introducing a GOV.UK-derived writing skill for badly formatted agent reports.
  Source: https://x.com/fofrAI/status/2070504201256317168
- @fofrAI gist: original `govuk-style` skill.
  Source: https://gist.github.com/fofr/505e225f9bf5e839d30c12ba6bfa0be2
- @fofrAI, 29 June 2026: follow-up saying the skill is now used for everything an agent writes.
  Source: https://x.com/fofrAI/status/2071539446059610459
- @jjpcodes, 27 June 2026 reply: the useful move is to deslopify all agent output, not just reports, because clearer conversations help code too.
  Source: https://x.com/jjpcodes/status/2070768413727670716
- @jjpcodes, 30 June 2026 quote tweet: frame this as an anti-slop skill that actually helps, built from the browser appshots, source skill, and tweet context.
  Source: https://x.com/jjpcodes/status/2071883248263708943

## GOV.UK sources used

- GOV.UK writing standards overview and tone of voice:
  https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/tone-of-voice/
- Meet user needs:
  https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/writing-guidelines/meet-user-needs/
- Clear structure:
  https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/writing-guidelines/clear-structure/
- Clear language:
  https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/writing-guidelines/clear-language/
- Right tone:
  https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/writing-guidelines/right-tone/
- Link guidance:
  https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/writing-guidelines/add-links/
- A to Z style guide:
  https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/style-guides/a-to-z-style-guide/
- Government Design Principles:
  https://www.gov.uk/guidance/government-design-principles

## Implementation notes

The source gist is short and report-oriented. The current `SKILL.md` is intentionally a minimal adaptation of it, not a rewrite. It keeps the main wording and GOV.UK-derived structure, but changes the scope:

- trigger for all human-facing agent output, including chat, status, plans, reviews, PR text, docs, summaries, comments, and emails
- use British English for agent-authored prose
- keep facts, source text, code, logs, paths, identifiers, quotes, legal text, and error strings exact
- use plain structure and concrete wording without flattening technical meaning
- treat Markdown as structure, not decoration
- keep Josh's anti-slop framing: useful first, concrete first, no agent report voice

## Claude review

Claude reviewed the first draft on 30 June 2026 and found:

- the all-output scope matched the stated intent
- the English-variant handling in the first draft was wrong for Josh and needed correction
- the skill should include stronger GOV.UK rules for sentence length, acronyms, capitalisation and tables
- the no-bold rule should stay close to the original unless future use shows it is too strict

The follow-up edit deliberately changed the default to British English. The later fidelity edit replaced the expanded draft with a near-original version and kept only the necessary all-output, British English, and exactness changes.

Keep future edits compact so loading the skill does not make ordinary responses heavier.
