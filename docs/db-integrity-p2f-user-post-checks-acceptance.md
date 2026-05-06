# DB Integrity P2f User Post Checks Acceptance

## Status
Code baseline and live DB P2f maintenance completed on 2026-05-05 against local MySQL `petpal`.
- Backup created at `_tmp_db_backup/petpal-live-before-db-integrity-p2f-user-post-checks-20260505-234601.sql`.
- Live `ALTER TABLE` was executed successfully.
- Post-checks, direct-write DB smoke, and minimal API smoke passed.

## Scope
- Add one `user` CHECK and four `post` CHECK constraints in `schema.sql`.
- Add a direct-write backend test that proves the database rejects invalid user/post values.
- Add a manual SQL script for future live DB execution and rollback.
- Record verification for this user/post `CHECK` subset only, not full P2.

## Explicit Non-Scope
- No phone-client changes.
- No admin changes.
- No REST API changes.
- No business validation or error-message changes.
- No `user.status` CHECK; current code does not define a user status enum.
- No `post.status` CHECK; current code uses `ACTIVE`, but does not define a post status enum.
- No `service_review` constraints.

## Files
- `petpal-server/src/main/resources/db/schema.sql`
- `petpal-server/src/test/java/com/petpal/server/PetPalServerMvcTest.java`
- `scripts/db-integrity-p2f-user-post-checks.sql`
- `docs/db-integrity-p2f-user-post-checks-acceptance.md`

## Automated Verification
- `mvn -Dtest=PetPalServerMvcTest#dbIntegrityP2fRejectsInvalidUserPostCheckValues test`
  - Before schema constraints, failed as expected because invalid `user.deleted` was accepted.
  - After schema constraints, passed with `Tests run: 1, Failures: 0, Errors: 0, Skipped: 0`.
- `.\scripts\test-backend.ps1`
  - Result: passed, `Tests run: 62, Failures: 0, Errors: 0, Skipped: 0`.

## Live DB Read-Only Pre-Check
- Connection source: `petpal-server/src/main/resources/application.yml`
  - `jdbc:mysql://localhost:3306/petpal`
  - user `root`
- MySQL version: `8.0.40`.
- Result counts before ALTER:
  - `user_deleted_bool = 0`
  - `post_visibility = 0`
  - `post_like_count_non_negative = 0`
  - `post_comment_count_non_negative = 0`
  - `post_deleted_bool = 0`
- Existing P2f CHECK constraint check returned 0 rows before ALTER.

## Live DB Execution Result
- Executed as separate table ALTER statements:
  - `ALTER TABLE user ADD CONSTRAINT chk_user_deleted_bool ...`
  - `ALTER TABLE post ADD CONSTRAINT chk_post_visibility ..., ADD CONSTRAINT chk_post_like_count_non_negative ..., ADD CONSTRAINT chk_post_comment_count_non_negative ..., ADD CONSTRAINT chk_post_deleted_bool ...`
- Constraint existence check passed for:
  - `chk_post_comment_count_non_negative`
  - `chk_post_deleted_bool`
  - `chk_post_like_count_non_negative`
  - `chk_post_visibility`
  - `chk_user_deleted_bool`
- Post-ALTER invalid counts remained clean:
  - `user_deleted_bool = 0`
  - `post_visibility = 0`
  - `post_like_count_non_negative = 0`
  - `post_comment_count_non_negative = 0`
  - `post_deleted_bool = 0`

## Live Smoke
- Direct invalid `user.deleted` insert was rejected by `chk_user_deleted_bool` with `ERROR 3819`.
- Direct invalid `post.visibility` insert was rejected by `chk_post_visibility` with `ERROR 3819`.
- Direct invalid `post.like_count` insert was rejected by `chk_post_like_count_non_negative` with `ERROR 3819`.
- Direct invalid `post.comment_count` insert was rejected by `chk_post_comment_count_non_negative` with `ERROR 3819`.
- Direct invalid `post.deleted` insert was rejected by `chk_post_deleted_bool` with `ERROR 3819`.
- `POST /api/user/login`: response code `OK`.
- `GET /api/post/feed`: response code `OK`, current feed count `7`.
- `GET /api/post/1`: response code `OK`, post id `1`.
- `GET /api/post/1/comment`: response code `OK`, current comment count `2`.

## Known Risks
- New databases created from `schema.sql` will enforce these five checks immediately.
- Existing databases still need the manual ALTER in `scripts/db-integrity-p2f-user-post-checks.sql`.
- These checks enforce DB-level boundaries only; API validation remains owned by the existing service layer.
- Existing `post.like_count` and `post.comment_count` values are only constrained to be non-negative; this slice does not reconcile derived count drift.
- MySQL `CHECK` enforcement requires MySQL 8.0.16 or newer; the verified local version is MySQL `8.0.40`.

## Suggested Commit Message
`fix: add user post db checks`
