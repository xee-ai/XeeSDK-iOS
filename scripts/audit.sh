#!/usr/bin/env bash
# Fails if "adapty" appears anywhere but LICENSE (the upstream MIT notice, which must stay) and the
# "Migrate from Adapty" doc samples. Run from anywhere.
set -uo pipefail
cd "$(dirname "$0")/.."
status=0

hits=$(grep -rIni "adapty" --exclude-dir=.build --exclude-dir=.git --exclude=LICENSE \
    --exclude=MigrateToXee.swift --exclude=audit.sh . || true)
if [ -n "$hits" ]; then
  echo "$hits" | cut -c1-200 | head -30
  echo "FAIL: $(echo "$hits" | wc -l | tr -d ' ') lines still mention Adapty"
  status=1
fi

if find . -path ./.build -prune -o -iname '*adapty*' -print | grep .; then
  echo "FAIL: a file name still says Adapty"
  status=1
fi

[ $status -eq 0 ] && echo "audit ok"
exit $status
