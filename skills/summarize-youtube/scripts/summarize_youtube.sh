#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: summarize_youtube.sh <youtube-url> [options]

Options:
  --cli <provider>     claude (default), codex, gemini
  --length <preset>    short|medium|long|xl|xxl (default: xxl)
  --model <id>         whisper.cpp model id (default: medium.en)
  --timeout <duration> summarize timeout (default: 10m)
  --retries <count>    summarize retries (default: 2)
  --extract            transcript only (no LLM summary)
  -h, --help           show this help

Examples:
  summarize_youtube.sh "https://www.youtube.com/watch?v=..."
  summarize_youtube.sh "https://youtu.be/..." --length xl --cli claude
  summarize_youtube.sh "https://youtu.be/..." --extract > /tmp/transcript.txt
USAGE
}

url=""
cli="claude"
length="xxl"
model="medium.en"
timeout="10m"
retries="2"
extract="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cli)
      cli="$2"
      shift 2
      ;;
    --length)
      length="$2"
      shift 2
      ;;
    --model)
      model="$2"
      shift 2
      ;;
    --timeout)
      timeout="$2"
      shift 2
      ;;
    --retries)
      retries="$2"
      shift 2
      ;;
    --extract)
      extract="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      if [[ -z "$url" ]]; then
        url="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$url" ]]; then
  usage
  exit 1
fi

summarize_bin="${SUMMARIZE_BIN:-/opt/homebrew/bin/summarize}"
if [[ ! -x "$summarize_bin" ]]; then
  summarize_bin="$(command -v summarize || true)"
fi
if [[ -z "$summarize_bin" || ! -x "$summarize_bin" ]]; then
  echo "summarize not found. Install it or set SUMMARIZE_BIN." >&2
  exit 1
fi

model_dir="${SUMMARIZE_MODEL_DIR:-$HOME/.cache/whisper.cpp}"
model_path="${SUMMARIZE_MODEL_PATH:-${model_dir}/ggml-${model}.bin}"

export SUMMARIZE_BIN="$summarize_bin"
export SUMMARIZE_MODEL_DIR="$model_dir"
export SUMMARIZE_MODEL_PATH="$model_path"
export SUMMARIZE_MODEL_ID="$model"
export SUMMARIZE_URL="$url"
export SUMMARIZE_CLI="$cli"
export SUMMARIZE_LENGTH="$length"
export SUMMARIZE_TIMEOUT="$timeout"
export SUMMARIZE_RETRIES="$retries"
export SUMMARIZE_EXTRACT="$extract"

nix shell nixpkgs#yt-dlp nixpkgs#whisper-cpp --command bash -lc '
  set -euo pipefail
  whisper_bin="$(command -v whisper-cli)"
  ytdlp_bin="$(command -v yt-dlp)"

  model_path="$SUMMARIZE_MODEL_PATH"
  if [[ ! -f "$model_path" ]]; then
    echo "Missing whisper.cpp model: $model_path" >&2
    echo "Download:" >&2
    echo "  nix shell nixpkgs#whisper-cpp --command whisper-cpp-download-ggml-model $SUMMARIZE_MODEL_ID --output-dir \"$SUMMARIZE_MODEL_DIR\"" >&2
    exit 1
  fi

  export SUMMARIZE_WHISPER_CPP_BINARY="$whisper_bin"
  export SUMMARIZE_WHISPER_CPP_MODEL_PATH="$model_path"
  export YT_DLP_PATH="$ytdlp_bin"

  extra=()
  if [[ "$SUMMARIZE_EXTRACT" == "true" ]]; then
    extra+=(--extract)
  fi

  "$SUMMARIZE_BIN" "$SUMMARIZE_URL" \
    --video-mode transcript --youtube yt-dlp \
    --cli "$SUMMARIZE_CLI" --length "$SUMMARIZE_LENGTH" \
    --timeout "$SUMMARIZE_TIMEOUT" --retries "$SUMMARIZE_RETRIES" \
    "${extra[@]}"
'
