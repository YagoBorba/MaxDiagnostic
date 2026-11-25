#!/usr/bin/env bash
# Smoke test for the LibreSpeed server used by MaxDiagnostic.
#
# Starts the container with MAX_CONCURRENT_TESTS=2 and checks that:
#   - the speed test runner and LibreSpeed endpoints are served;
#   - slots are granted up to the limit, refused after it and released;
#   - concurrent reservations never exceed the limit.
#
# Usage: ./smoke-test.sh   (needs docker, curl and jq)
set -euo pipefail

cd "$(dirname "$0")"
BASE="http://localhost:7000"
LIMIT=2
export MAX_CONCURRENT_TESTS=$LIMIT

fail() { echo "FAIL: $*" >&2; docker compose logs --tail 50 >&2 || true; exit 1; }
status() { curl -s -o /dev/null -w '%{http_code}' "$@"; }

docker compose up -d
trap 'docker compose down -v >/dev/null 2>&1 || true' EXIT

for _ in $(seq 1 90); do
  [ "$(status "$BASE/api.php?action=check_capacity")" = "200" ] && break
  sleep 2
done

echo "== static files and LibreSpeed backend"
for path in /librespeed_runner.html /speedtest.js /speedtest_worker.js /backend/empty.php /backend/getIP.php "/backend/garbage.php?ckSize=1"; do
  code=$(status "$BASE$path")
  echo "$path -> $code"
  [ "$code" = "200" ] || fail "$path returned $code"
done

api() { curl -s -w '\n%{http_code}' "$@"; }
body() { sed '$d' <<<"$1"; }
code() { tail -n1 <<<"$1"; }

echo "== capacity flow (limit $LIMIT)"
r=$(api "$BASE/api.php?action=check_capacity")
[ "$(code "$r")" = "200" ] && [ "$(body "$r" | jq -r .status)" = "OK" ] || fail "check_capacity: $r"
[ "$(body "$r" | jq -r .max_concurrent_tests)" = "$LIMIT" ] || fail "MAX_CONCURRENT_TESTS did not reach PHP: $r"

tokens=()
for i in $(seq 1 "$LIMIT"); do
  r=$(api -X POST "$BASE/api.php?action=reserve_slot&clientId=smoke-$i")
  [ "$(code "$r")" = "200" ] && [ "$(body "$r" | jq -r .status)" = "GRANTED" ] || fail "reserve $i: $r"
  tokens+=("$(body "$r" | jq -r .token)")
done

r=$(api -X POST "$BASE/api.php?action=reserve_slot&clientId=smoke-extra")
[ "$(code "$r")" = "429" ] && [ "$(body "$r" | jq -r .status)" = "BUSY" ] || fail "reservation above the limit was not refused: $r"

r=$(api "$BASE/api.php?action=release_slot&token=${tokens[0]}")
[ "$(code "$r")" = "200" ] || fail "release: $r"

r=$(api -X POST "$BASE/api.php?action=reserve_slot&clientId=smoke-after-release")
[ "$(body "$r" | jq -r .status)" = "GRANTED" ] || fail "slot was not reusable after release: $r"
tokens[0]=$(body "$r" | jq -r .token)

for t in "${tokens[@]}"; do curl -s -o /dev/null "$BASE/api.php?action=release_slot&token=$t"; done

echo "== 20 concurrent reservations"
tmp=$(mktemp -d)
for i in $(seq 1 20); do
  curl -s -X POST "$BASE/api.php?action=reserve_slot&clientId=race-$i" -o "$tmp/$i.json" &
done
wait
granted=$(cat "$tmp"/*.json | jq -s '[.[] | select(.status == "GRANTED")] | length')
echo "granted: $granted"
[ "$granted" = "$LIMIT" ] || fail "expected exactly $LIMIT granted slots under concurrency, got $granted"

r=$(api "$BASE/api.php?action=unknown")
[ "$(code "$r")" = "400" ] || fail "unknown action should return 400: $r"

echo "OK: LibreSpeed server and capacity manager behave as expected"
