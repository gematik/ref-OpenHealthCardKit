## Code Comments

- Default: no comments.
- `///` doc comments: only on `public`/`open` API (per SwiftLint `missing_docs`).
- `//` allowed only for non-obvious "why": framework quirks, workarounds,
  hazards (ordering/concurrency/lifetime), rejected alternatives.
- Never comment what the code already says — rename/refactor instead.

## Makefile Commands

- `make setup`: only for initial environment setup, or to recover from a broken/stale env (dependency, cache, generated-project issues).
- `make update`: update Carthage dependencies. Runs `carthage update --no-build`.
- `make format` + `make lint`: run after every code change. `format` via swiftformat; `lint` runs swiftformat (lint mode) + swiftlint.
- `make test`: build and run tests (iOS + macOS). Runs `fastlane test_all`.
- `make build`: unsigned build-for-testing only (iOS + macOS). Runs `fastlane build_all` — no tests, no signing.


<!-- BACKLOG.MD GUIDELINES START -->
<!-- backlog.md-instructions-version: 1.52.0 -->
<CRITICAL_INSTRUCTION>

## Backlog.md Workflow

This project uses Backlog.md for task and project management.

**At the beginning of each conversation in this project, run `backlog instructions overview` before answering or taking action. Re-read it only if you have not read it yet in the current conversation.**

Use the overview to decide whether to search, read, create, or update Backlog tasks.

Before task lifecycle actions, read the matching detailed guide:
- `backlog instructions task-creation` before creating or splitting tasks
- `backlog instructions task-execution` before planning, changing status or assignee, adding a plan or implementation notes, or implementing task work
- `backlog instructions task-finalization` before checking acceptance criteria, writing final summaries, or moving tasks to terminal statuses

Use `backlog <command> --help` before running unfamiliar commands. Help shows options, fields, and examples.

Do not edit Backlog task, draft, document, decision, or milestone markdown files directly. Use the `backlog` CLI so metadata, relationships, and history stay consistent.

**TaskCreate is session-only.** When creating backlog tasks, use `backlog task create`, not Claude's TaskCreate tool. TaskCreate creates ephemeral in-memory tasks that don't persist to disk and will not appear in `backlog/tasks/`. Always use the `backlog` CLI for any task management in this project.

**Do not manually create task markdown files.** Backlog.md requires YAML frontmatter with metadata (`id`, `title`, `status`, `created_date`, etc.). Files created by hand lack this and are invisible to the browser. Always use `backlog task create` to generate properly-formatted task files.

</CRITICAL_INSTRUCTION>
<!-- BACKLOG.MD GUIDELINES END -->
