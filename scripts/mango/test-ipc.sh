#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FAKE_MMSG_DIR=$(mktemp -d)
trap 'rm -rf "$FAKE_MMSG_DIR"' EXIT

cat > "$FAKE_MMSG_DIR/mmsg" << 'EOF'
#!/usr/bin/env bash
echo "mmsg $@" >> "$FAKE_MMSG_LOG"
case "$1" in
  dispatch)
    shift
    echo "dispatch: $@"
    ;;
  get)
    shift
    case "$1" in
      tags)
        echo '{"tags": [{"id": 1, "active": true}, {"id": 2, "active": false}]}'
        ;;
      monitors)
        echo '{"monitors": [{"name": "eDP-1", "width": 1920, "height": 1080}]}'
        ;;
      keyboard)
        echo '{"layout": "us"}'
        ;;
    esac
    ;;
esac
EOF
chmod +x "$FAKE_MMSG_DIR/mmsg"

export PATH="$FAKE_MMSG_DIR:$PATH"
export FAKE_MMSG_LOG="$FAKE_MMSG_DIR/mmsg.log"

failures=0

assert_exit() {
  local label=$1 expected=$2
  shift 2
  local actual=0
  "$@" >/dev/null 2>&1 || actual=$?
  if [ "$actual" -ne "$expected" ]; then
    printf 'FAIL: %s: expected exit %d, got %d\n' "$label" "$expected" "$actual"
    failures=$((failures + 1))
  else
    printf 'PASS: %s\n' "$label"
  fi
}

assert_mmsg_called() {
  local label=$1 expected_pattern=$2
  if grep -q "$expected_pattern" "$FAKE_MMSG_LOG" 2>/dev/null; then
    printf 'PASS: %s\n' "$label"
  else
    printf 'FAIL: %s: mmsg not called with /%s/\n' "$label" "$expected_pattern"
    failures=$((failures + 1))
  fi
}

clear_log() {
  rm -f "$FAKE_MMSG_LOG"
}

assert_exit "view-tag 0 rejected" 64 "$SCRIPT_DIR/ipc.sh" view-tag 0
assert_exit "view-tag 10 rejected" 64 "$SCRIPT_DIR/ipc.sh" view-tag 10

clear_log
assert_exit "view-tag 1 succeeds" 0 "$SCRIPT_DIR/ipc.sh" view-tag 1
assert_mmsg_called "view-tag 1 calls mmsg dispatch view 1" "dispatch view 1"

clear_log
assert_exit "tags succeeds" 0 "$SCRIPT_DIR/ipc.sh" tags
assert_mmsg_called "tags calls mmsg get tags" "get tags"

if [ "$failures" -gt 0 ]; then
  printf '\n%d test(s) failed\n' "$failures"
  exit 1
fi

printf '\nAll IPC tests passed\n'
