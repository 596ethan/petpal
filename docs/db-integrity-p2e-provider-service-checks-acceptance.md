# DB Integrity P2e Provider Service Checks Acceptance

## Status
Code baseline and live DB P2e maintenance completed on 2026-05-05 against local MySQL `petpal`.
- Backup created at `_tmp_db_backup/petpal-live-before-db-integrity-p2e-provider-service-checks-20260505-232912.sql`.
- Live `ALTER TABLE` was executed successfully.
- Post-checks, direct-write DB smoke, and minimal API smoke passed.

## Scope
- Add six `CHECK` constraints for `service_provider` and `service_item` in `schema.sql`.
- Add a direct-write backend test that proves the database rejects invalid provider/service values.
- Add a manual SQL script for future live DB execution and rollback.
- Record verification for this provider/service item `CHECK` subset only, not full P2.

## Explicit Non-Scope
- No phone-client changes.
- No admin changes.
- No REST API changes.
- No business validation or error-message changes.
- No `service_provider.status` check; current code does not define a status enum.
- No `post`, `user`, or `service_review` constraints.

## Files
- `petpal-server/src/main/resources/db/schema.sql`
- `petpal-server/src/test/java/com/petpal/server/PetPalServerMvcTest.java`
- `scripts/db-integrity-p2e-provider-service-checks.sql`
- `docs/db-integrity-p2e-provider-service-checks-acceptance.md`

## Automated Verification
- `mvn -Dtest=PetPalServerMvcTest#dbIntegrityP2eRejectsInvalidProviderServiceCheckValues test`
  - Before schema constraints, failed as expected because invalid `service_provider.type` was accepted.
  - After schema constraints, passed with `Tests run: 1, Failures: 0, Errors: 0, Skipped: 0`.
- `.\scripts\test-backend.ps1`
  - Result: passed, `Tests run: 61, Failures: 0, Errors: 0, Skipped: 0`.

## Live DB Read-Only Pre-Check
- Connection source: `petpal-server/src/main/resources/application.yml`
  - `jdbc:mysql://localhost:3306/petpal`
  - user `root`
- MySQL version: `8.0.40`.
- Result counts before ALTER:
  - `service_provider_type = 0`
  - `service_provider_rating_range = 0`
  - `service_provider_deleted_bool = 0`
  - `service_item_price_non_negative = 0`
  - `service_item_duration_positive = 0`
  - `service_item_deleted_bool = 0`
- Existing P2e CHECK constraint check returned 0 rows before ALTER.

## Live DB Execution Result
- Executed as separate table ALTER statements:
  - `ALTER TABLE service_provider ADD CONSTRAINT chk_service_provider_type ..., ADD CONSTRAINT chk_service_provider_rating_range ..., ADD CONSTRAINT chk_service_provider_deleted_bool ...`
  - `ALTER TABLE service_item ADD CONSTRAINT chk_service_item_price_non_negative ..., ADD CONSTRAINT chk_service_item_duration_positive ..., ADD CONSTRAINT chk_service_item_deleted_bool ...`
- Constraint existence check passed for:
  - `chk_service_item_deleted_bool`
  - `chk_service_item_duration_positive`
  - `chk_service_item_price_non_negative`
  - `chk_service_provider_deleted_bool`
  - `chk_service_provider_rating_range`
  - `chk_service_provider_type`
- Post-ALTER invalid counts remained clean:
  - `service_provider_type = 0`
  - `service_provider_rating_range = 0`
  - `service_provider_deleted_bool = 0`
  - `service_item_price_non_negative = 0`
  - `service_item_duration_positive = 0`
  - `service_item_deleted_bool = 0`

## Live Smoke
- Direct invalid `service_provider.type` insert was rejected by `chk_service_provider_type` with `ERROR 3819`.
- Direct invalid `service_provider.rating` insert was rejected by `chk_service_provider_rating_range` with `ERROR 3819`.
- Direct invalid `service_provider.deleted` insert was rejected by `chk_service_provider_deleted_bool` with `ERROR 3819`.
- Direct invalid `service_item.price` insert was rejected by `chk_service_item_price_non_negative` with `ERROR 3819`.
- Direct invalid `service_item.duration` insert was rejected by `chk_service_item_duration_positive` with `ERROR 3819`.
- Direct invalid `service_item.deleted` insert was rejected by `chk_service_item_deleted_bool` with `ERROR 3819`.
- `POST /api/user/login`: response code `OK`.
- `GET /api/provider/list`: response code `OK`, current provider count `3`.
- `GET /api/provider/1`: response code `OK`, provider id `1`.
- `GET /api/provider/1/services`: response code `OK`, current service count `2`.

## Known Risks
- New databases created from `schema.sql` will enforce these six checks immediately.
- Existing databases still need the manual ALTER in `scripts/db-integrity-p2e-provider-service-checks.sql`.
- These checks enforce DB-level boundaries only; API validation remains owned by the existing service layer.
- MySQL `CHECK` enforcement requires MySQL 8.0.16 or newer; the verified local version is MySQL `8.0.40`.

## Suggested Commit Message
`fix: add provider service db checks`
