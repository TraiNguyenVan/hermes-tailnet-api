# hermes-tailnet-api

An agent skill + dependency-free CLI that lets a coding agent (Claude Code,
Codex, OpenCode, Cursor, Aider, …) drive a **remote Hermes agent** over a private
network: run tasks, and let that host use its own terminal, file, browser, web,
and delegation tools.

Every call is a full agent turn executed server-side. It is not a model proxy.

## Install

```bash
npx skills add TraiNguyenVan/hermes-tailnet-api -g -a '*' -y
~/.agents/skills/hermes-tailnet-api/scripts/setup.sh
```

or without node:

```bash
curl -fsSL https://raw.githubusercontent.com/TraiNguyenVan/hermes-tailnet-api/v1.0.5/install.sh | sh
```

`setup.sh` prompts for the server URL and the API key, writes
`~/.config/hermes/api.env` at `600`, and refuses to finish until
`hermes-api models` answers.

## Use

```bash
hermes-api ask "restart the postgres container"
hermes-api run "audit open ports"      # prints run_id
hermes-api wait <run_id>
hermes-api events <run_id>
hermes-api steer <run_id> "skip the DNS check"
```

## Upgrade

```bash
npx skills update hermes-tailnet-api -g -y       # skills.sh installs (name it explicitly)
./install.sh                                     # bootstrap installs (idempotent)
hermes-api version                               # confirm CLI version + base
```

## What it needs

- `python3` (stdlib only — no pip installs)
- Network reachability to the Hermes API server (typically a tailnet address)
- An API key that the server's operator issues to you (`API_SERVER_KEY`)

## Security notes

- No credentials are stored in this repo; `setup.sh` writes them to
  `~/.config/hermes/api.env` with mode `600` on your machine only.
- The remote agent runs with the permissions of the Hermes host. Ask its operator
  what it may touch before delegating destructive work.
- Read `scripts/hermes-api` before running it — it is ~250 lines of stdlib
  `urllib`, no dependencies, no telemetry.

## Contents

| Path | Purpose |
|---|---|
| `SKILL.md` | skill body the agent loads |
| `scripts/hermes-api` | the CLI |
| `scripts/setup.sh` | link CLI + write credentials + verify |
| `install.sh` | bootstrap installer (pipe-friendly) |
| `references/api.md` | endpoint cheat sheet |

MIT licensed.
