#!/usr/bin/env bash
# Reflect Claude Code status in the tmux window title: an emoji for state plus a
# short label naming what the pane is for. Invoked from Claude Code hooks.
#
#   working  (UserPromptSubmit) -> "⏳ <label>"
#   waiting  (Notification)     -> "🟡 <label>"
#   done     (Stop)             -> "🟢 <label>"
#
# The label is PINNED to the session's first meaningful prompt and then frozen, so
# the title keeps telling you what the pane is about; only the emoji tracks state.
# The cache is keyed by Claude session_id, so reusing a tmux window for a new
# session gets a fresh label instead of inheriting the old one.
#
# Label engine:
#   pin      -> a fast in-shell heuristic pins an instant label on the first prompt
#              (no subprocess, no cost), so a title shows immediately.
#   refine   -> a model then refines that label once, in the background. Default is
#              the local ollama HTTP API (qwen2.5:0.5b) with a few-shot prompt at
#              temperature 0, so output is clean and deterministic; a validation
#              backstop drops chatty/echoed output. Override the model with
#              CLAUDE_TITLE_MODEL, or the whole engine with CLAUDE_TITLE_CMD (any
#              command: prompt on stdin -> label on stdout). Refinement never blocks
#              the prompt; if it fails or is rejected, the heuristic label stands.
#
# No-ops when not in tmux. Writes nothing to stdout (UserPromptSubmit stdout is
# injected into the prompt, so the script must stay silent there).

set -uo pipefail

# Recursion / nested-session guard: if CLAUDE_TITLE_CMD is overridden to a `claude`
# command, that headless session inherits CLAUDE_TITLE_GEN=1 and its hooks no-op.
# The default ollama engine doesn't fire Claude hooks, so this is just insurance.
[ -n "${CLAUDE_TITLE_GEN:-}" ] && exit 0

[ -n "${TMUX:-}" ] || exit 0          # only meaningful inside tmux
pane="${TMUX_PANE:-}"
[ -n "$pane" ] || exit 0

mode="${1:-working}"

# Every hook payload arrives as JSON on stdin; read it once.
input=$(cat 2>/dev/null || true)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)

wid=$(tmux display-message -t "$pane" -p '#{window_id}' 2>/dev/null) || exit 0
# Pin the label per Claude session (fall back to window id if session_id is absent).
key="${sid:-$wid}"
cache="${TMPDIR:-/tmp}/claude-title-${key//[^A-Za-z0-9]/}"

rename() { tmux rename-window -t "$pane" "$1" 2>/dev/null || true; }

# Cheap, dependency-free label: lowercase, strip punctuation, drop filler/command
# words, keep the first few content words. Good enough to tell tabs apart.
heuristic_label() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c '[:alnum:] ' ' ' \
    | tr ' ' '\n' \
    | grep -vxE '(the|a|an|to|of|in|on|at|for|and|or|with|please|can|could|would|should|you|i|me|my|we|our|this|that|these|those|is|are|be|it|its|so|but|then|also|just|now|get|got|set|need|want|do|does|did|use|using|add|make|made|create|update|fix|change|let|s|run|new|some|any|all|into|from|as|by|when|how|why|continue|proceed|yes|yep|yeah|ok|okay|sure|thanks|thank|hi|hey|hello|yo)' \
    | grep -vxE '.{0,1}' \
    | head -3 \
    | tr '\n' ' ' \
    | sed 's/[[:space:]]*$//' \
    | cut -c1-30
}

# Normalize raw model output into a label: lowercase, _/- to spaces, drop other
# punctuation, collapse whitespace, keep the first 4 words, cap at 30 chars.
sanitize_label() {
  tr '\n' ' ' | tr '_-' '  ' | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^[:alnum:] ]/ /g; s/[[:space:]]\{1,\}/ /g; s/^ //; s/ $//' \
    | cut -d' ' -f1-4 | cut -c1-30 | sed 's/ *$//'
}

# Few-shot prompt: a 0.5b model follows examples far better than a bare instruction.
# These example labels are also the echo denylist in valid_label below; keep in sync.
title_prompt() {
  cat <<PROMPT
You label coding tasks for a tmux tab. Output ONLY the label: 2 to 4 lowercase words, no punctuation, no greeting, no explanation.

Task: fix the auth redirect loop on login
Label: fix auth redirect

Task: add pagination to the users api endpoint
Label: users api pagination

Task: set ollama as the default tmux pane title generator
Label: ollama tmux titles

Task: $1
Label:
PROMPT
}

# Backstop: reject output that's a verbatim few-shot echo or opens like chat/meta
# text. On rejection the model result is dropped and the pinned heuristic stands.
valid_label() {
  local s="$1"
  [ -n "$s" ] || return 1
  # Single run-on token with no word boundary and >15 chars = junk (e.g. the model
  # dropping separators). Real one-word labels (polars, d152, duckdb) are short.
  case "$s" in
    *" "*) : ;;
    *) [ "${#s}" -gt 15 ] && return 1 ;;
  esac
  case "$s" in
    "fix auth redirect"|"users api pagination"|"ollama tmux titles") return 1 ;;
    hello*|hi\ *|hey*|sure*|certainly*|ok|ok\ *|okay*|yes*|yeah*|of\ course*|here*|sorry*|greetings*|well\ *|as\ an*|i\ *|im\ *|the\ label*|label*|task*|your\ *|assistant*) return 1 ;;
  esac
  return 0
}

# Background, one-time model refinement of a freshly pinned label. Default engine is
# the local ollama HTTP API at temperature 0 (deterministic, no chatty output);
# override with CLAUDE_TITLE_CMD (any command: prompt on stdin -> label on stdout)
# and/or CLAUDE_TITLE_MODEL. Failure (daemon down, garbage) leaves the heuristic.
refine_label() {
  local prompt="$1"
  [ -n "$prompt" ] || return 0
  local model="${CLAUDE_TITLE_MODEL:-qwen2.5:0.5b}"
  (
    # CLAUDE_TITLE_GEN guards against recursion if CLAUDE_TITLE_CMD is a `claude`
    # command; harmless for the API path, which doesn't fire Claude hooks anyway.
    export CLAUDE_TITLE_GEN=1
    local task full raw smart
    task=$(printf '%s' "$prompt" | head -c 2000)
    full=$(title_prompt "$task")
    if [ -n "${CLAUDE_TITLE_CMD:-}" ]; then
      raw=$(printf '%s' "$full" | $CLAUDE_TITLE_CMD 2>/dev/null)
    else
      raw=$(jq -nc --arg m "$model" --arg p "$full" \
              '{model:$m,prompt:$p,stream:false,options:{temperature:0,num_predict:12,seed:42}}' \
            | curl -s --max-time 10 http://localhost:11434/api/generate -d @- 2>/dev/null \
            | jq -r '.response // empty' 2>/dev/null)
    fi
    smart=$(printf '%s' "$raw" | sanitize_label)
    valid_label "$smart" || smart=""
    if [ -n "$smart" ]; then
      printf '%s' "$smart" >"$cache"
      tmux rename-window -t "$pane" "⏳ $smart" 2>/dev/null || true
    fi
  ) >/dev/null 2>&1 &
}

case "$mode" in
  working)
    prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)

    # Stop tmux auto-renaming on the next shell prompt, then set the title now.
    tmux set-window-option -t "$pane" automatic-rename off 2>/dev/null || true

    pinned=$(cat "$cache" 2>/dev/null || echo "")
    if [ -n "$pinned" ]; then
      # Label already chosen for this session: keep it, just show the working state.
      rename "⏳ $pinned"
    else
      # First meaningful prompt of the session: derive the label and pin it.
      label=""
      [ -n "$prompt" ] && label=$(heuristic_label "$prompt")
      if [ -n "$label" ]; then
        printf '%s' "$label" >"$cache"
        rename "⏳ $label"
        refine_label "$prompt"
      else
        # Filler opener (e.g. "continue"): stay unpinned, retry on the next prompt.
        rename "⏳ working"
      fi
    fi
    ;;
  waiting)
    label=$(cat "$cache" 2>/dev/null || echo "waiting")
    rename "🟡 $label"
    ;;
  done)
    label=$(cat "$cache" 2>/dev/null || echo "done")
    rename "🟢 $label"
    ;;
esac

exit 0
