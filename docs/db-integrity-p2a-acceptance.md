# DB Integrity P2a Acceptance

## Status
Code baseline and live DB P2a maintenance completed on 2026-04-28 against local MySQL `petpal`.
- Backup created at `_tmp_db_backup/petpal-live-before-db-integrity-p2a-20260428-231230.sql`.
- Live `ALTER TABLE` was executed successfully.
- Post-checks and minimal DB/API smoke passed.

## Scope
- Add four ordinary core foreign keys in `schema.sql`.
- Add direct-write backend tests that prove the database rejects orphan references.
- Add a manual SQL script for future live DB execution and rollback.
- Record verification for this small P2a slice.

## Explicit Non-Scope
- No phone-client changes.
- No admin changes.
- No new API endpoints.
- No enum, boolean, or range `CHECK` constraints.
- No community comment, post-like, appointment, or service-review ordinary foreign keys.
- No `ON DELETE CASCADE`.

## Files
- `petpal-server/src/main/resources/db/schema.sql`
- `petpal-server/src/test/java/com/petpal/server/PetPalServerMvcTest.java`
- `scripts/db-integrity-p2a-core-foreign-keys.sql`
- `docs/db-integrity-p2a-acceptance.md`

## Automated Verification
- `mvn -Dtest=PetPalServerMvcTest#dbIntegrityP2aRejectsCoreOrphanReferences test`
  - Result: passed, `Tests run: 1, Failures: 0, Errors: 0, Skipped: 0`.
- `.\scripts\test-backend.ps1`
  - Result: passed, `Tests run: 57, Failures: 0, Errors: 0, Skipped: 0`.

## Live DB Read-Only Pre-Check
- Connection source: `petpal-server/src/main/resources/application.yml`
  - `jdbc:mysql://localhost:3306/petpal`
  - user `root`
- Result counts before ALTER:
  - `pet_owner = 0`
  - `health_pet = 0`
  - `vaccine_pet = 0`
  - `service_item_provider = 0`
- Existing P2a FK check returned 0 rows before ALTER.

## Live DB Execution Result
- Executed as separate ALTER statements:
  - `ALTER TABLE pet ADD CONSTRAINT fk_pet_owner FOREIGN KEY (owner_id) REFERENCES user (id)`
  - `ALTER TABLE pet_health_record ADD CONSTRAINT fk_pet_health_record_pet FOREIGN KEY (pet_id) REFERENCES pet (id)`
  - `ALTER TABLE pet_vaccine ADD CONSTRAINT fk_pet_vaccine_pet FOREIGN KEY (pet_id) REFERENCES pet (id)`
  - `ALTER TABLE service_item ADD CONSTRAINT fk_service_item_provider FOREIGN KEY (provider_id) REFERENCES service_provider (id)`
- Constraint existence check passed for:
  - `fk_pet_owner`
  - `fk_pet_health_record_pet`
  - `fk_pet_vaccine_pet`
  - `fk_service_item_provider`
- Post-ALTER orphan counts remained clean:
  - `pet_owner = 0`
  - `health_pet = 0`
  - `vaccine_pet = 0`
  - `service_item_provider = 0`

## Live Smoke
- Direct orphan `pet.owner_id` insert is rejected by `fk_pet_owner`.
- Direct orphan `pet_health_record.pet_id` insert is rejected by `fk_pet_health_record_pet`.
- Direct orphan `pet_vaccine.pet_id` insert is rejected by `fk_pet_vaccine_pet`.
- Direct orphan `service_item.provider_id` insert is rejected by `fk_service_item_provider`.
- `POST /api/user/login`: response code `OK`.
- `GET /api/provider/list`: current provider count `3`.
- `GET /api/provider/1/services`: current service count `2`.
- `GET /api/pet/list`: current pet count `2`.

## Known Risks
- New databases created from `schema.sql` will enforce these four foreign keys immediately.
- Existing databases still need the manual ALTER in `scripts/db-integrity-p2a-core-foreign-keys.sql`.
- Remaining P2 work is intentionally deferred to smaller follow-up slices.
- These constraints use default restrict/no-action behavior; application soft-delete rules still own lifecycle behavior.

## Suggested Commit Message
`fix: add p2a core foreign keys`
