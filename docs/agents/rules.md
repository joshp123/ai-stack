---
written_by: ai
---

# Rules

The engineering and process rules for Josh's agents. Repo-local rules may add
details or override these when the local context is more specific.

## 1. Code

1. Boring code wins. Simple, explicit, local, readable.
2. Build the smallest thing that fully solves the problem. No smaller, no
   bigger.
3. One obvious way to do each thing. No knobs, no modes, no second matcher doing
   the same job differently. The Zen of Python is the reference:

   > Beautiful is better than ugly.
   > Explicit is better than implicit.
   > Simple is better than complex.
   > Complex is better than complicated.
   > Flat is better than nested.
   > Sparse is better than dense.
   > Readability counts.
   > Special cases aren't special enough to break the rules.
   > Although practicality beats purity.
   > Errors should never pass silently.
   > Unless explicitly silenced.
   > In the face of ambiguity, refuse the temptation to guess.
   > There should be one and preferably only one obvious way to do it.
   > Although that way may not be obvious at first unless you're Dutch.
   > Now is better than never.
   > Although never is often better than right now.
   > If the implementation is hard to explain, it's a bad idea.
   > If the implementation is easy to explain, it may be a good idea.
   > Namespaces are one honking great idea. Let's do more of those!

4. Delete concepts instead of explaining them. An abstraction, flag, retry or
   fallback needs current, proven, repeated pain to exist.
5. ZFC: cognition goes to models, shells stay deterministic. Read the memo:
   `~/code/nix/ai-stack/docs/agents/ZFC.md`. Shells never rank, score,
   keyword-route or judge quality. Any semantic decision - is this a receipt,
   which item, what quality - goes to a model. One carve-out: deterministic code
   may make a bounded structural choice only when all three hold:
   - the same input must give the same output every time because agents retry
     against it, so query-time stability is a contract property
   - it operates on structure, not on meaning a model could judge better at the
     same layer
   - a model call there is architecturally wrong on latency and the
     precompute-at-sync-time alternative was considered and rejected in writing

   A full-text search index qualifies; that is the intent, not a loophole.
   Every carve-out is documented at its call site; an undocumented heuristic is
   a violation.
6. In ambiguity, refuse and list candidates. A close match suggests; it never
   silently resolves.
7. Code is self-documenting, for humans and for agents. A scan of the file tells
   you what it does. Weird complexity, stringly typed data and leaked
   abstractions are bugs, not style.
8. One language per file. Shell lives in `.sh`, Go in `.go`, Swift in `.swift`.
   Code embedded in strings inside another language is banned. Prompts and long
   natural-language templates live in their own text files, not inline in code.
   The fewer languages, the better.
9. Prefer real code over scripting. When logic grows past plumbing, it moves out
   of shell.
10. Right tool for the job, and a collapsing tech stack. Match the repo first.
    Every new tool or surface must earn its place, and two surfaces that can be
    one become one.
11. Regular expressions are a last resort. Occasionally the right tool, usually
    a smell; remove them where a parser, exact match or model does the job
    honestly.
12. Files stay under about 500 lines. Split before the limit, into human-named
    files.
13. Check both sides of every model call raw. Read the exact bytes sent in -
    after selection, truncation and formatting - and sample the artifact that
    came out against source. Schema checks and benchmark scores have both
    certified garbage: an extractor once ran hundreds of calls over inputs whose
    bodies were empty or cut short, and a schema check and benchmark score both
    passed while the output was hollow. Reading one input batch would have
    caught it before the first commit.
14. Sample before you spend. A heavy or expensive run first runs a small slice;
    its raw output is read and judged against the bar; only then does the full
    run fire. Firing the fleet on an unverified pipeline burns time and quota on
    garbage.
15. Deficient input is an alarm, not a row. A model given nothing says so; the
    shell counts it and aborts when it dominates.
16. Derived state self-heals at the point of use, with one log line. A repair
    verb or `--fix` flag is a design bug.
17. Before v1.0, breaking can be correct when data can be re-derived and no
    stable caller contract exists. Do not add shims, deprecation paths or
    migration code without a real stable surface to protect.
18. Wire and inter-process contracts should be typed and generated when the repo
    has that standard. Do not hand-roll encodings. JSON is fine for user
    `--json` output and for repos whose established contract is JSON.
19. Pin upstream tool minimums, and re-check upstream for new primitives before
    building a workaround. Fast-moving tools grow the primitive you are about to
    hand-roll.

## 2. Output: the design bar

Every output is designed for humans and agents at once. If a human reads it cold
and gets it, an agent will too.

1. Beautiful, clear, predictable. Proper wrapping, real columns, deliberate
   spacing and padding. Ugly output is a bug.
2. Field names carry human meaning. Use semantic fields a person would say out
   loud.
3. No machine slop reaches a reader. Short human identifiers, never long machine
   refs. Surface names, never internal module names. No internal abstraction
   leaks into any output, error or log a user sees.
4. Hints are separated from content. Next-step guidance sits on its own line,
   clearly spaced, self-explanatory, never crammed onto a data line.
5. Progressive discovery. The tool teaches itself: no information dumps, no
   required documentation, no skills to read first. An agent zero-shots onto the
   tool from its own output and help text, surface by surface.
6. Logging is part of definition of done. Clean output by default; verbose modes
   stream detail; help pages name the flag and the log file; any failure is
   diagnosable from the log alone.
7. The check is reading every permutation, raw. Before an output surface ships,
   run every permutation of it - every verb, human and JSON mode, both terminal
   widths, success and failure, not just the happy path - and read each one.
   This is also a standing argument for fewer permutations, not more.
8. Output structure follows `https://clig.dev` and the `anti-slop-output` skill.
   Human field names, plain language, front-loaded - the same bar as prose,
   applied to a CLI. It is all one thing.
9. An output-shape change gates on a model review, never a script. A model that
   did not write the change reads raw transcripts of every affected permutation
   through the surface users actually see. Anything unparseable is slop;
   anything they would still have to ask is missing. Conformance and schema
   checks are tripwires that remember past defects and prove nothing new; when
   review finds a defect class, add a tripwire, but review stays the gate.

## 3. Architecture: the tree is the map

1. Running `tree` reveals the project: what it is, how it works, where things
   live, ideally without reading a line of documentation. Naming and structure
   carry the ontology.
2. Modules are deep with small, clear interfaces. Modularity exists to let many
   agents work in parallel without stepping on each other - clear boundaries
   shrink blast radius - never as theatre.
3. Interface boundaries are explicit and beautiful. If two agents keep colliding
   in one file, the boundary is wrong; fix the structure, not the scheduling.

## 4. Models and grounding

Read `~/.config/ai/models.md` before choosing a model or calling a model outside
the current harness.

1. Use the appropriate model for the job, and parallelise with subagents. Model
   choice is per task, never per session.
2. Bulk classification and extraction run on the best current cheap model, not
   whatever happens to be installed. Before picking, survey the latest open
   models from the Chinese labs and Google: Qwen, DeepSeek, Kimi, GLM/Zhipu,
   MiniMax, Gemma and peers, sorted by release date. Re-survey often; models age
   in weeks. Verify the winner against a raw-graded sample before the fleet.
3. Use the native harness for its own frontier model: Codex for Codex, Claude
   Code for human-driven Claude work, and Pi for agent-driven external model
   calls. Use the best taste model available for product decisions, output
   design, hard reviews and copy; do not burn it on mechanical work.
4. Agentic workflows use Pi when the current harness needs to call another
   provider.
5. The capability tech tree builds in order: agents reading, agents evaluating,
   benchmarks, golden path tasks. Every layer is grounded in what a real human
   actually asked or would do, never in scenarios an agent invented.
6. Agents drift toward the boring mean. We want taste and opinion; deviate from
   the mean deliberately where it serves the vision.

## 5. Process rules

1. Every agent diff gets an adversarial model review before commit. Human review
   is for taste, not for catching violations.
2. The reviewer assumes the work is wrong until raw evidence proves otherwise.
   It refutes; it never says "looks great".
3. Recurring sweeps re-check everything committed since the last sweep, so a
   slipped violation is caught before it compounds.
4. An ask for Josh is a grilling round: concrete question, pre-chewed options,
   one decision at a time. Never a passive "blocked on you" line. This covers
   every decision presented to Josh, with no implicit form allowed. A decision
   named in passing, bundled into a multi-part "approve?", or left as a list
   item in a briefing is a violation. Each is its own explicit question with the
   options, the recommendation, and the reason. Asks are non-blocking when
   independent work can continue.
5. Agents produce the answer; Josh confirms it. An ask that needs Josh to
   generate content from memory is an invalid ask.
6. Never tell Josh to read a file. Open it or put it in front of him.
7. Maximum parallelism, scoped blast radius. Lanes run concurrently whenever
   their write-sets are disjoint. Serialize only what genuinely shares a
   write-set. Two lanes needing the same file is a partitioning bug - fix the
   split or module boundary, do not queue the agents. A merge conflict or
   reimplementation churn is evidence the partition was wrong, not that
   parallelism is wrong.
8. Done needs a sign-off naming what was probed and the raw evidence seen. A
   claim is not evidence.
9. A finding becomes a tracked item or a fix, never a notes file named after the
   process that found it.
10. Artifacts gate like code. Any user-visible artifact passes an adversarial
    review: anti-slop, correctness against raw, and a completeness pass before
    it is installed or shown.
11. Runs abort early, not at the end. Long runs verify their first unit raw
    before the rest executes, and alarms evaluate incrementally.
12. After two misses on the same ask, stop repeating the method. Inspect the
    failed artifact, name the root cause or the exact unknown, and change
    approach.

## 6. Evidence gate

Answered with evidence before done:

- which rules did this touch, and how was each checked
- what raw input and raw output were read, exactly
- does every output line pass the design bar: human-clear, agent-clear,
  beautiful, hints separated, no machine slop
- is the change diagnosable from logs or command output alone
- what exists here beyond what was asked, if anything, and why
- is the diff boring and the tree still the map
- what would Josh object to if he read this now
