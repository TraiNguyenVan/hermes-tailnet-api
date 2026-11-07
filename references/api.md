# Hermes API server — client cheat sheet

Everything below hangs off the base URL you configured (default shape
`http://<host>:<port>/v1`). Auth: `Authorization: Bearer <key>`.
Profiles multiplex under `/p/<profile>/v1`.

Discover the live truth before assuming: `GET /v1/capabilities` returns feature
flags plus a machine-readable route list, and `GET /v1/toolsets` says which tools
the server actually has enabled.

## Routes

| Method | Path | Notes |
|---|---|---|
| GET | `/health`, `/health/detailed` | liveness, readiness checks |
| GET | `/v1/models` | usually one entry, `hermes-agent` |
| GET | `/v1/capabilities` | feature flags + every route |
| GET | `/v1/toolsets` | enabled/disabled toolsets for API runs |
| GET | `/v1/skills` | installed skills (may be unimplemented on older builds) |
| POST | `/v1/chat/completions` | OpenAI shape, `messages` required, SSE if `stream` |
| POST | `/v1/responses` | OpenAI Responses shape |
| POST | `/v1/runs` | `{"input": "..."}` → run_id (202) |
| GET | `/v1/runs/{id}` | status snapshot |
| GET | `/v1/runs/{id}/events` | SSE, `: keepalive` every 10s |
| POST | `/v1/runs/{id}/steer` | only while `running`, else 409 |
| POST | `/v1/runs/{id}/approval` | resolve a pending approval |
| POST | `/v1/runs/{id}/resolve-unknown` | acknowledge a restart-unknown run |
| POST | `/v1/runs/{id}/stop` | cooperative interrupt |
| GET/POST | `/api/sessions`, `/api/sessions/{id}`, `/…/messages`, `/…/fork`, `/…/chat`, `/…/chat/stream`, `/…/model` | session resources |

Session continuity: `X-Hermes-Session-Id` and `X-Hermes-Session-Key` headers.
Run submission is idempotent when you send an idempotency key.

## Limits worth knowing

- Runs are profile-scoped: another profile's run id returns 404, not 403.
- Concurrency is capped server-side (commonly 10 simultaneous runs).
- Feature flags for audio, realtime voice, admin config writes, memory writes,
  and CORS are usually `false`. Check `/v1/capabilities` rather than guessing.
