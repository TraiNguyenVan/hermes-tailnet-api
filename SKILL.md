---
name: hermes-tailnet-api
description: "Use when you must run work on a remote Hermes agent host: shell, files, browser."
version: 1.2.0
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
hermes-api health         # server health + readiness checks
hermes-api capabilities   # discover available features & route table
hermes-api tools          # see available tools on remote host (terminal, browser, etc.)
hermes-api sessions       # list active conversation sessions
hermes-api models         # must print {"object": "list", ...}
```

## Verbs

| Command | Use |
|---|---|
| `hermes-api ask "do X"` | synchronous, prints the answer (short replies) |
| `hermes-api ask --stream "do X"` | stream tokens live to stdout |
| `hermes-api run "do X"` | async, prints a `run_id` immediately |
| `hermes-api wait RUN_ID` | poll until finished, print output with elapsed time |
| `hermes-api get RUN_ID` | one status snapshot (JSON) |
| `hermes-api events RUN_ID` | stream live tool-progress SSE |
| `hermes-api steer RUN_ID "change course"` | inject guidance at the next tool boundary |
| `hermes-api approve RUN_ID [allow\|deny]` | resolve pending tool approval prompt |
| `hermes-api stop RUN_ID` | interrupt the run |
| `hermes-api runs` | discover active/recent runs (capability gated) |
| `hermes-api sessions` | list active conversation sessions |
| `hermes-api capabilities` | inspect server feature flags & route list |
| `hermes-api tools` | list enabled/disabled tools on remote agent |
| `hermes-api health` | check server and platform readiness |
| `hermes-api models` / `version` | connectivity+auth check / config check |

Flags on `ask`/`run`/`wait`:
- `-f, --file PATH`: attach a text, code, or diff file (pre-validated, max 25MB).
- `-i, --image PATH`: attach an image file (pre-validated, max 20MB, auto data URL).
- `--extract-media [DIR]`: auto-save returned image artifacts to local files.
- `--stop-on-interrupt`: in `wait`, automatically stop the remote run on Ctrl-C.
- `--session <id>`: continue an existing session conversation.
- `--model <id>`: use a specific model route.
- `--profile <name>`: route to another gateway profile.
- `-`: read prompt / patch from standard input.

## Examples

```bash
# Pipe code or diff directly from git
git diff | hermes-api ask - "review this diff for race conditions"

# Attach files to review or process
hermes-api ask -f main.py -f config.py "spot configuration bugs"

# Attach an image for multimodal vision analysis
hermes-api ask -i diagram.png "explain architecture in this diagram"

# Asynchronous run with media artifact extraction & resilient wait
RUN_ID=$(hermes-api run -f test.log "analyze crash and plot memory profile")
hermes-api wait $RUN_ID --extract-media ./artifacts --stop-on-interrupt

# Discover active sessions
hermes-api sessions
```

## Working rules

- **Shell tool timeouts are ~2 minutes.** Use `run` then `wait`; the run survives
  server-side, so re-`wait` the same id instead of re-running it.
- **Ctrl-C in `wait` interrupts the local polling only.** The remote run continues
  on the server unless `--stop-on-interrupt` is passed. Re-attach with `wait` or
  cancel with `stop`.
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
