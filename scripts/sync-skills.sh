#!/usr/bin/env bash
# Sync project Agent Skills: .cursor/skills is the source of truth → .claude/skills, .agents/skills
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ROOT}/.cursor/skills"
if [[ ! -d "$SRC" ]]; then
  echo "error: missing ${SRC}" >&2
  exit 1
fi
for DST in "${ROOT}/.claude/skills" "${ROOT}/.agents/skills"; do
  mkdir -p "$DST"
  rsync -a --delete "${SRC}/" "${DST}/"
  echo "Synced ${SRC} -> ${DST}"
done
