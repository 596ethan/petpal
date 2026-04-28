# DB Integrity P0 Acceptance

## Status
Code baseline completed on 2026-04-26.

Live DB P0 maintenance was executed on 2026-04-28 against local MySQL `petpal`.
- Backup created at `_tmp_db_backup/petpal-live-before-db-integrity-p0-20260428-213245.sql`.
- `post.id = 2` was corrected from `user_id = 2` to `user_id = 1`.
- `uk_pet_owner_id`, `uk_service_item_provider_id`, `fk_post_user_pet`, `fk_appointment_user_pet`, and `fk_appointment_provider_service` were applied successfully.
- Phone-side and admin-side manual verification passed on 2026-04-28.

## Scope
- Clean the rebuild seed mismatch where `post.id = 2` referenced `pet.id = 2` with the wrong author.
- Add database constraints that block direct writes of a post with a non-owned pet.
- Add database constraints that block direct writes of an appointment with a non-owned pet.
- Add database constraints that block direct writes of an appointment with a service from another provider.

## Files
- `petpal-server/src/main/resources/db/schema.sql`
- `petpal-server/src/main/resources/db/seed.sql`
- `scripts/db-integrity-p0-cross-owner-guard.sql`
- `petpal-server/src/test/java/com/petpal/server/PetPalServerMvcTest.java`

## Automated Verification
- `mvn -Dtest=PetPalServerMvcTest#compositeForeignKeysBlockMismatchedPostAndAppointmentWrites test`
  - Result: passed, `Tests run: 1, Failures: 0, Errors: 0, Skipped: 0`.
- `.\scripts\test-backend.ps1`
  - Result: passed, `Tests run: 50, Failures: 0, Errors: 0, Skipped: 0`.

## Live DB Read-Only Pre-Check
- Command: MySQL 8.0.40 read-only count query against local `petpal`.
- Result: `post.user_pet = 1`, `appointment.user_pet = 0`, `appointment.provider_service = 0`.

## Live DB Execution Result
- Post-cleanup mismatch counts: `post.user_pet = 0`, `appointment.user_pet = 0`, `appointment.provider_service = 0`.
- Constraint existence check passed for:
  - `uk_pet_owner_id`
  - `uk_service_item_provider_id`
  - `fk_post_user_pet`
  - `fk_appointment_user_pet`
  - `fk_appointment_provider_service`

## Live Smoke
- `GET /api/provider/list`: `200`, response code `OK`, current provider count `3`.
- `POST /api/user/login`: `200`, response code `OK`, profile id `1`.
- `GET /api/appointment/list`: `200`, response code `OK`, current appointment count `12`.
- Direct invalid `post(user_id, pet_id)` insert is rejected by `fk_post_user_pet`.
- Direct invalid `appointment(user_id, pet_id)` insert is rejected by `fk_appointment_user_pet`.
- Direct invalid `appointment(provider_id, service_id)` insert is rejected by `fk_appointment_provider_service`.

## Manual Verification Completed
- Phone-side normal path passed.
- Admin-side normal path passed.
- No regression was found in the manual check after the live DB P0 maintenance.

## Known Risks
- This does not add ordinary foreign keys for every referenced column; those remain P2 scope.
- This does not prevent using soft-deleted pets or services by itself; backend business checks still own that rule.
- Other existing databases still will not pick up `schema.sql` changes without a manual ALTER or a future migration mechanism.

## Suggested Commit Message
`fix: add p0 cross-owner db guards`
