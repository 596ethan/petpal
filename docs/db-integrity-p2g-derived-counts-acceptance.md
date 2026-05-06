# DB Integrity P2g Derived Counts Acceptance

## Status

- Backup created at `_tmp_db_backup/petpal-live-before-db-integrity-p2g-derived-counts-20260506-144249.sql`.
- Live `post.like_count` and `post.comment_count` repair was executed successfully.
- Post-repair drift check returned `post_derived_count_drift = 0`.
- Minimal API smoke passed against the local backend on port `18080`.

## Scope

- Repair stored community post counters from their source tables.
- Keep `post.like_count` aligned with `COUNT(post_like)`.
- Keep `post.comment_count` aligned with root comments only: `COUNT(comment WHERE parent_id IS NULL)`.
- Add a regression test that blocks future seed or write-path drift.

Out of scope:

- No new CHECK, FK, UNIQUE, trigger, generated column, or DDL.
- No phone client, admin, REST API, or business rule changes.
- No `service_review` constraints.
- No `user.status`, `post.status`, or `service_provider.status` checks.

## Changed Files

- `petpal-server/src/main/resources/db/seed.sql`
- `petpal-server/src/test/java/com/petpal/server/PetPalServerMvcTest.java`
- `scripts/db-integrity-p2g-derived-counts.sql`
- `docs/db-integrity-p2g-derived-counts-acceptance.md`
- `docs/db-integrity-p2-summary-review.md`

## Automated Verification

- `mvn -Dtest=PetPalServerMvcTest#dbIntegrityP2gPostDerivedCountsMatchActualLikesAndRootComments test`
  - Before seed repair, failed as expected with `expected: 0L but was: 2L`.
  - After seed repair, passed with `Tests run: 1, Failures: 0, Errors: 0, Skipped: 0`.
- `mvn -Dtest=PetPalServerMvcTest#likeAndUnlikeAreIdempotent test`
  - Result: passed, `Tests run: 1, Failures: 0, Errors: 0, Skipped: 0`.
- `.\scripts\test-backend.ps1`
  - Result: passed, `Tests run: 63, Failures: 0, Errors: 0, Skipped: 0`.

## Live DB Pre-Repair Check

Command:

```powershell
$env:MYSQL_PWD='54321'; mysql -uroot petpal --batch --raw --execute="source scripts/db-integrity-p2g-derived-counts.sql"
```

Pre-repair drift rows:

| post id | stored like | actual like | stored root comments | actual root comments |
| --- | ---: | ---: | ---: | ---: |
| `1` | `23` | `0` | `2` | `2` |
| `2` | `57` | `1` | `2` | `2` |

## Live Repair Result

The maintenance script repaired all mismatched post counters by recalculating from `post_like` and root `comment` rows.

Post-repair check:

| post id | stored like | actual like | stored root comments | actual root comments |
| --- | ---: | ---: | ---: | ---: |
| `1` | `0` | `0` | `2` | `2` |
| `2` | `1` | `1` | `2` | `2` |

Final drift count:

- `post_derived_count_drift = 0`

## API Smoke

Backend was started temporarily on `http://127.0.0.1:18080` and stopped after smoke verification.

- `POST /api/user/login`
  - Result: `200`, response code `OK`.
- `GET /api/post/1`
  - Result: `likeCount = 0`, `commentCount = 2`.
- `GET /api/post/2`
  - Result: `likeCount = 1`, `commentCount = 2`.

## Known Risks

- This repairs existing stored counters but does not add triggers. The application write path remains responsible for maintaining counters.
- If future direct DB writes bypass `CommunityMutationService`, counters can drift again; rerun `scripts/db-integrity-p2g-derived-counts.sql` as an audit/repair tool.
- `comment_count` intentionally counts root comments only, matching the current Community P0 API.

## Suggested Commit Message

`fix: repair post derived counts`
