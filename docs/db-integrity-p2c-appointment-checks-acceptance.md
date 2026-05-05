# DB Integrity P2c Appointment Checks Acceptance

## Status
Code baseline and live DB P2c maintenance completed on 2026-05-05 against local MySQL `petpal`.
- Backup created at `_tmp_db_backup/petpal-live-before-db-integrity-p2c-appointment-checks-20260505-225322.sql`.
- Live `ALTER TABLE` was executed successfully.
- Post-checks, direct-write DB smoke, and minimal API smoke passed.

## Scope
- Add two appointment-table `CHECK` constraints in `schema.sql`.
- Add a direct-write backend test that proves the database rejects invalid appointment `status` and `deleted` values.
- Add a manual SQL script for future live DB execution and rollback.
- Record verification for this appointment `CHECK` subset only, not full P2.

## Explicit Non-Scope
- No phone-client changes.
- No admin changes.
- No new API endpoints.
- No business validation changes.
- No appointment status transition rule changes.
- No provider, service item, community, or service review constraints.
- No remaining ordinary foreign keys.

## Files
- `petpal-server/src/main/resources/db/schema.sql`
- `petpal-server/src/test/java/com/petpal/server/PetPalServerMvcTest.java`
- `scripts/db-integrity-p2c-appointment-checks.sql`
- `docs/db-integrity-p2c-appointment-checks-acceptance.md`

## Automated Verification
- `mvn -Dtest=PetPalServerMvcTest#dbIntegrityP2cRejectsInvalidAppointmentCheckValues test`
  - Before schema constraints, failed as expected because invalid appointment `status` was accepted.
  - After schema constraints, passed with `Tests run: 1, Failures: 0, Errors: 0, Skipped: 0`.
- `.\scripts\test-backend.ps1`
  - Result: passed, `Tests run: 59, Failures: 0, Errors: 0, Skipped: 0`.

## Live DB Read-Only Pre-Check
- Connection source: `petpal-server/src/main/resources/application.yml`
  - `jdbc:mysql://localhost:3306/petpal`
  - user `root`
- Result counts before ALTER:
  - `appointment_status = 0`
  - `appointment_deleted_bool = 0`
- Existing P2c CHECK constraint check returned 0 rows before ALTER.

## Live DB Execution Result
- Executed as separate ALTER statements:
  - `ALTER TABLE appointment ADD CONSTRAINT chk_appointment_status CHECK (status IN ('PENDING_CONFIRM', 'CONFIRMED', 'COMPLETED', 'CANCELLED', 'EXPIRED'))`
  - `ALTER TABLE appointment ADD CONSTRAINT chk_appointment_deleted_bool CHECK (deleted IN (0, 1))`
- Constraint existence check passed for:
  - `chk_appointment_deleted_bool`
  - `chk_appointment_status`
- Post-ALTER invalid counts remained clean:
  - `appointment_status = 0`
  - `appointment_deleted_bool = 0`

## Live Smoke
- Direct invalid `appointment.status` insert was rejected by `chk_appointment_status` with `ERROR 3819`.
- Direct invalid `appointment.deleted` insert was rejected by `chk_appointment_deleted_bool` with `ERROR 3819`.
- `POST /api/user/login`: response code `OK`.
- `GET /api/appointment/list`: response code `OK`, current appointment count `13`.
- `GET /api/provider/list`: response code `OK`, current provider count `3`.

## Known Risks
- New databases created from `schema.sql` will enforce these two checks immediately.
- Existing databases still need the manual ALTER in `scripts/db-integrity-p2c-appointment-checks.sql`.
- These checks enforce DB-level boundaries only; API validation and appointment status flow rules remain owned by the existing service layer.
- MySQL `CHECK` enforcement requires MySQL 8.0.16 or newer; the verified local version is MySQL `8.0.40`.

## Suggested Commit Message
`fix: add appointment db checks`
