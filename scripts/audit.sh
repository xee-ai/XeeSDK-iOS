#!/usr/bin/env bash
# Fails if "adapty" survives outside the allowed places. Run from anywhere.
set -uo pipefail
cd "$(dirname "$0")/.."
status=0

# 1. No Adapty host anywhere, fixtures included.
if grep -rIn "adapty\.io" Sources Sources.Logger Tests Package.swift; then
  echo "FAIL: an adapty.io host remains"
  status=1
fi

# 2. No other mention, in code or manifests. Allowed: the attribution line; the snake_case adapty_*
#    strings, which are wire values the server matches; and the backticked `adapty`, the value of the
#    `store` field that the server sends.
hits=$(grep -rIniE "adapty" \
    --include='*.swift' --include='*.h' --include='*.xcprivacy' --include='*.yaml' --include='*.cue' \
    Sources Sources.Logger Tests Package.swift \
  | grep -v "Derived from Adapty iOS SDK" \
  | sed -E 's/adapty_[a-z0-9_]+//g; s/`adapty`//g' \
  | grep -iE "adapty" || true)
if [ -n "$hits" ]; then
  echo "$hits" | head -30
  echo "FAIL: $(echo "$hits" | wc -l | tr -d ' ') lines still mention Adapty"
  status=1
fi

# 3. No file or directory name left over.
if find Sources Sources.Logger Tests -iname '*adapty*' | grep .; then
  echo "FAIL: a file name still says Adapty"
  status=1
fi

[ $status -eq 0 ] && echo "audit ok"
exit $status
