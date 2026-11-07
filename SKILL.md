---
name: hermes-tailnet-api
description: "Use when you must run work on a remote Hermes agent host: shell, files, browser."
version: 1.0.6
author: TraiNguyenVan
license: MIT
platforms: [linux, darwin]
metadata:
  hermes:
    tags: [hermes, delegation, remote, api, tailnet]
---

# Drive a remote Hermes agent

`hermes-api` is a dependency-free CLI (python3 stdlib only) for a Hermes
gateway's API server. Each call runs a real agent **on the server host** with its
terminal, file, browser, web, and delegation tools.

It is an agent loop, not a model endpoint — never point a model `base_url` at it.

## First run

```bash
scripts/setup.sh          # prompts for server URL + API key, checks connectivity
hermes-api version        # CLI version + configured base
hermes-api models         # must print {"object": "list", ...}
```

## Verbs

| Command | Use |
|---|---|
| `hermes-api ask "do X"` | synchronous, prints the answer (short replies) |
| `hermes-api run "do X"` | async, prints a `run_id` immediately |
| `hermes-api wait RUN_ID` | poll until finished, print output |
| `hermes-api get RUN_ID` | one status snapshot (JSON) |
| `hermes-api events RUN_ID` | stream live tool-progress SSE |
| `hermes-api steer RUN_ID "change course"` | inject guidance at the next tool boundary |
| `hermes-api stop RUN_ID` | interrupt the run |
| `hermes-api models` / `version` | connectivity+auth check / config check |

Flags on `ask`/`run`: `--session <id>` (continue a conversation), `--model <id>`,
`--profile <name>` (route to another gateway profile).

## Working rules

- **Shell tool timeouts are ~2 minutes.** Use `run` then `wait`; the run survives
  server-side, so re-`wait` the same id instead of re-running it.
- Every run is a full agent turn (tens of thousands of prompt tokens). Do not
  loop it; batch the work into one instruction.
- `steer` only lands while the run is `running`; `409` means it already finished.
- The remote agent acts with its own permissions. State what it may touch.

## Triaging a failure

| Symptom | Cause |
|---|---|
| `cannot reach http://…` | wrong base URL, server down, or sandbox blocks network |
| `HTTP 401` | wrong/missing key in `~/.config/hermes/api.env` |
| `no server URL configured` | `scripts/setup.sh` not run, or `HERMES_API_BASE` unset |
| `HTTP 400 … Missing 'input' field` | empty prompt |
| `command not found: hermes-api` | setup did not link it, or `~/.local/bin` is not on `PATH` |
| `echo $HERMES_API_KEY` prints but calls 401 | variable not exported; the CLI reads the file, so `set -a; . ~/.config/hermes/api.env; set +a` also works |

Route reference and feature flags: `references/api.md`.
