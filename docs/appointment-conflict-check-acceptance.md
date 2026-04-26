# Appointment Conflict Check Acceptance

## Status
Accepted and completed on 2026-04-26.

Manual phone/admin verification passed.
Live DB duplicate cleanup and ALTER are intentionally not executed in this round and still require separate confirmation before running.

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

## Manual Verification Completed
- First appointment succeeds.
- Repeating the same pet, provider, and time shows `该宠物在此时间已有预约，请选择其他时间`.
- Cancelling the appointment allows booking the same pet, provider, and time again.
- Admin confirm/complete flow does not regress.

## Live DB Follow-Up Still Pending
- Before applying the live DB ALTER, run the duplicate query in `scripts/appointment-active-duplicate-guard.sql` and clean any active duplicate groups manually.
- This script is committed only as a manual maintenance script and is not executed automatically by the app, tests, or any repo script.

## Known Risks And Follow-Up
- `schema.sql` is updated as the rebuild baseline, but any existing MySQL database still needs the manual cleanup plus ALTER in `scripts/appointment-active-duplicate-guard.sql`.
- There is still no Flyway/Liquibase migration mechanism in this repo, so this guard is not auto-applied to existing environments.

## Suggested Commit Message
`fix: harden duplicate active appointment guard`
