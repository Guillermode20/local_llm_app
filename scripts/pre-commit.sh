#!/usr/bin/env bash
# Pre-commit hook for Local LLM App
#
# Installed by running:
#   ln -sf ../../scripts/pre-commit.sh .git/hooks/pre-commit
#
# Runs formatting and static analysis on staged Dart files.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "=== Running Dart Format ==="
# Get staged Dart files
staged_files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.dart$' || true)

if [ -n "$staged_files" ]; then
  if ! dart format --set-exit-if-changed $staged_files; then
    echo -e "${RED}Formatting issues found. Run 'dart format .' and stage changes.${NC}"
    exit 1
  fi
  echo -e "${GREEN}Formatting OK${NC}"
else
  echo "No staged Dart files to check."
fi

echo "=== Running Flutter Analyze on staged changes ==="
# Only analyze if Dart files changed
if [ -n "$staged_files" ]; then
  if ! flutter analyze --no-fatal-infos --no-fatal-warnings; then
    echo -e "${RED}Analysis found issues.${NC}"
    exit 1
  fi
  echo -e "${GREEN}Analysis OK${NC}"
fi

echo -e "${GREEN}All pre-commit checks passed.${NC}"
