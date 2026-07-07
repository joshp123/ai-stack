---
written_by: ai
---

# Models

Use this when choosing a model or calling a model outside the current harness.
Model choice is per task, never per session.

## Harnesses

- Use the current harness for its native model. In Codex, use the Codex model
  through Codex. In Claude Code, use Claude through Claude Code.
- Use Pi for agent-driven calls to other providers, especially Anthropic and
  Ollama checks from a shell.
- Use Ollama through Pi for Ollama cloud models unless Josh explicitly asks for
  direct Ollama.
- Do not run local Ollama models unless Josh explicitly asks and confirms local
  resource use. Local models use this machine's CPU/GPU/RAM and can make the
  system slow.

## Pi mechanics

List what Pi can currently use before choosing:

```sh
pi --list-models
pi --list-models ollama
```

Use no tools and no saved session for smoke tests, classification probes and
model comparisons:

```sh
pi --model anthropic/<model-from-pi-list> --thinking xhigh --no-tools --no-session -p 'Reply with exactly: opus-ok'
pi --model ollama/<model-from-pi-list> --no-tools --no-session -p 'Reply with exactly: ollama-ok'
```

Do not carry a whole agent toolset or complicated system prompt into a simple
classification or model check. With Anthropic through Pi, bad tool and system
prompt combinations can change routing or usage behaviour. Keep the prompt
small, name the model explicitly and turn tools off unless the task needs them.

Pi auth is separate from Claude Code auth. Claude Code can be logged in while Pi
still fails. Pi stores credentials under `~/.pi/agent/auth.json`; OAuth refreshes
can mutate it. If Pi reports missing Anthropic auth, fix Pi auth or the
Nix-managed Pi secret. Do not copy Claude Code tokens.

If manual repair is genuinely needed, start interactive Pi and run `/login`,
then select the provider. Treat this as a repair path, not the normal workflow.

## Ollama

Ollama can run local models and cloud models behind similar APIs:

- local API: `http://localhost:11434`
- Ollama cloud API: `https://ollama.com`
- OpenAI-compatible API: `/v1`
- Anthropic-compatible API exists for tools that expect Anthropic

In Pi, `ollama/<name>:cloud` means the configured Ollama provider is using a
cloud model. It does not mean the model is running locally.

Ollama adds and changes cloud models often. Always check the live catalogue
before choosing:

- `pi --list-models ollama`
- `ollama.com/search?c=cloud`
- `docs.ollama.com/api/introduction`
- `docs.ollama.com/api/openai-compatibility`
- `docs.ollama.com/api/anthropic-compatibility`

As of 6 July 2026, the live Ollama cloud catalogue includes these families and
labs. Treat this as an inventory starting point, not a stable ranking:

| family | lab/provider | use as |
|---|---|---|
| Qwen | Alibaba | open text, coding, vision and OCR candidates |
| DeepSeek | DeepSeek | open reasoning and coding candidates |
| Kimi | Moonshot AI | long-context and coding candidates |
| GLM | Z.ai/Zhipu | reasoning and agentic engineering candidates |
| MiniMax | MiniMax | coding and agentic workflow candidates |
| Gemma/Gemini | Google | vision, OCR and general candidates |
| Nemotron | NVIDIA | agentic and efficiency candidates |
| Devstral/Mistral | Mistral | coding candidates |
| gpt-oss | OpenAI | cautionary old/bad candidate, useful as a negative example |

Ollama benchmarks are weak hints. Our task samples often disagree with public
benchmarks and with the model card story. Use benchmarks to pick candidates;
use raw task samples to pick winners.

## Picking models

Use the strongest cheap model that honestly fits the task:

- general engineering: use the Codex harness by default
- human-driven Claude work: use Claude Code
- agent-driven Claude or model checks: use Pi
- bulk classification and extraction: survey the latest cheap/open candidates,
  run a raw-graded sample, then scale
- taste-heavy product, output, API, copy and hard review: use the best taste
  model available; do not waste it on mechanical work

For bulk classification and extraction, do not pick from whatever happens to be
installed. Survey the latest Qwen, DeepSeek, Kimi, GLM/Zhipu, MiniMax, Gemma and
peer models by release date. Re-survey often; model quality changes in weeks.

`gpt-oss` is the cautionary example: do not use it just because it is present in
a catalogue. If an old or weak model appears in a list, verify it against the
actual task before spending more time on it.

## Grounding

Read both sides of every model call raw:

- the source after selection, truncation and formatting
- the exact prompt or request sent to the model
- the returned artifact against the source

Run a small sample before a heavy run. If the first unit is empty, truncated,
misrouted or hollow, stop and fix the pipeline before scaling.
