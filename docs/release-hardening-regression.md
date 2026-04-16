# Release Hardening Regression Gate

This document records the release-hardening verification for the Community P0 sealed baseline.

## Status

- Status: blocked
- Date: 2026-04-16
- Branch: `codex/fix/release-hardening`
- Baseline tag: `community-p0-code-sealed`
- Final conclusion: release-hardening is not sealed yet.
- Blocker: final phone/device regression must be repeated from a clean committed `codex/fix/release-hardening` branch. The current workspace still contains unrelated dirty files that are intentionally excluded from this release-hardening commit.

## Hardening Scope Verified By Automated Checks

- BCrypt-only login path:
  - Seed/test accounts store BCrypt hashes for `123456`.
  - Plaintext stored password is rejected.
  - Wrong password is rejected.
- Token type enforcement:
  - Login response shape remains unchanged.
  - Protected phone APIs accept access tokens.
  - Refresh tokens used as access tokens return `401 UNAUTHORIZED`.
- Upload and error matrix:
  - Missing upload file returns `400 FILE_REQUIRED`.
  - Non-image upload returns `400 INVALID_FILE_TYPE`.
  - Oversized upload returns `400 FILE_TOO_LARGE`.
  - Multipart size limit maps to `400 FILE_TOO_LARGE`.
  - Malformed JSON maps to `400 BAD_REQUEST` with `Invalid request body`.
  - Parameter type mismatch maps to `400 BAD_REQUEST` with `Invalid request parameter`.
  - Storage failure maps to `500 FILE_UPLOAD_FAILED`.
  - Missing file object maps to `404 FILE_NOT_FOUND`.
- Existing MVP backend rules:
  - Auth success/failure.
  - Appointment creation/list/cancel/admin transitions.
  - Pet Archive P0 create/update/delete/health/vaccine rules.
  - Community P0 create/feed/detail/like/unlike/comment/delete/upload rules.

## Commands Run

Backend:

```powershell
.\scripts\test-backend.ps1
```

Result:

```text
Tests run: 41, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

Phone build:

```powershell
hvigorw.js --mode module -p module=entry@default -p product=default assembleHap --no-daemon --no-parallel --no-incremental --analyze=false
```

Result:

```text
BUILD SUCCESSFUL in 6 s 620 ms
```

Observed warnings:

- ArkTS warnings in `Index.ets` about functions that may throw.
- Deprecated `showToast` warning in `PetDetail.ets`.
- HAP signing skipped because no signing config is configured.

## Final Regression Execution Checklist

Before starting manual regression, confirm the branch is clean:

```powershell
git switch codex/fix/release-hardening
git status --short
```

If the persistent local database still contains plaintext seed passwords, run this reset SQL before login:

```sql
UPDATE user
SET password = '$2a$10$Trga2O1gLdnL6g8mvggVK.kdQdkQkkcEQ8AWzaS1oTD.t4eZLKfzi'
WHERE phone IN ('13800000001', '13800000002');
```

### Login

- Start dependencies and backend.
- Set the phone app API base URL to the development machine LAN IP, not `127.0.0.1`.
- Log in with `13800000001 / 123456`.
- Verify wrong password stays on login and shows an error.
- Verify an expired/invalid session returns to login instead of silently falling back to mock data.

### Appointment P0

- Open provider list and provider detail from backend data.
- Create a future appointment for an owned pet and valid provider service.
- Verify the created appointment appears in the current user's appointment list.
- Cancel a cancellable appointment from the phone.
- Use admin to confirm and complete an appointment.
- Refresh the phone appointment list and verify status changes are visible.

### Pet Archive P0

- Create a pet profile and verify it appears in the phone pet list.
- Partially update only selected fields and verify omitted fields are preserved.
- Soft delete a separate pet and verify it disappears from the list.
- Add a health record and verify list ordering.
- Add a vaccine record and verify list ordering.
- Verify deleted/non-owned pet access shows the not-found/error state.

### Community P0

- Publish a post with one uploaded image.
- Verify the upload returns a backend proxy URL under `/api/file/object/{fileKey}`.
- Verify feed and detail render the uploaded image.
- Like and unlike the post and verify backend state refreshes `liked` and `likeCount`.
- Add a root comment and verify it appears in comment list order.
- Delete the author's post.
- Verify feed, detail, and comment list no longer expose the deleted post.
- Verify at least one upload failure, such as non-image or oversized upload, shows the stable backend message.

## Manual Regression Still Required

Run from a clean committed `codex/fix/release-hardening` branch with no unrelated local changes:

1. Start MySQL, Redis, MinIO, and backend.
2. If the persistent local database predates release hardening, reset known seed account hashes:

```sql
UPDATE user
SET password = '$2a$10$Trga2O1gLdnL6g8mvggVK.kdQdkQkkcEQ8AWzaS1oTD.t4eZLKfzi'
WHERE phone IN ('13800000001', '13800000002');
```

3. Set the phone app backend URL to the development machine LAN IP.
4. Verify login with `13800000001 / 123456`.
5. Verify appointment create, list, cancel, admin confirm/complete, and phone refresh.
6. Verify Pet Archive P0 create, partial update, soft delete, add/list health record, and add/list vaccine record.
7. Verify Community P0 publish with uploaded image, feed/detail image render, like, unlike, root comment create/list, author delete, and deleted post not found.
8. Verify upload failure display for at least one stable backend error, such as non-image upload or oversized upload.

## Risks And Follow-Ups

- Refresh-token rotation remains intentionally out of scope; auth failure requires re-login.
- Existing persistent development databases are not automatically migrated. Known seed/test users must be reset manually if they still contain plaintext passwords.
- Final release gate cannot be called sealed until the manual regression above is executed on a clean branch.
- Phone repository tests exist under `Cutepetpost/entry/src/test`, but this project still has no known runnable local Hvigor unit-test task for them.

Suggested commit message:

```text
fix: harden release auth and upload errors
```
