# Mango Compositor Service

This directory contains the Mango-owned compositor service implementation for
QuickShell.

## Boundaries

- `MangoService.qml` — action dispatcher; calls `scripts/mango/ipc.sh` only.
- `MangoState.qml` — state normalizer; exposes tags (1-9), monitors,
  activeClient, and keyboardLayout to the UI.
- No QML outside this directory invokes `mmsg` directly.

## Data flow

```
MangoWM  →  mmsg  →  scripts/mango/*.sh  →  MangoState.qml  →  UI widgets
UI widgets  →  MangoService.qml  →  scripts/mango/ipc.sh  →  mmsg  →  MangoWM
```
