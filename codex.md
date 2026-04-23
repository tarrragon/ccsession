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

## Mandatory Writing Compliance

These rules are mandatory for every Codex session that writes, reviews, or edits teaching material, blog content, specs, proposals, or long-form technical documentation.

Before drafting or revising content:

1. Read `.claude/skills/compositional-writing/SKILL.md`.
2. For article-style material, also read `.claude/skills/compositional-writing/references/writing-articles.md`.
3. For general document style, also read `.claude/rules/core/document-writing-style.md`.
4. Apply the rules as active constraints, not as optional reference material.

High-priority writing requirements:

- Put the core principle or definition first. Examples, code, caveats, and boundaries must follow the principle.
- Use positive concept anchors before negative contrast. A paragraph about mistakes, anti-patterns, or boundaries must first state the correct responsibility model.
- Avoid pure negative framing such as "X is not Y" as the only explanation. If negative contrast is needed, pair it with a positive concept and the reason the substitute is insufficient.
- Treat summary tables as indexes, not as complete explanations. When a table introduces categories, add follow-up paragraphs that explain how to recognize each category, show realistic examples, and analyze why the distinction matters.
- Write for readers who may not yet recognize industry shorthand. Terms such as CRUD-heavy system, high-concurrency I/O, long-lived connection, dynamic runtime behavior, or frontend integration bottleneck need observable signals and examples before they become useful decision criteria.
- Prefer headings such as "Design Check" / "檢查" over "Common Mistakes" / "常見錯誤" when the section teaches a reusable concept.
- Do not let examples from `server/` become project maintenance instructions. Teaching material must stay neutral and usable for engineers working on other Go projects.

Verification before finishing writing work:

- Search the changed material for high-risk negative wording: `不是`, `不要`, `不應`, `不能`, `不可`, `不行`, `不可以`, `常見錯誤`, `錯誤一`.
- Search for project-specific leakage when writing public teaching material: `ccsession`, `Claude`, `JSONL`, `SessionRegistry`, `EventDispatcher`, `FileWatcher`, `Hook`.
- Review every match before finalizing. Some negative wording is valid when it is a direct definition, but paragraph openers, headings, and anti-pattern sections must preserve a positive concept anchor.

Post-generation review is mandatory:

- Treat the first generated draft as non-compliant until proven otherwise. Knowing the writing rules does not guarantee the generated content followed them.
- After every drafting or expansion pass, perform a second review against the writing rules before reporting completion.
- The second review must check at least these points:
  1. Does every table-introduced category have follow-up explanation, recognition signals, realistic examples, and analysis?
  2. Does every paragraph start with the core principle before examples or caveats?
  3. Does every negative contrast have a positive concept anchor?
  4. Does the article avoid reader-labeling language such as "new engineer" / "beginner" in the published text?
  5. Does the content stay neutral and reusable outside this project?
- If the review finds a violation, revise immediately and run the verification search again. Do not leave known writing-standard violations for a later pass unless the user explicitly asks to defer.

Key rules for the Go teaching material:

- Atomize each article around one concept.
- Make intent explicit before implementation details.
- Keep headings and terms grep-friendly.
- For longer technical chapters, preserve the reasoning path:
  observation -> interpretation -> strategy -> execution.
- Put business logic before concrete code cases.

Key rules for Backend teaching material:

- Backend chapters must discuss requirements before concrete service operation details.
- Backend material must be language-neutral. Backend chapters should not depend on Go, Python, or any other language tutorial links as prerequisite reading.
- Direction of dependency: language tutorials may link to Backend service concepts, but Backend service chapters should stand alone and explain concepts in a way usable from multiple languages.
- Backend service entity articles must include a cross-language adaptation section. This section should evaluate which language/runtime traits fit the service well, which traits create risk, and what abstraction or operation boundary each language needs.
- Every Backend chapter that evaluates a service category or concrete service entity must include a cost and opportunity-cost section.
- The cost section must explicitly cover security constraints, traffic and stability impact, server/cloud cost, human operation cost, and the opportunity cost of choosing this option over simpler or alternative designs.
- Security constraints are part of the cost model. Permission boundaries, data masking, encryption, audit, and server protection can improve risk posture, but they also add implementation, operation, testing, and incident-response cost.
- Service entity articles must not present a tool as an automatic best practice. They must explain what risk the tool lowers, what new burden it adds, what cheaper option exists, and what condition would change the decision.

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
