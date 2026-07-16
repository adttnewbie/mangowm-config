#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

systemctl --user stop graphical-session.target
systemctl --user stop graphical-session-pre.target

sleep 0.5

"$SCRIPT_DIR/mango/ipc.sh" quit
