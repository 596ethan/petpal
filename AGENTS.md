# PetPal Codex Rules

## Scope
This file applies to the whole repository.

## Mission
Build and maintain a real, testable, phone-first MVP for PetPal.
Prefer work that directly improves or unblocks the phone MVP.

## Product Priority
Primary deliverable:
- `Cutepetpost` phone client

Support-only surfaces:
- `petpal-server`
- `petpal-admin`

Out of scope unless explicitly promoted into the current accepted phone-MVP stage or a new approved slice:
- tablet/watch adaptation
- multi-device collaboration
- search
- map features
- notifications
- reviews
- SMS login
- third-party login
- non-essential infrastructure work

## Source of Truth
Before substantive implementation, read:
1. `docs/phone-mvp.md`
2. relevant accepted docs in `docs/`
3. the directly affected module code only

Do not read broadly across unrelated docs unless needed for debugging a conflict, acceptance record, or cross-module contract.

## Canonical Commands
Use these commands unless a task explicitly requires otherwise:

- deps up: `.\scripts\dev-deps-up.ps1`
- backend tests: `.\scripts\test-backend.ps1`
- backend run: `.\scripts\run-backend.ps1`

Phone client:
- open `Cutepetpost` in DevEco Studio
- phone is the only first-class target

## Working Protocol
For any task that is not trivial:
1. First inspect the relevant spec and affected files.
2. State a short plan before editing.
3. Make the minimum necessary change.
4. Avoid unrelated renames, formatting churn, and opportunistic refactors.
5. Do not expand scope without a phone-MVP reason.

## Git Rules
- Use Codex-compatible branch names with semantic suffixes:
  - `codex/feature/<slice-or-topic>`
  - `codex/fix/<slice-or-topic>`
  - `codex/docs/<topic>`
- Use commit messages in the form `<type>: <summary>`.
  - Examples: `feat: implement community p0`, `fix: proxy uploaded images`, `docs: seal community p0 acceptance`
- Before ending any slice or reviewable unit of work, run `git status --short` and separate:
  - intended source or documentation changes
  - generated or temporary files
  - pre-existing user changes
  - files that still need to be added intentionally
- Do not commit unrelated changes. Do not revert user changes unless the user explicitly asks.

## File Hygiene
- Temporary acceptance files must not enter git. This includes `_tmp_*`, screenshots, layout dumps, transient logs, and ad hoc generated images.
- If acceptance evidence must be retained, summarize it in `docs/*acceptance.md` instead of keeping scattered temporary files.
- Keep generated build outputs, local caches, and tool home directories out of commits.
- Do not clean up files you did not create unless the user explicitly asks or they are ignored temporary artifacts created by the current task.

## Slice Contract
Before implementing a substantive slice, ensure the slice spec in `docs/phone-mvp.md` covers:
- user goal
- entry screen
- API contract
- success state
- failure state
- test cases

No substantive coding without a concrete slice spec.

## Implementation Rules
- Do not extend `DemoDataStore` for core flows.
- Replace mock-backed behavior with real persistence in MVP order.
- Backend work must be justified by a phone use case.
- Admin work must be justified by appointment fulfillment or phone-side status visibility.
- Preserve existing product direction unless a real flow requires UI change.

## Encoding And Copy Rules
- Keep source, docs, and generated acceptance records as UTF-8.
- Do not introduce mojibake or repair unrelated mojibake opportunistically.
- If a touched file already contains mojibake, only fix text directly relevant to the current task unless the user requests a broader cleanup.
- User-facing copy must remain readable in the phone UI and acceptance docs. If Chinese text cannot be entered safely in the current shell/tool path, prefer ASCII acceptance labels over corrupted Chinese.

## Testing Rules
For each real feature slice:
1. Write or update failing backend tests first.
2. Implement persistence and business rules.
3. Update phone-side repository/integration tests where applicable.
4. Wire the phone UI to real APIs.
5. Run verification before declaring done.

Core verification expectations:
- auth success/failure
- appointment creation
- appointment list by current user
- cancel rules
- admin status transition rules
- pet creation
- pet partial update
- pet soft delete
- health record creation/list
- vaccine record creation/list
- phone client error/empty states

## Environment Notes
For phone-device debugging:
- the phone app must use the dev machine LAN IP, not `127.0.0.1`
- keep backend, phone app, and admin page on the same backend HTTP port
- watch for Windows port conflicts in the `8000-8099` range
- if admin page fails with `failed to fetch`, check CORS/preflight and `X-PetPal-Admin-Token`

Runtime defaults:
- MySQL default database: `petpal`
- MySQL default host port: `3306`
- Redis default port: `6379`
- MinIO API/console ports: `9000`/`9001`
- admin token is development-only and must not be treated as a production secret

## Data Model Rule
Schema and APIs must align with PRD only where needed for the phone MVP.
Do not expand secondary tables early unless the phone flow requires them immediately.

## Done Definition
A task is not done if:
- it still depends on mock data
- it only echoes request payloads
- it has no business-rule tests
- the phone client cannot consume it end-to-end

A task is done only when:
- backend behavior is real
- tests cover the rule being changed
- the phone client consumes the real API when relevant
- the result is demonstrable end-to-end or the remaining manual step is stated clearly

## Slice Sealing Protocol
A slice may be called "sealed" only after all of the following are true:
- `docs/phone-mvp.md` contains the accepted slice contract.
- Backend and phone-side tests relevant to the slice have been run and recorded.
- Real-device, emulator, or explicitly accepted manual verification has a written record.
- Known risks, blocked checks, and out-of-scope items are listed.
- `git status --short` has been reviewed and temporary files are ignored or removed.
- A sealing or acceptance document exists at `docs/<slice>-device-acceptance.md`, or an existing acceptance document is updated.
- The final report includes a suggested commit message.

If a P0 requirement is unverified or blocked, the slice is only a "seal candidate"; do not call it sealed.

## Required Final Output
At the end of each task, report:
- changed files
- what behavior changed
- tests/commands run
- manual verification still needed
- remaining risks or follow-ups
