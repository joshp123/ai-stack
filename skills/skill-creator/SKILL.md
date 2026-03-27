---
name: skill-creator
description: Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends an AI coding agent's capabilities with specialized knowledge, workflows, or tool integrations.
license: Complete terms in LICENSE.txt
---

# Skill Creator

This skill provides guidance for creating effective skills.

## About Skills

Skills are modular, self-contained folders that extend an AI coding agent's capabilities by providing specialized knowledge, workflows, and tools. Think of them as onboarding guides for specific domains or tasks. They transform a general-purpose agent into a specialized agent equipped with procedural knowledge that no model can fully possess.

### What Skills Provide

1. Specialized workflows - Multi-step procedures for specific domains
2. Tool integrations - Instructions for working with specific file formats or APIs
3. Domain expertise - Company-specific knowledge, schemas, business logic
4. Bundled resources - Scripts, references, and assets for complex and repetitive tasks

## Core Principles

### Concise Is Key

The context window is a public good. Skills share the context window with the system prompt, conversation history, other skill metadata, and the user request.

Default assumption: the agent is already very smart. Only add context the agent does not already have. Challenge each paragraph: does this information justify its token cost?

Prefer concise examples over verbose explanations.

### Set Appropriate Degrees Of Freedom

Match the level of specificity to the task's fragility and variability:

- High freedom: text-based instructions when multiple approaches are valid
- Medium freedom: pseudocode or scripts with parameters when a preferred pattern exists
- Low freedom: specific scripts with few parameters when the operation is fragile and consistency matters

### Protect Validation Integrity

Use independent validation when realistic testing matters. When subagents are available, they are useful for forward-testing, but treat that as evaluation rather than answer leakage:

- pass raw artifacts, prompts, logs, or diffs
- avoid passing the intended answer or suspected fix
- keep prompts generic enough that success depends on transferable reasoning

## Anatomy Of A Skill

Every skill consists of a required SKILL.md file and optional bundled resources:

```text
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter metadata (required)
│   │   ├── name: (required)
│   │   └── description: (required)
│   └── Markdown instructions (required)
└── Bundled Resources (optional)
    ├── scripts/          - Executable code (Python/Bash/etc.)
    ├── references/       - Documentation intended to be loaded into context as needed
    └── assets/           - Files used in output (templates, icons, fonts, etc.)
```

### SKILL.md

Every SKILL.md consists of:

- Frontmatter (YAML): `name` and `description` are the main trigger surface for skill selection
- Body (Markdown): instructions and guidance used after the skill triggers

### Bundled Resources

#### Scripts

Executable code for tasks that require deterministic reliability or are repeatedly rewritten.

- When to include: when the same code is being rewritten repeatedly or deterministic reliability is needed
- Example: `scripts/rotate_pdf.py` for PDF rotation tasks
- Benefits: token efficient, deterministic, may be executed without loading into context
- Note: scripts may still need to be read by the agent for patching or environment-specific adjustments

#### References

Documentation and reference material intended to be loaded into context as needed.

- When to include: when the agent should reference documentation while working
- Examples: API docs, schemas, policies, domain-specific workflow guides
- Benefits: keeps SKILL.md lean and loads detailed context only when needed
- Best practice: if files are large, include search guidance in SKILL.md
- Avoid duplication: keep information either in SKILL.md or in references, not both

#### Assets

Files not intended to be loaded into context, but used within the output the agent produces.

- When to include: when the skill needs templates, images, icons, fonts, or boilerplate output files
- Benefits: separates output resources from documentation

### What Not To Include

Only include files that directly support the skill. Do not create extra documentation like:

- README.md
- INSTALLATION_GUIDE.md
- QUICK_REFERENCE.md
- CHANGELOG.md

The skill should contain the information needed for another agent to do the job. Skip auxiliary process docs.

## Progressive Disclosure

Skills use a three-level loading system to manage context efficiently:

1. Metadata (name + description) - always in context
2. SKILL.md body - loaded when the skill triggers
3. Bundled resources - loaded only when needed

Keep SKILL.md under roughly 500 lines. Split variant-specific details into reference files and link them directly from SKILL.md. Avoid deeply nested reference chains.

## Skill Creation Process

Skill creation involves these steps:

1. Understand the skill with concrete examples
2. Plan reusable skill contents
3. Initialize the skill
4. Edit the skill
5. Validate the skill
6. Iterate and forward-test when warranted

Follow these steps in order, skipping only when there is a clear reason.

### Skill Naming

- Use lowercase letters, digits, and hyphens only
- Normalize user-provided titles to hyphen-case
- Keep names under 64 characters
- Prefer short verb-led phrases
- Namespace by tool when it improves clarity, e.g. `gh-address-comments`

### Step 1: Understand The Skill With Concrete Examples

Skip this step only when the skill's usage patterns are already clearly understood.

To create an effective skill, understand concrete examples of how it will be used. This can come from direct user examples or from generated examples validated with user feedback.

Avoid overwhelming users. Start with the most important questions and follow up as needed.

### Step 2: Plan The Reusable Skill Contents

For each example:

1. Consider how to execute the task from scratch
2. Identify what scripts, references, and assets would help when repeating that work

Examples:

- A PDF rotation task suggests `scripts/rotate_pdf.py`
- A frontend app builder suggests template assets
- A BigQuery skill suggests schema references

### Step 3: Initialize The Skill

Skip this step only if the skill already exists.

When creating a new skill from scratch, run:

```bash
scripts/init_skill.py <skill-name> --path <output-directory>
```

Examples:

```bash
scripts/init_skill.py my-skill --path skills/public
```

The initializer:

- creates the skill directory
- generates SKILL.md with proper frontmatter placeholders
- creates example resource directories
- adds example files that can be customized or deleted

After initialization, customize the generated files and delete placeholder material that is not needed.

### Step 4: Edit The Skill

When editing the skill, remember that it is being created for another agent to use. Include information that is beneficial and non-obvious. Focus on procedural knowledge, domain-specific details, and reusable assets that materially improve execution.

After substantial revisions, or if the skill is tricky, forward-test it on realistic tasks. When subagents are available, use them as an evaluation surface rather than leaking your conclusions.

#### Start With Reusable Skill Contents

Start with the reusable resources identified earlier: `scripts/`, `references/`, and `assets/`.

Added scripts must be tested by actually running them. If there are many similar scripts, test a representative sample. If `--examples` was used, delete placeholder files that are not needed.

#### Update SKILL.md

Writing guidelines:

- Use imperative or infinitive form
- Make the frontmatter do the trigger work
- Put all "when to use" information in `description`, not in the body
- Keep the body focused on how to execute

##### Frontmatter

Write YAML frontmatter with `name` and `description`.

- `name`: the skill name
- `description`: the primary triggering mechanism
  - include both what the skill does and the concrete contexts that should trigger it
  - do not hide trigger information in a "When to Use" body section

##### Body

Write the workflow and explain how to use the bundled resources.

### Step 5: Validate The Skill

Once development is complete, run:

```bash
scripts/quick_validate.py <path/to/skill-folder>
```

Fix any reported issues and rerun until it passes.

### Step 6: Iterate

After testing the skill, use real outcomes to improve it.

Iteration workflow:

1. Use the skill on real tasks
2. Notice struggles or inefficiencies
3. Identify how SKILL.md or bundled resources should change
4. Implement changes and test again
5. Forward-test when it is reasonable and useful

## Forward-Testing

To forward-test, launch subagents or fresh sessions with minimal context.

Good prompt shape:

`Use $skill-x at /path/to/skill-x to solve problem y`

Bad prompt shape:

`Review the skill at /path/to/skill-x; pretend a user asks you to...`

Decision rule:

- err on the side of forward-testing
- ask for approval if it could take a long time, need additional approvals, or touch live production systems

Considerations:

- use fresh threads for independent passes
- pass the skill and task the way a user would
- pass raw artifacts, not your diagnosis
- avoid showing expected answers or intended fixes
- rebuild context from source artifacts after each iteration
- clean up test artifacts between passes when contamination matters

If forward-testing only works when the evaluator sees leaked context, tighten the skill or the test setup before trusting the result.
