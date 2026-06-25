#!/bin/bash
# Claude Code status line

input=$(cat) || input=""

# Extract fields
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "?"' 2>/dev/null) || cwd="?"
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "?"' 2>/dev/null) || model="?"
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null) || used_pct=""
session_id=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null) || session_id=""

# Extract token usage fields
# Use cumulative session totals for in/out (reliably non-null after first message)
tok_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty' 2>/dev/null) || tok_in=""
tok_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty' 2>/dev/null) || tok_out=""
# Cache figures come from current_usage (no session-level cache total in schema)
tok_cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // empty' 2>/dev/null) || tok_cache_read=""
tok_cache_write=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // empty' 2>/dev/null) || tok_cache_write=""

# Colors (ANSI, will be dimmed by Claude Code)
reset="\e[0m"
green="\e[38;5;64m"
violet="\e[38;5;61m"
white="\e[38;5;245m"
yellow="\e[38;5;136m"
cyan="\e[38;5;37m"
red="\e[38;5;124m"
blue="\e[38;5;67m"
pink="\e[38;5;218m"

# Session clock
session_clock=""
if [ -n "$session_id" ]; then
  session_dir="${HOME}/.claude/session-times"
  mkdir -p "$session_dir"
  session_file="${session_dir}/${session_id}"
  if [ ! -f "$session_file" ]; then
    date +%s > "$session_file"
  fi
  start_time=$(cat "$session_file" 2>/dev/null) || start_time=""
  if [ -n "$start_time" ]; then
    now=$(date +%s)
    elapsed=$(( now - start_time ))
    elapsed_min=$(( elapsed / 60 ))
    elapsed_hr=$(( elapsed_min / 60 ))
    remaining_min=$(( elapsed_min % 60 ))
    if [ "$elapsed_hr" -ge 1 ]; then
      session_clock="${elapsed_hr}h ${remaining_min}m"
    else
      session_clock="${elapsed_min}m"
    fi
  fi
fi

# Git branch + status (skip optional locks to avoid contention)
git_part=""
if git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null; then
  branch=$(git -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null \
    || git -C "$cwd" rev-parse --short HEAD 2>/dev/null \
    || echo "(unknown)")
  s=""
  git -C "$cwd" diff --quiet --ignore-submodules --cached 2>/dev/null || s="${s}+"
  git -C "$cwd" diff-files --quiet --ignore-submodules -- 2>/dev/null || s="${s}!"
  if [ -n "$(git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null)" ]; then s="${s}?"; fi
  git -C "$cwd" rev-parse --verify refs/stash &>/dev/null && s="${s}\$"
  [ -n "$s" ] && s=" [${s}]"
  git_part=" $(printf "${white}${violet}\ue725 ${branch}${white}${s}")"
fi

# Context progress bar
ctx_part=""
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  bar_width=10
  filled=$(( used_int * bar_width / 100 ))
  empty=$(( bar_width - filled ))
  bar=""
  i=0
  while [ $i -lt $filled ]; do bar="${bar}█"; i=$(( i + 1 )); done
  i=0
  while [ $i -lt $empty ]; do bar="${bar}░"; i=$(( i + 1 )); done

  if [ "$used_int" -ge 80 ]; then
    bar_color="$red"
  elif [ "$used_int" -ge 50 ]; then
    bar_color="$yellow"
  else
    bar_color="$green"
  fi

  ctx_part=" $(printf "${white}ctx ${bar_color}${bar}${white} ${used_int}%%")"
fi

# Session clock part
clock_part=""
if [ -n "$session_clock" ]; then
  clock_part=" $(printf "${white}| ${pink}\u23f1 ${pink}${session_clock}")"
fi

# Token counts part
# Helper: format a raw token integer as a compact string (e.g. 1200 -> "1.2k", 850 -> "0.9k")
fmt_tok() {
  local n=$1
  if [ -z "$n" ] || [ "$n" -eq 0 ] 2>/dev/null; then
    echo "0"
  elif [ "$n" -ge 1000 ]; then
    # Use awk for floating-point formatting
    awk -v v="$n" 'BEGIN { printf "%.1fk", v/1000 }'
  else
    echo "$n"
  fi
}

tok_part=""
if [ -n "$tok_in" ] || [ -n "$tok_out" ]; then
  in_fmt=$(fmt_tok "${tok_in:-0}")
  out_fmt=$(fmt_tok "${tok_out:-0}")
  tok_str="${blue}↓${in_fmt} ↑${out_fmt}"
  # Combine cache read + write into a single cache figure
  if [ -n "$tok_cache_read" ] || [ -n "$tok_cache_write" ]; then
    cache_total=$(( ${tok_cache_read:-0} + ${tok_cache_write:-0} ))
    cache_fmt=$(fmt_tok "$cache_total")
    tok_str="${tok_str} ${yellow}⚡${cache_fmt}"
  fi
  tok_part=" $(printf "${white}| ${tok_str}")"
fi

printf "%b\n" "${git_part} ${white}| ${cyan}${model}${ctx_part}${tok_part}${clock_part}${reset}"
exit 0
