#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"
qs_ensure_cache "workspaces"

for pid in $(pgrep -f "workspaces.sh"); do
    if [ "$pid" != "$$" ] && [ "$pid" != "$PPID" ]; then
        kill -9 "$pid" 2>/dev/null
    fi
done

cleanup() {
    pkill -P $$ 2>/dev/null
}
trap cleanup EXIT SIGTERM SIGINT

BT_PID_FILE="$QS_RUN_WORKSPACES/bt_scan_pid"

if [ -f "$BT_PID_FILE" ]; then
    kill $(cat "$BT_PID_FILE") 2>/dev/null
    rm -f "$BT_PID_FILE"
fi

(timeout 2 bluetoothctl scan off > /dev/null 2>&1) &

SEQ_END=9

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_workspaces() {
    tags_json=$("$SCRIPT_DIR/mango/tags.sh" list 2>/dev/null) || return
    active_tag=$(echo "$tags_json" | jq -r '.tags[] | select(.active == true) | .id' | head -1)
    active_tag=${active_tag:-1}

    echo "$tags_json" | jq --unbuffered --argjson a "$active_tag" --arg end "$SEQ_END" -c '
        (map( { (.id|tostring): . } ) | add) as $s
        |
        [range(1; ($end|tonumber) + 1)] | map(
            . as $i |
            ($i|tostring) as $sid |
            {
                id: $i,
                active: ($i == $a),
                windows: (($s[$sid].clients // []) | length)
            }
        )
    ' > "$QS_STATE_WORKSPACES/workspaces.json.tmp"
    mv "$QS_STATE_WORKSPACES/workspaces.json.tmp" "$QS_STATE_WORKSPACES/workspaces.json"
}

print_workspaces

while true; do
    sleep 2
    print_workspaces
done
