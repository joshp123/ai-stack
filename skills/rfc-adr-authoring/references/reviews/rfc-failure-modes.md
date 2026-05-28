# RFC Failure Modes And Calibration Examples

Use this as calibration before drafting or revising a high-stakes RFC. The point is not to copy the sections. The point is to notice what a bad agent reaches for when it has not understood the system, and what a stronger RFC does instead.

## Failure Mode: Placeholder Decision

Bad fragment:

```markdown
V1a should support Slack-class plugins. Upstream changes are probably needed, and richer provenance can come later.
```

Why it failed:

- "Slack-class" is not a real engineering boundary.
- "Probably needed" asks the reader to trust the author instead of showing the mechanism.
- "Later" hides whether the current slice is sound without the deferred work.

Better fragment:

```markdown
V1a scope is official runtime packages whose published tarball is already complete enough to load without dependency installation: packages with no runtime dependencies, or packages whose runtime dependencies are already bundled in the published tarball.

This does not require an upstream OpenClaw change. OpenClaw already supports loading a prepared plugin directory from `plugins.load.paths`; Nix can produce that prepared directory and render `plugins.entries.<id>.enabled = true`.
```

The better version names the actual artifact class, names the existing interface, and makes the upstream-change claim falsifiable.

## Failure Mode: Pretending Mutable State Is Declarative

Bad fragment:

```markdown
Make OpenClaw read already installed plugins as if the user had run `openclaw plugins install`, but without actually running the command.
```

Why it failed:

- It describes a desired illusion, not an ownership model.
- It blurs three different things: package preparation, install receipts, and runtime loading.
- It invites Nix to forge mutable lifecycle state that rollback cannot own.

Better fragment:

```markdown
OpenClaw runtime plugin support has two separable jobs:

1. prepare a plugin directory that already contains runtime code and dependencies;
2. tell OpenClaw to discover, trust, and start that prepared directory.

Mutable OpenClaw does both through `openclaw plugins install`. Nix should do job 1 by producing an immutable plugin root. nix-openclaw should do job 2 by rendering normal OpenClaw config.
```

The better version separates responsibilities before proposing mechanics. That made the rest of the RFC easier to evaluate.

## Failure Mode: Version Policy Escape Hatch

Bad fragment:

```markdown
Use npm latest by default, or follow the package manager version unless a reviewed lock entry says otherwise.
```

Why it failed:

- `latest` and dist-tags are registry-time decisions, not reproducible inputs.
- "Unless reviewed" is an undefined bypass around the supply-chain policy.
- It never answers whether plugin versions are tied to the OpenClaw version or chosen independently.

Better fragment:

```markdown
Official runtime plugin versions are tied to the pinned OpenClaw release version for V1a.

For each supported plugin, nix-openclaw records an exact npm tarball URL and fixed hash in the flake-locked source. User builds never resolve semver, query npm, or run a package manager.

No per-plugin version override exists in V1a. If overrides are needed later, they need a separate exact-version policy and proof gates.
```

The better version is boring and narrow. It answers the reproducibility question before adding flexibility.

## Failure Mode: Configuration Surface Mush

Bad fragment:

```nix
programs.openclaw.runtimePlugins.slack = {
  enabled = true;
  config = {
    mode = "socket";
  };
};
```

Why it failed:

- It invents a Nix-only plugin config surface.
- It hides upstream OpenClaw config semantics behind a second API.
- It makes the selection surface and runtime configuration surface look like one thing.

Better fragment:

```nix
programs.openclaw.runtimePlugins = [
  "slack"
];

programs.openclaw.config.channels.slack = {
  mode = "socket";
  appToken.source = "env";
  appToken.provider = "env";
  appToken.id = "SLACK_APP_TOKEN";
  botToken.source = "env";
  botToken.provider = "env";
  botToken.id = "SLACK_BOT_TOKEN";
};
```

The better version keeps Nix selection small and leaves runtime configuration in the upstream OpenClaw shape.

## Failure Mode: Warning Instead Of Deciding

Bad fragment:

```markdown
If users set both raw plugin load paths and runtime plugins, warn or try to deduplicate them.
```

Why it failed:

- It leaves ownership ambiguous.
- It turns a design contradiction into runtime behavior.
- It asks future maintainers to debug precedence rules instead of rejecting the mixed surface.

Better fragment:

```markdown
It is an eval error to mix raw `plugins.load.paths` with `runtimePlugins` in the same instance.

If a user needs raw load paths, they own that OpenClaw config surface directly. If they use `runtimePlugins`, nix-openclaw owns the generated load paths for that instance.
```

The better version makes the boundary visible at config evaluation time.

## Failure Mode: Evidence Drift

Bad fragment:

```markdown
Evidence:
- old package diff
- unrelated plugin example
- TODO from a previous draft
```

Why it failed:

- Stale evidence made the RFC look broader than the verified source state.
- Unrelated package names distracted from the actual claim.
- The reviewer could not tell which facts were current.

Better fragment:

```markdown
Evidence:
- `src/plugins/discovery.ts`: explicit config-selected plugin directories are discovered from `plugins.load.paths`.
- `src/plugins/config-activation-shared.ts`: config-origin plugins are selected by `plugins.entries.<id>.enabled = true` or an allowlist entry.
- Local proof gate: evaluate generated config and confirm the Nix-built plugin root appears in `plugins.load.paths`.
```

The better version ties each claim to source evidence or a proof gate.

## Failure Mode: Broad Research Prompt With No Load-Bearing Details

Bad fragment:

```markdown
Research the best architecture for remote multi-agent development. Cover networking, credentials, worktrees, and handoff.
```

Why it failed:

- It names domains but not decisions.
- It gives the researcher permission to return generic architecture advice.
- It omits the concrete artifacts that would make the result implementable.

Better fragment:

```markdown
The design needs to answer:

- what receipt proves an agent session can be resumed or recreated;
- who owns a worktree and when it can be deleted;
- where private state lives relative to repo state;
- how package environments are selected without mutating global tools;
- which credentials can cross the remote boundary;
- how the transport stack fails and recovers;
- what kill criteria stop the design from becoming permanent infrastructure.
```

The better version still leaves room for the researcher to think. It just names the facts that must become concrete.

## Good Example Shape

One runtime-plugin RFC became readable only after it stopped arguing for a preferred implementation and started with the model:

```markdown
Executive Model -> Decision -> Problem -> Goals and Non-Goals -> What the upstream system already supports -> Why not imitate the mutable lifecycle? -> User-facing model -> Version policy -> Builder -> Implementation -> When upstream changes become worth it -> What would falsify this design? -> Supported first slice -> Proof gates -> Evidence
```

That sequence is not a universal template. It is a useful example of a design that had to separate lifecycle ownership, upstream capability, Nix reproducibility, and supply-chain risk before implementation details could make sense.

## Good RFC Smell

A strong RFC usually has these properties:

- the decision can be stated in one paragraph without hiding deferred work;
- the user-facing API is smaller than the implementation explanation;
- alternatives are rejected because of named invariants, not author preference;
- versioning, mutability, rollback, and trust boundaries are explicit when they matter;
- proof gates can falsify the design before the implementation is large.

If the draft needs repeated verbal explanation to make sense, it is probably not decision-grade yet.
