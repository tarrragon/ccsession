# Codex Notes

## Current Documentation Task

- Goal: turn the Go WebSocket server under `server/` into teaching material.
- Target blog content directory: `/Users/mac-eric/project/blog/content`.
- New series directories:
  - `go`
  - `go-advanced`
- Reference series:
  - `/Users/mac-eric/project/blog/content/python`
  - `/Users/mac-eric/project/blog/content/python-advanced`

## Writing Standard

Use `.claude/skills/compositional-writing/SKILL.md` as the writing standard.

Key rules for the Go teaching material:

- Atomize each article around one concept.
- Make intent explicit before implementation details.
- Keep headings and terms grep-friendly.
- For longer technical chapters, preserve the reasoning path:
  observation -> interpretation -> strategy -> execution.
- Put business logic before concrete code cases.

## Decision / Analysis Standard

Use `.claude/skills/wrap-decision/SKILL.md` for decision analysis.

User shorthand mapping:

- "分析" means use `wrap-decision`.
- "warp" means use `wrap-decision` (user shorthand; actual skill name is WRAP).
- "思考決策" means use `wrap-decision`.
- "做分析", "查資料再分析", "評估方案", "提案評估", "架構決策" also mean use `wrap-decision`.

Core WRAP flow:

1. Anchor Check: confirm customer, current goal, and whether the issue affects decision quality or development efficiency.
2. Step 0 Data Sufficiency Gate: check whether there is enough evidence, whether assumptions are replacing data, and whether missing data changes risk.
3. W - Widen Options: expand options before deciding; include current plan, alternatives, and zero-tool / documentation / existing-system options when relevant.
4. R - Reality Test: verify assumptions with source evidence, base rates, concrete cases, and source-by-source checks.
5. A - Attain Distance: expose opportunity cost, priority conflicts, and 10/10/10 consequences.
6. P - Prepare to Be Wrong: premortem, failure modes, safety margin, rollback plan, and tripwires.

Network research under WRAP:

- Prefer primary sources: official docs, project repositories, design docs, source code, release notes.
- For engineering examples, use mature Go projects when possible.
- Do not stop at one search. Use iterative research when the question affects architecture, teaching structure, or project direction.
- Iterative research structure:
  1. Divergent search: broad keywords across multiple related domains.
  2. Concrete search: specific project examples and real code layouts.
  3. Precise search: high-quality source details, docs, and exact terminology.
  4. Inverse search: criticism, counterexamples, limitations, and failure modes.
- Reality Test every list-like answer against sources; do not trust an unsourced generated list.
- After each research round, expose current bias and what evidence would change the conclusion.
- For final recommendations, state the preferred direction, why, what was rejected, and what risk/tripwire should be watched.

When analysis relates to Go teaching material:

- Use WRAP to prevent the curriculum from overfitting to this project.
- Widen examples beyond this repository by checking mature Go projects.
- Reality-test architecture claims against real Go codebases.
- Convert findings back into neutral teaching chapters, not project maintenance instructions.

## Source Material

The primary example source is the Go backend in `server/`:

- `main.go`: process startup, dependency wiring, HTTP routes, shutdown.
- `websocket_server.go`: WebSocket upgrade, client lifecycle, read/write pumps.
- `event_dispatcher.go`: channel fan-in, event deduplication, status updates.
- `session_registry.go`: concurrent state management with `sync.RWMutex`.
- `file_watcher.go`: filesystem watching and JSONL event ingestion.
- `hooks_handler.go`: HTTP JSON handler and non-blocking channel send.
- `*_test.go`: table tests, injected clocks, and concurrency-oriented verification.
