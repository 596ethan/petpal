# DB Integrity P2d Community Foreign Keys Acceptance

## Status
Code baseline and live DB P2d maintenance completed on 2026-05-05 against local MySQL `petpal`.
- Backup created at `_tmp_db_backup/petpal-live-before-db-integrity-p2d-community-foreign-keys-20260505-231144.sql`.
- Live `ALTER TABLE` was executed successfully.
- Post-checks, direct-write DB smoke, and minimal API smoke passed.

## Scope
- Add nine community and user-social ordinary foreign keys in `schema.sql`.
- Add a direct-write backend test that proves the database rejects orphan community references.
- Add a manual SQL script for future live DB execution and rollback.
- Record verification for this community/user-social FK subset only, not full P2.

## Explicit Non-Scope
- No phone-client changes.
- No admin changes.
- No new API endpoints.
- No business validation changes.
- No community behavior changes.
- No `ON DELETE CASCADE`.
- No `service_review` foreign keys.
- No provider, service item, or post enum/range `CHECK` constraints.

## Files
- `petpal-server/src/main/resources/db/schema.sql`
- `petpal-server/src/test/java/com/petpal/server/PetPalServerMvcTest.java`
- `scripts/db-integrity-p2d-community-foreign-keys.sql`
- `docs/db-integrity-p2d-community-foreign-keys-acceptance.md`

## Automated Verification
- `mvn -Dtest=PetPalServerMvcTest#dbIntegrityP2dRejectsCommunityOrphanReferences test`
  - Before schema constraints, failed as expected because orphan `user_follow.follower_id` was accepted.
  - After schema constraints, passed with `Tests run: 1, Failures: 0, Errors: 0, Skipped: 0`.
- `.\scripts\test-backend.ps1`
  - Result: passed, `Tests run: 60, Failures: 0, Errors: 0, Skipped: 0`.

## Live DB Read-Only Pre-Check
- Connection source: `petpal-server/src/main/resources/application.yml`
  - `jdbc:mysql://localhost:3306/petpal`
  - user `root`
- Result counts before ALTER:
  - `user_follow_follower = 0`
  - `user_follow_following = 0`
  - `post_user = 0`
  - `post_image_post = 0`
  - `post_like_post = 0`
  - `post_like_user = 0`
  - `comment_post = 0`
  - `comment_parent = 0`
  - `comment_user = 0`
- Existing P2d FK constraint check returned 0 rows before ALTER.

## Live DB Execution Result
- Executed as table-grouped ALTER statements:
  - `ALTER TABLE user_follow ADD CONSTRAINT fk_user_follow_follower ..., ADD CONSTRAINT fk_user_follow_following ...`
  - `ALTER TABLE post ADD CONSTRAINT fk_post_user ...`
  - `ALTER TABLE post_image ADD CONSTRAINT fk_post_image_post ...`
  - `ALTER TABLE post_like ADD CONSTRAINT fk_post_like_post ..., ADD CONSTRAINT fk_post_like_user ...`
  - `ALTER TABLE comment ADD CONSTRAINT fk_comment_post ..., ADD CONSTRAINT fk_comment_parent ..., ADD CONSTRAINT fk_comment_user ...`
- Constraint existence check passed for:
  - `fk_user_follow_follower`
  - `fk_user_follow_following`
  - `fk_post_user`
  - `fk_post_image_post`
  - `fk_post_like_post`
  - `fk_post_like_user`
  - `fk_comment_post`
  - `fk_comment_parent`
  - `fk_comment_user`
- Post-ALTER orphan counts remained clean:
  - `user_follow_follower = 0`
  - `user_follow_following = 0`
  - `post_user = 0`
  - `post_image_post = 0`
  - `post_like_post = 0`
  - `post_like_user = 0`
  - `comment_post = 0`
  - `comment_parent = 0`
  - `comment_user = 0`

## Live Smoke
- Direct orphan `user_follow.follower_id` insert was rejected by `fk_user_follow_follower` with `ERROR 1452`.
- Direct orphan `user_follow.following_id` insert was rejected by `fk_user_follow_following` with `ERROR 1452`.
- Direct orphan `post.user_id` insert was rejected by `fk_post_user` with `ERROR 1452`.
- Direct orphan `post_image.post_id` insert was rejected by `fk_post_image_post` with `ERROR 1452`.
- Direct orphan `post_like.post_id` insert was rejected by `fk_post_like_post` with `ERROR 1452`.
- Direct orphan `post_like.user_id` insert was rejected by `fk_post_like_user` with `ERROR 1452`.
- Direct orphan `comment.post_id` insert was rejected by `fk_comment_post` with `ERROR 1452`.
- Direct orphan `comment.parent_id` insert was rejected by `fk_comment_parent` with `ERROR 1452`.
- Direct orphan `comment.user_id` insert was rejected by `fk_comment_user` with `ERROR 1452`.
- `POST /api/user/login`: response code `OK`.
- `GET /api/post/feed`: response code `OK`, current post count `7`.
- `GET /api/post/1`: response code `OK`, returned id `1`.
- `GET /api/post/1/comment`: response code `OK`, current comment count `2`.

## Known Risks
- New databases created from `schema.sql` will enforce these nine foreign keys immediately.
- Existing databases still need the manual ALTER in `scripts/db-integrity-p2d-community-foreign-keys.sql`.
- These FKs use default restrict/no-action behavior; application soft-delete rules still own lifecycle behavior.
- This slice intentionally leaves `service_review` and remaining enum/range checks to later P2 slices.
- Verified local MySQL version is `8.0.40`.

## Suggested Commit Message
`fix: add community db foreign keys`
