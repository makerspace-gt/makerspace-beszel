#!/usr/bin/env bash
# Pre-commit / pre-push guard: refuse any ansible-vault file that is not encrypted.
# This repo is public, so a decrypted vault must never be committed or pushed.
# detect-secrets does NOT reliably catch this (host addresses etc. match no pattern).
set -euo pipefail

status=0
for f in "$@"; do
  [ -f "$f" ] || continue
  if ! head -1 "$f" | grep -q '^\$ANSIBLE_VAULT'; then
    echo "ERROR: $f is NOT ansible-vault encrypted — refusing to commit/push."
    echo "       Encrypt it first:  ansible-vault encrypt $f"
    status=1
  fi
done
exit "$status"
