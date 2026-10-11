#!/bin/sh
# Link every skill in this repo into ~/.agents/skills (read by Codex and other agents) and
# ~/.claude/skills (Claude Code). Re-running is safe; existing non-link entries are left alone.
set -eu
repo=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$HOME/.agents/skills" "$HOME/.claude/skills"
for dir in "$repo"/skills/*/; do
  name=$(basename "$dir")
  for target in "$HOME/.agents/skills/$name:$repo/skills/$name" "$HOME/.claude/skills/$name:../../.agents/skills/$name"; do
    link=${target%%:*} src=${target#*:}
    if [ -e "$link" ] && [ ! -L "$link" ]; then
      echo "skip $link: exists and is not a symlink" >&2
      continue
    fi
    ln -sfn "$src" "$link"
    echo "linked $link -> $src"
  done
done
echo
echo "Add snippets/global-instructions.md to ~/.claude/CLAUDE.md and ~/.codex/AGENTS.md."
