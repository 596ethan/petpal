# Appointment Conflict Check Acceptance

## Status
Accepted, completed, and promoted to stable baseline on 2026-04-26.

Stable tag: `appointment-conflict-check-stable`.

Manual phone/admin verification passed. Live DB active-duplicate guard maintenance was executed after confirmation:
- Backup created at `_tmp_db_backup/petpal-live-before-appointment-guard-20260426-225023.sql`.
- Active duplicate check returned 0 groups before ALTER, so no live appointment rows were cleaned.
- `appointment.active_duplicate_guard` and unique index `uk_appointment_active_duplicate` were applied to the live `petpal` database.
- Active duplicate check returned 0 groups after ALTER.

## Behavior Verified By Automated Tests
- Duplicate active appointment creation is rejected with HTTP `409`.
- Conflict response code is `APPOINTMENT_CONFLICT`.
- Conflict response message is `该宠物在此时间已有预约，请选择其他时间`.
- A second active duplicate row is not inserted.
- Rebooking the same pet, provider, and appointment time is allowed after the first appointment is cancelled.
- Rebooking the same pet, provider, and appointment time is allowed after the first appointment is completed.
- The database unique constraint blocks duplicate active inserts even when the write bypasses the service pre-check.
- `AppointmentService` translates the database unique-constraint conflict into `409 APPOINTMENT_CONFLICT`.
- Phone repository surfaces the backend conflict code and message instead of converting it to a generic network error.

## Commands Run
- `.\scripts\test-backend.ps1`
  - Result: `Tests run: 49, Failures: 0, Errors: 0, Skipped: 0`.
- `hvigorw.js test --no-daemon`
  - Result: `BUILD SUCCESSFUL in 14 s 358 ms`.
- `hvigorw.js assembleHap --no-daemon`
  - Result: `BUILD SUCCESSFUL in 15 s 705 ms`.
  - Warning: signing config is not configured; HAP signing was skipped.
- Live DB smoke after ALTER
  - `GET /api/provider/list`: HTTP `200`.
  - Login smoke: success.
  - Appointment list smoke: success, current count `12`.
  - Duplicate active insert smoke: blocked by `appointment.uk_appointment_active_duplicate`; smoke rows left `0`.

## Manual Verification Completed
- First appointment succeeds.
- Repeating the same pet, provider, and time shows `该宠物在此时间已有预约，请选择其他时间`.
- Cancelling the appointment allows booking the same pet, provider, and time again.
- Admin confirm/complete flow does not regress.

## Live DB Audit Completed
- Current active duplicate appointment groups: `0`.
- Historical duplicate appointment groups by `user_id + pet_id + provider_id + appointment_time`: `4`; these are cancelled/completed historical rows and do not violate the active duplicate rule.
- Exact duplicate appointment rows with same business fields and status: `3` groups; all are `CANCELLED` test/history rows.
- Orphan reference checks returned no current orphan rows in the audited live DB tables.
- Schema audit confirmed there are no database foreign keys; this is a broader schema risk, not part of the appointment-conflict guard slice.

## Maintenance Script Scope
- `scripts/appointment-active-duplicate-guard.sql` is committed only as a manual live DB maintenance script.
- The script is not executed automatically by the app, tests, backend startup, or any repo command.
- Future live DB runs must still follow the sequence: backup, duplicate check, manual cleanup if needed, ALTER, smoke verification.

## Known Risks And Follow-Up
- Existing historical cancelled duplicate appointment rows remain in live DB; they are allowed by the accepted rule because only active `PENDING_CONFIRM` and `CONFIRMED` appointments are guarded.
- The rebuild baseline in `schema.sql` contains the appointment guard, but existing environments still require explicit manual maintenance if they have not already run the ALTER.
- The repo still has no Flyway/Liquibase migration mechanism, so schema changes are not auto-applied to existing databases.
- The broader live DB audit found missing database-level foreign key constraints and some business uniqueness gaps outside the current slice.

## Commit Message
`fix: harden duplicate active appointment guard`
