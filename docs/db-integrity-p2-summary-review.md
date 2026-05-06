# DB Integrity P2 Summary Review

## Status

Review date: 2026-05-06

Branch: `codex/docs/db-integrity-p2g-summary-review`

Base commit: `799ae42 fix: repair post derived counts`

Live database: local MySQL `petpal`

Live MySQL version: `8.0.40`

Result: `schema.sql`, the maintenance scripts, the acceptance documents, and the live MySQL database are aligned for P0/P1/P2a-P2g. All expected P0/P1/P2a-P2f constraints are present in live MySQL, P2g has no DDL constraints, and all covered invalid-count/drift checks returned `0`.

This is a summary review only. No schema, DDL, seed data, backend API, phone client, or admin behavior was changed in this review update. Full P2 should still not be called sealed. The remaining candidates have been moved out of the current database plan and into backlog.

## Stage Matrix

| Stage | Commit | Script | Acceptance record | Live backup | Automated verification | Live smoke summary |
| --- | --- | --- | --- | --- | --- | --- |
| P0 cross-owner guards | `2bbdb1e fix: add p0 cross-owner db guards` | `scripts/db-integrity-p0-cross-owner-guard.sql` | `docs/db-integrity-p0-acceptance.md` | `_tmp_db_backup/petpal-live-before-db-integrity-p0-20260428-213245.sql` | `mvn -Dtest=PetPalServerMvcTest#compositeForeignKeysBlockMismatchedPostAndAppointmentWrites test`; `.\scripts\test-backend.ps1` passed with 50 tests | Provider list/login API smoke passed; direct invalid post/appointment ownership/provider writes were rejected. |
| P1 business uniques | `c5de12c fix: add p1 business uniqueness guards` | `scripts/db-integrity-p1-business-uniques.sql` | `docs/db-integrity-p1-acceptance.md` | `_tmp_db_backup/petpal-live-before-db-integrity-p1-20260428-221431.sql` | `mvn -Dtest=PetPalServerMvcTest#dbIntegrityP1* test`; `.\scripts\test-backend.ps1` passed with 56 tests | Duplicate follow, self-follow, duplicate image sort, negative sort, and duplicate active service-item name writes were rejected. |
| P2a core FKs | `bc651c1 fix: add p2a core foreign keys` | `scripts/db-integrity-p2a-core-foreign-keys.sql` | `docs/db-integrity-p2a-acceptance.md` | `_tmp_db_backup/petpal-live-before-db-integrity-p2a-20260428-231230.sql` | `mvn -Dtest=PetPalServerMvcTest#dbIntegrityP2aRejectsCoreOrphanReferences test`; `.\scripts\test-backend.ps1` passed with 57 tests | Direct orphan pet owner, pet health, pet vaccine, and service item provider writes were rejected. |
| P2b pet checks | `b9d752a fix: add pet archive db checks` | `scripts/db-integrity-p2b-pet-checks.sql` | `docs/db-integrity-p2b-acceptance.md` | `_tmp_db_backup/petpal-live-before-db-integrity-p2b-20260505-223144.sql` | `mvn -Dtest=PetPalServerMvcTest#dbIntegrityP2bRejectsInvalidPetArchiveCheckValues test`; `.\scripts\test-backend.ps1` passed with 58 tests | Invalid pet species/gender/weight/neutered/deleted and health record type writes were rejected with `ERROR 3819`. |
| P2c appointment checks | `629454f fix: add appointment db checks` | `scripts/db-integrity-p2c-appointment-checks.sql` | `docs/db-integrity-p2c-appointment-checks-acceptance.md` | `_tmp_db_backup/petpal-live-before-db-integrity-p2c-appointment-checks-20260505-225322.sql` | `mvn -Dtest=PetPalServerMvcTest#dbIntegrityP2cRejectsInvalidAppointmentCheckValues test`; `.\scripts\test-backend.ps1` passed with 59 tests | Invalid appointment status and deleted writes were rejected with `ERROR 3819`. |
| P2d community FKs | `1ff3cdb fix: add community db foreign keys` | `scripts/db-integrity-p2d-community-foreign-keys.sql` | `docs/db-integrity-p2d-community-foreign-keys-acceptance.md` | `_tmp_db_backup/petpal-live-before-db-integrity-p2d-community-foreign-keys-20260505-231144.sql` | `mvn -Dtest=PetPalServerMvcTest#dbIntegrityP2dRejectsCommunityOrphanReferences test`; `.\scripts\test-backend.ps1` passed with 60 tests | Direct orphan user follow, post, post image, post like, and comment writes were rejected with `ERROR 1452`. |
| P2e provider/service checks | `c676f83 fix: add provider service db checks` | `scripts/db-integrity-p2e-provider-service-checks.sql` | `docs/db-integrity-p2e-provider-service-checks-acceptance.md` | `_tmp_db_backup/petpal-live-before-db-integrity-p2e-provider-service-checks-20260505-232912.sql` | `mvn -Dtest=PetPalServerMvcTest#dbIntegrityP2eRejectsInvalidProviderServiceCheckValues test`; `.\scripts\test-backend.ps1` passed with 61 tests | Invalid provider type/rating/deleted and service item price/duration/deleted writes were rejected with `ERROR 3819`. |
| P2f user/post checks | `1824098 fix: add user post db checks` | `scripts/db-integrity-p2f-user-post-checks.sql` | `docs/db-integrity-p2f-user-post-checks-acceptance.md` | `_tmp_db_backup/petpal-live-before-db-integrity-p2f-user-post-checks-20260505-234601.sql` | `mvn -Dtest=PetPalServerMvcTest#dbIntegrityP2fRejectsInvalidUserPostCheckValues test`; `.\scripts\test-backend.ps1` passed with 62 tests | Invalid user deleted and post visibility/like count/comment count/deleted writes were rejected with `ERROR 3819`. |
| P2g derived counts | `799ae42 fix: repair post derived counts` | `scripts/db-integrity-p2g-derived-counts.sql` | `docs/db-integrity-p2g-derived-counts-acceptance.md` | `_tmp_db_backup/petpal-live-before-db-integrity-p2g-derived-counts-20260506-144249.sql` | `mvn -Dtest=PetPalServerMvcTest#dbIntegrityP2gPostDerivedCountsMatchActualLikesAndRootComments test`; `mvn -Dtest=PetPalServerMvcTest#likeAndUnlikeAreIdempotent test`; `.\scripts\test-backend.ps1` passed with 63 tests | Live `post.like_count` and `post.comment_count` drift was repaired; `post_derived_count_drift = 0`, and post detail API smoke returned repaired counts. |

## Schema Constraint List

Primary keys are omitted from this list.

| Table | `schema.sql` constraints |
| --- | --- |
| `user` | `UNIQUE phone`; `chk_user_deleted_bool` |
| `user_follow` | `uk_user_follow_pair`; `chk_user_follow_not_self`; `fk_user_follow_follower`; `fk_user_follow_following` |
| `pet` | `uk_pet_owner_id`; `fk_pet_owner`; `chk_pet_species`; `chk_pet_gender`; `chk_pet_weight_range`; `chk_pet_is_neutered_bool`; `chk_pet_deleted_bool` |
| `pet_health_record` | `fk_pet_health_record_pet`; `chk_pet_health_record_type` |
| `pet_vaccine` | `fk_pet_vaccine_pet` |
| `post` | `fk_post_user`; `fk_post_user_pet`; `chk_post_visibility`; `chk_post_like_count_non_negative`; `chk_post_comment_count_non_negative`; `chk_post_deleted_bool` |
| `post_image` | `uk_post_image_sort`; `chk_post_image_sort_non_negative`; `fk_post_image_post` |
| `post_like` | unnamed `UNIQUE (post_id, user_id)`; `fk_post_like_post`; `fk_post_like_user` |
| `comment` | `fk_comment_post`; `fk_comment_parent`; `fk_comment_user` |
| `service_provider` | `chk_service_provider_type`; `chk_service_provider_rating_range`; `chk_service_provider_deleted_bool` |
| `service_item` | `uk_service_item_provider_id`; `uk_service_item_active_name`; `fk_service_item_provider`; `chk_service_item_price_non_negative`; `chk_service_item_duration_positive`; `chk_service_item_deleted_bool` |
| `appointment` | `UNIQUE order_no`; `uk_appointment_active_duplicate`; `fk_appointment_user_pet`; `fk_appointment_provider_service`; `chk_appointment_status`; `chk_appointment_deleted_bool` |
| `service_review` | none |

## Live Constraint List

Live MySQL query source: `scripts/db-integrity-p2-summary-readonly.sql`.

Primary keys are omitted from this list.

| Table | Live MySQL constraints |
| --- | --- |
| `user` | `phone` unique; `chk_user_deleted_bool` |
| `user_follow` | `uk_user_follow_pair`; `chk_user_follow_not_self`; `fk_user_follow_follower`; `fk_user_follow_following` |
| `pet` | `uk_pet_owner_id`; `fk_pet_owner`; `chk_pet_species`; `chk_pet_gender`; `chk_pet_weight_range`; `chk_pet_is_neutered_bool`; `chk_pet_deleted_bool` |
| `pet_health_record` | `fk_pet_health_record_pet`; `chk_pet_health_record_type` |
| `pet_vaccine` | `fk_pet_vaccine_pet` |
| `post` | `fk_post_user`; `fk_post_user_pet`; `chk_post_visibility`; `chk_post_like_count_non_negative`; `chk_post_comment_count_non_negative`; `chk_post_deleted_bool` |
| `post_image` | `uk_post_image_sort`; `chk_post_image_sort_non_negative`; `fk_post_image_post` |
| `post_like` | `post_id` unique for `(post_id, user_id)`; `fk_post_like_post`; `fk_post_like_user` |
| `comment` | `fk_comment_post`; `fk_comment_parent`; `fk_comment_user` |
| `service_provider` | `chk_service_provider_type`; `chk_service_provider_rating_range`; `chk_service_provider_deleted_bool` |
| `service_item` | `uk_service_item_provider_id`; `uk_service_item_active_name`; `fk_service_item_provider`; `chk_service_item_price_non_negative`; `chk_service_item_duration_positive`; `chk_service_item_deleted_bool` |
| `appointment` | `order_no` unique; `uk_appointment_active_duplicate`; `fk_appointment_user_pet`; `fk_appointment_provider_service`; `chk_appointment_status`; `chk_appointment_deleted_bool` |
| `service_review` | none |

All 42 expected P0/P1/P2a-P2f constraints returned `present` from live `information_schema.table_constraints`. P2g adds no DDL constraint; it is covered by the derived-count drift check below.

## Live Invalid-Count Review

Command:

```powershell
$env:MYSQL_PWD='54321'; mysql -uroot petpal --batch --raw --execute="source scripts/db-integrity-p2-summary-readonly.sql"
```

Result summary:

| Stage | Covered invalid-count rows | Result |
| --- | ---: | --- |
| P0 | 3 | all `0` |
| P1 | 5 | all `0` |
| P2a | 4 | all `0` |
| P2b | 6 | all `0` |
| P2c | 2 | all `0` |
| P2d | 9 | all `0` |
| P2e | 6 | all `0` |
| P2f | 5 | all `0` |
| P2g | 1 | all `0` |

The live DB also reports these current unconstrained status values:

| Column | Live values |
| --- | --- |
| `user.status` | `ACTIVE = 2` |
| `post.status` | `ACTIVE = 7` |
| `service_provider.status` | `OPEN = 3` |

## Backlog Items

`service_review` still has no FK or rating CHECK constraints in `schema.sql` or live MySQL. The live read-only review found `0` appointment orphans, `0` user orphans, `0` provider orphans, and `0` rating out-of-range rows. This is now backlog, not part of the current database plan.

`user.status`, `post.status`, and `service_provider.status` still have no CHECK constraints. Current live rows are clean, but the code does not provide equally stable enum boundaries for all three. In particular, provider admin currently accepts arbitrary uppercased provider statuses, and existing tests cover `PAUSED`; adding a DB CHECK later would be a behavior decision, not only a DB integrity cleanup. This is now backlog.

Automatic `updated_at` maintenance is backlog.

A formal migration mechanism such as Flyway or Liquibase is backlog.

`post.like_count` and `post.comment_count` now have non-negative CHECK constraints from P2f, and P2g repaired the live derived-count drift. The current summary script reports `post_derived_count_drift = 0`. This still does not add triggers; application write paths must keep counters aligned, and direct DB writes can still create future drift.

## Verification Run In This Review

- `git status --short --branch`
- `git log -8 --oneline --decorate`
- `rg -n "CONSTRAINT|FOREIGN KEY|UNIQUE KEY|CHECK" petpal-server/src/main/resources/db/schema.sql`
- `mysql --version`
- `$env:MYSQL_PWD='54321'; mysql -uroot petpal --batch --raw --execute="source scripts/db-integrity-p2-summary-readonly.sql"`
  - Result: MySQL `8.0.40`; all 42 expected P0/P1/P2a-P2f DDL constraints returned `present`; P2g `post_derived_count_drift = 0`; remaining `service_review` candidate counts all returned `0`.
- `.\scripts\test-backend.ps1`
  - Result: passed, `Tests run: 63, Failures: 0, Errors: 0, Skipped: 0`.

No Java, `schema.sql`, seed data, API, phone client, or admin code changed in this review update.

## Suggested Commit Message

`docs: include p2g in db integrity summary`
