#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# new-paper.sh — start a new paper from this template
#
# Usage:
#   new-paper.sh <folder> ["Paper Title"] ["Short Title"]
#
# What it does:
#   1. Copies the template (committed files only) into <folder>
#   2. Fills in the title in _paper.yml and response.qmd
#   3. Fills in your author block (see "Author defaults" below)
#   4. Starts a fresh git repo with an initial commit
#   5. Opens the folder in VS Code
#
# Author defaults:
#   If ~/.config/quarto-paper/_authors.yml exists, it replaces the
#   template's _authors.yml. Otherwise your name and email are taken
#   from `git config user.name` / `git config user.email`.
#
# Template source:
#   By default, the git repo this script lives in. Set
#   QUARTO_PAPER_TEMPLATE to a path or URL to use another one, e.g.
#   QUARTO_PAPER_TEMPLATE=https://github.com/hhadah/my-quarto-paper-template.git
# ──────────────────────────────────────────────────────────────
set -euo pipefail

if [[ $# -lt 1 || "$1" == "-h" || "$1" == "--help" ]]; then
  sed -n '3,9p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

dest="$1"
title="${2:-}"
short_title="${3:-}"

# ── Locate the template ───────────────────────────────────────
script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
if [[ -n "${QUARTO_PAPER_TEMPLATE:-}" ]]; then
  template="$QUARTO_PAPER_TEMPLATE"
elif git -C "$script_dir" rev-parse --git-dir >/dev/null 2>&1; then
  template="$script_dir"
else
  template="https://github.com/hhadah/my-quarto-paper-template.git"
fi

if [[ -e "$dest" ]]; then
  echo "Error: '$dest' already exists." >&2
  exit 1
fi

# ── Ask for a title if none was given ─────────────────────────
if [[ -z "$title" && -t 0 ]]; then
  read -r -p "Paper title: " title
  read -r -p "Short title (running head, optional): " short_title
fi

# ── Copy the template ─────────────────────────────────────────
echo "Copying template from $template ..."
[[ -d "$template" ]] && template="file://$template"
git clone --quiet --depth 1 "$template" "$dest"
cd "$dest"
rm -rf .git new-paper.sh

# YAML-safe: escape backslashes and double quotes
yaml_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

if [[ -n "$title" ]]; then
  T="$(yaml_escape "$title")" perl -pi -e 's/Your Paper Title Here/$ENV{T}/' _paper.yml
  T="$(yaml_escape "$title")" perl -pi -e 's/Your Paper Title/$ENV{T}/' response.qmd
fi
if [[ -n "$short_title" ]]; then
  T="$(yaml_escape "$short_title")" perl -pi -e 's/"Short Title"/"$ENV{T}"/' _paper.yml
fi

# ── Author block ──────────────────────────────────────────────
authors_default="${XDG_CONFIG_HOME:-$HOME/.config}/quarto-paper/_authors.yml"
if [[ -f "$authors_default" ]]; then
  cp "$authors_default" _authors.yml
  echo "Authors: copied from $authors_default"
else
  name="$(git config user.name || true)"
  email="$(git config user.email || true)"
  [[ -n "$name" ]] && N="$(yaml_escape "$name")" perl -pi -e 's/^(  - name: )Your Name$/$1$ENV{N}/' _authors.yml
  [[ -n "$email" ]] && E="$email" perl -pi -e 's/your\.email\@university\.edu/$ENV{E}/' _authors.yml
  echo "Authors: filled name/email from git config (save a full block to $authors_default to reuse it)"
fi

# ── Fresh git repo ────────────────────────────────────────────
git init --quiet
git add -A
git commit --quiet -m "Start paper from quarto template"

echo "Created $(pwd)"

# ── Open in VS Code ───────────────────────────────────────────
if command -v code >/dev/null 2>&1; then
  code . _paper.yml
else
  echo "VS Code 'code' command not found; open the folder manually."
fi
