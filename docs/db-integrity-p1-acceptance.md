# DB Integrity P1 Acceptance

## Status
Code baseline and live DB P1 maintenance completed on 2026-04-28 against local MySQL `petpal`.
- Backup created at `_tmp_db_backup/petpal-live-before-db-integrity-p1-20260428-221431.sql`.
- Live `ALTER TABLE` was executed successfully.
- Post-checks and minimal DB/API smoke passed.
- Phone-side manual verification passed.

## Scope
- Add three low-risk business uniqueness/check baselines in `schema.sql`.
- Add direct-write backend tests that prove the database rejects invalid rows.
- Add a manual SQL script for future live DB execution and rollback.
- Record verification and the fact that live DB handling stopped at read-only pre-check.

## Explicit Non-Scope
- No phone-client changes.
- No admin changes.
- No new API endpoints.
- No P2 or P3 integrity work.
- No ordinary foreign keys.
- No `updated_at` changes.
- No enum, boolean, or broad range checks outside the accepted P1 rules.

## Files
- `petpal-server/src/main/resources/db/schema.sql`
- `petpal-server/src/test/java/com/petpal/server/PetPalServerMvcTest.java`
- `scripts/db-integrity-p1-business-uniques.sql`
- `docs/db-integrity-p1-acceptance.md`

## Automated Verification
- `mvn -Dtest=PetPalServerMvcTest#dbIntegrityP1* test`
  - Result: passed, `Tests run: 6, Failures: 0, Errors: 0, Skipped: 0`.
- `.\scripts\test-backend.ps1`
  - Result: passed, `Tests run: 56, Failures: 0, Errors: 0, Skipped: 0`.

## Live DB Read-Only Pre-Check
- Connection source: `petpal-server/src/main/resources/application.yml`
  - `jdbc:mysql://localhost:3306/petpal`
  - user `root`
- Result counts:
  - `user_follow_duplicate_pairs = 0`
  - `user_follow_self_rows = 0`
  - `post_image_duplicate_sort_rows = 0`
  - `post_image_negative_sort_rows = 0`
  - `service_item_active_name_duplicates = 0`
  - `existing_p1_constraints = 0`
  - `existing_active_name_guard_column = 0`

## Live DB Execution Result
- Executed:
  - `ALTER TABLE user_follow ADD UNIQUE KEY uk_user_follow_pair (follower_id, following_id), ADD CONSTRAINT chk_user_follow_not_self CHECK (follower_id <> following_id)`
  - `ALTER TABLE post_image ADD UNIQUE KEY uk_post_image_sort (post_id, sort_order), ADD CONSTRAINT chk_post_image_sort_non_negative CHECK (sort_order >= 0)`
  - `ALTER TABLE service_item ADD COLUMN active_name_guard ... , ADD UNIQUE KEY uk_service_item_active_name (provider_id, name, active_name_guard)`
- Constraint existence check passed for:
  - `uk_user_follow_pair`
  - `chk_user_follow_not_self`
  - `uk_post_image_sort`
  - `chk_post_image_sort_non_negative`
  - `uk_service_item_active_name`
  - `service_item.active_name_guard`
- Post-ALTER duplicate/invalid-row counts remained clean:
  - `user_follow_duplicate_pairs = 0`
  - `user_follow_self_rows = 0`
  - `post_image_duplicate_sort_rows = 0`
  - `post_image_negative_sort_rows = 0`
  - `service_item_active_name_duplicates = 0`

## Live Smoke
- Direct duplicate `user_follow(follower_id, following_id)` insert is rejected by `uk_user_follow_pair`.
- Direct self-follow insert is rejected by `chk_user_follow_not_self`.
- Direct duplicate `post_image(post_id, sort_order)` insert is rejected by `uk_post_image_sort`.
- Direct negative `post_image.sort_order` insert is rejected by `chk_post_image_sort_non_negative`.
- Direct duplicate active `service_item(provider_id, name)` insert is rejected by `uk_service_item_active_name`.
- Deleted same-name `service_item` was inserted inside a transaction successfully, observed as `total_count = 2` and `deleted_count = 1`, then rolled back; post-rollback counts returned to `total_count = 1`, `deleted_count = 0`.
- `GET /api/provider/list`: `200`, response code `OK`, current provider count `3`.
- `POST /api/user/login`: `200`, response code `OK`, profile id `1`.
- `GET /api/appointment/list`: `200`, response code `OK`, current appointment count `13`.

## Phone-Side Manual Verification
- Date: 2026-04-28.
- Device target: HarmonyOS emulator `127.0.0.1:5555`.
- User state: already logged in as phone user `小满`.
- Home tab: opened successfully, login state visible, pet/appointment summary rendered, and provider statistic showed `照护机构 3`.
- Appointment tab: current-user appointment list rendered with `已完成`, `待确认`, and `已取消` statuses.
- Provider list: appointment tab rendered 3 providers, matching backend provider count `3`.
- Provider detail: opened `云朵宠物医院`; service items `基础问诊` and `疫苗接种` rendered.
- Mine tab: current user profile, pet count, next reminder, and pet archive card rendered.
- Community tab: feed rendered with post content, image, like/comment controls, and detail/delete actions.
- Automation logs were updated under `Cutepetpost/midscene_run/log/`; temporary screenshot files were generated under `C:\Users\Public\AppData\Local\Temp`.

## Known Risks
- New databases created from `schema.sql` now enforce these rules, but existing databases still need a manual ALTER or a future migration mechanism.
- `post_image` keeps both the old non-unique index and the new unique key on the same column pair because this slice stayed aligned with the accepted minimum-change plan.
- This slice only covers the three approved P1 rules; other direct-write integrity gaps remain future work.
- Provider detail header currently shows `评分 -` and `营业 -` even though `GET /api/provider/1` returns `rating = 4.8` and `businessHours = 09:00-20:00`; this is a phone-side display follow-up, not a DB P1 constraint failure.

## Suggested Commit Message
`fix: add p1 business uniqueness db guards`
