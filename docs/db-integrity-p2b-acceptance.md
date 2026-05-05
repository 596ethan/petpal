# DB Integrity P2b Acceptance

## Status
Code baseline and live DB P2b maintenance completed on 2026-05-05 against local MySQL `petpal`.
- Backup created at `_tmp_db_backup/petpal-live-before-db-integrity-p2b-20260505-223144.sql`.
- Live `ALTER TABLE` was executed successfully.
- Post-checks and minimal DB/API smoke passed.

## Scope
- Add six pet archive `CHECK` constraints in `schema.sql`.
- Add direct-write backend tests that prove the database rejects invalid pet archive values.
- Add a manual SQL script for future live DB execution and rollback.
- Record verification for this small P2b slice.

## Explicit Non-Scope
- No phone-client changes.
- No admin changes.
- No new API endpoints.
- No business validation changes.
- No provider, community, appointment, service item, or service review checks.
- No remaining ordinary foreign keys.

## Files
- `petpal-server/src/main/resources/db/schema.sql`
- `petpal-server/src/test/java/com/petpal/server/PetPalServerMvcTest.java`
- `scripts/db-integrity-p2b-pet-checks.sql`
- `docs/db-integrity-p2b-acceptance.md`

## Automated Verification
- `mvn -Dtest=PetPalServerMvcTest#dbIntegrityP2bRejectsInvalidPetArchiveCheckValues test`
  - Before schema constraints, failed as expected because invalid `pet.species` was accepted.
  - After schema constraints, passed with `Tests run: 1, Failures: 0, Errors: 0, Skipped: 0`.
- `.\scripts\test-backend.ps1`
  - Result: passed, `Tests run: 58, Failures: 0, Errors: 0, Skipped: 0`.

## Live DB Read-Only Pre-Check
- Connection source: `petpal-server/src/main/resources/application.yml`
  - `jdbc:mysql://localhost:3306/petpal`
  - user `root`
- Result counts before ALTER:
  - `pet_species = 0`
  - `pet_gender = 0`
  - `pet_weight_range = 0`
  - `pet_is_neutered_bool = 0`
  - `pet_deleted_bool = 0`
  - `pet_health_record_type = 0`
- Existing P2b CHECK constraint check returned 0 rows before ALTER.

## Live DB Execution Result
- Executed as separate ALTER statements:
  - `ALTER TABLE pet ADD CONSTRAINT chk_pet_species CHECK (species IN ('DOG', 'CAT', 'RABBIT', 'BIRD', 'OTHER'))`
  - `ALTER TABLE pet ADD CONSTRAINT chk_pet_gender CHECK (gender IN ('MALE', 'FEMALE', 'UNKNOWN'))`
  - `ALTER TABLE pet ADD CONSTRAINT chk_pet_weight_range CHECK (weight IS NULL OR weight BETWEEN 0.01 AND 999.99)`
  - `ALTER TABLE pet ADD CONSTRAINT chk_pet_is_neutered_bool CHECK (is_neutered IN (0, 1))`
  - `ALTER TABLE pet ADD CONSTRAINT chk_pet_deleted_bool CHECK (deleted IN (0, 1))`
  - `ALTER TABLE pet_health_record ADD CONSTRAINT chk_pet_health_record_type CHECK (record_type IN ('VACCINE', 'CHECKUP', 'MEDICATION', 'SURGERY'))`
- Constraint existence check passed for:
  - `chk_pet_deleted_bool`
  - `chk_pet_gender`
  - `chk_pet_is_neutered_bool`
  - `chk_pet_species`
  - `chk_pet_weight_range`
  - `chk_pet_health_record_type`
- Post-ALTER invalid counts remained clean:
  - `pet_species = 0`
  - `pet_gender = 0`
  - `pet_weight_range = 0`
  - `pet_is_neutered_bool = 0`
  - `pet_deleted_bool = 0`
  - `pet_health_record_type = 0`

## Live Smoke
- Direct invalid `pet.species` insert was rejected by `chk_pet_species` with `ERROR 3819`.
- Direct invalid `pet.gender` insert was rejected by `chk_pet_gender` with `ERROR 3819`.
- Direct invalid `pet.weight` insert was rejected by `chk_pet_weight_range` with `ERROR 3819`.
- Direct invalid `pet.is_neutered` insert was rejected by `chk_pet_is_neutered_bool` with `ERROR 3819`.
- Direct invalid `pet.deleted` insert was rejected by `chk_pet_deleted_bool` with `ERROR 3819`.
- Direct invalid `pet_health_record.record_type` insert was rejected by `chk_pet_health_record_type` with `ERROR 3819`.
- `POST /api/user/login`: response code `OK`.
- `GET /api/pet/list`: response code `OK`, current pet count `2`.
- `GET /api/pet/1/health`: response code `OK`, current health record count `2`.

## Known Risks
- New databases created from `schema.sql` will enforce these six checks immediately.
- Existing databases still need the manual ALTER in `scripts/db-integrity-p2b-pet-checks.sql`.
- These checks enforce DB-level boundaries only; API validation and user-facing error text remain owned by the existing service layer.
- MySQL `CHECK` enforcement requires MySQL 8.0.16 or newer; the verified local version is MySQL 8.0.40.

## Suggested Commit Message
`fix: add p2b pet archive checks`
