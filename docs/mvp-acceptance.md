# PetPal Phone MVP Acceptance

This document records the current implementation only.

## Implemented

- Phone login uses `POST /api/user/login`.
- Phone provider list, provider detail, and service list use backend provider APIs.
- Phone appointment creation submits ISO 8601 local datetime strings.
- Phone "my appointments" uses `GET /api/appointment/list`.
- Phone appointment cancellation uses `PUT /api/appointment/{id}/cancel`.
- Admin appointment status updates use `PUT /admin/appointments/{id}/status`.
- Admin auth accepts `X-PetPal-Admin-Token` and `Authorization: Bearer <token>`.
- Core phone appointment flow no longer silently falls back to local mock data on provider, service, profile, pet, appointment, or appointment-create failure.
- Community P0 uses real backend APIs for post create/delete, image upload, feed/detail reads, like/unlike, root comment create, and comment list.
- Uploaded community images are served through backend proxy URLs under `/api/file/object/{fileKey}`.
- Authentication is BCrypt-only for stored passwords. Plaintext stored passwords are rejected.
- Protected phone APIs accept only access JWTs; refresh JWTs cannot be used as access tokens.

## Not Implemented

- No settings screen for API base URL.
- No refresh-token rotation.
- No push or message notification for appointment status changes.
- No automated phone test execution task is exposed by the current Hvigor project.

## Real Acceptance Result

Phone MVP main chain acceptance has passed on a real device:

| Checkpoint | Result |
|---|---|
| Phone login | Passed |
| View providers and services | Passed |
| Create appointment | Passed |
| My appointments visible | Passed |
| Admin updates appointment status | Passed |
| Phone refresh shows status change | Passed |

Pet Archive P0 acceptance has also passed on a real device:

| Checkpoint | Result |
|---|---|
| Create pet | Passed |
| Partial update pet | Passed |
| Soft delete pet | Passed |
| Add health record | Passed |
| View health record list | Passed |
| Add vaccine record | Passed |

The detailed Pet Archive P0 acceptance record is in `docs/pet-archive-p0-device-acceptance.md`.

Community P0 acceptance has passed code-freeze, backend tests, HAP build, API image proxy smoke testing, and device image proxy re-verification:

| Checkpoint | Result |
|---|---|
| Backend Community P0 tests | Passed |
| HAP build | Passed |
| Image upload returns backend proxy URL | Passed |
| Feed/detail render uploaded backend image URL | Passed |
| Like/unlike backend state | Passed |
| Root comment create/list | Passed |
| Author delete hides post from feed/detail/comment reads | Passed |

The detailed Community P0 acceptance record is in `docs/community-p0-device-acceptance.md`.

## Phone Device Debugging

Backend startup:

```powershell
.\scripts\dev-deps-up.ps1
.\scripts\run-backend.ps1
```

The appointment MVP accepted test run used backend port `19080`. The Pet Archive P0 accepted test run used backend port `18080` because this Windows environment reserves the `8000-8099` TCP range, including `8080`. Any available backend port is acceptable for local acceptance as long as the phone app and admin page point to the same running backend port.

If local `MySQL80` already uses port `3306`, run the project MySQL container on another host port such as `3307`; this database port is independent from the backend HTTP port.

Known development login accounts now require BCrypt hashes in the database. If an existing persistent local database still has plaintext `123456` for the seed users, reset them to the release-hardening hash:

```sql
UPDATE user
SET password = '$2a$10$Trga2O1gLdnL6g8mvggVK.kdQdkQkkcEQ8AWzaS1oTD.t4eZLKfzi'
WHERE phone IN ('13800000001', '13800000002');
```

Do not add online plaintext-to-BCrypt migration logic for this MVP release. Historical plaintext development accounts are test data and should be reset.

Phone base URL:

Edit `Cutepetpost/entry/src/main/ets/config/PetPalAppConfig.ets`:

```typescript
export const PETPAL_API_DEV_BASE_URL: string = 'http://192.168.1.3:<backend-port>/api';
export const PETPAL_API_BASE_URL: string = PETPAL_API_DEV_BASE_URL;
```

Use the development machine's LAN IP for phone testing. Do not use `127.0.0.1` from a physical phone.

Admin client:

- Open `petpal-admin/index.html` in the development machine browser.
- Do not open the backend root URL directly as the admin page.
- In the admin page, set API base URL to the same running backend port, for example `http://127.0.0.1:18080`.
- Default token: `petpal-admin-token-change-me`

## CORS Debugging

The local static admin page sends browser requests with `X-PetPal-Admin-Token`, so the backend must allow browser preflight requests:

- `OPTIONS /**` is permitted.
- Allowed headers include `Content-Type`, `Authorization`, and `X-PetPal-Admin-Token`.
- If the admin page shows `failed to fetch` while command-line requests with the token work, check the CORS/preflight handling first.

Test account:

```text
phone: 13800000001
password: 123456
```

Seed data:

- Provider: `Cloud Vet Center`
- Pet: `Nuomi`
- Existing appointment: `PP202603260001`

## Manual Checklist

1. Start dependencies and backend.
2. Set `PETPAL_API_DEV_BASE_URL` to the development machine LAN IP.
3. Build and run the HarmonyOS phone app.
4. Log in with `13800000001` / `123456`.
5. Confirm provider list loads from backend data.
6. Open `Cloud Vet Center`.
7. Confirm service list loads from backend data.
8. Submit a future appointment time such as `2099-01-02T10:00:00`.
9. Confirm the app shows the created order number.
10. Return to "my appointments" and confirm the new appointment is visible.
11. Open admin and set the new appointment status to `CONFIRMED`.
12. Refresh the phone appointment list and confirm status changes to confirmed.
13. Open admin and set the appointment status to `COMPLETED`.
14. Refresh the phone appointment list and confirm status changes to completed.
15. Open Community, publish a post with an uploaded image, and confirm the image renders in feed and detail.
16. Like, unlike, add a root comment, then delete the post.
17. Confirm the deleted post is absent from feed and detail/comment reads return not found.

## Acceptance Conclusion

The appointment main chain passed real-device acceptance:

Phone login -> view providers/services -> create appointment -> my appointments visible -> admin updates status -> phone refresh shows status change.

The Pet Archive P0 chain also passed real-device acceptance:

Phone login -> create pet -> partial update pet -> add health record -> verify health list -> add vaccine record -> soft delete a separate pet.

The Community P0 chain also passed device image proxy re-verification:

Phone login -> upload image -> publish post -> feed image renders -> detail image renders -> delete post -> feed/detail no longer expose the post.

The Phone MVP, Pet Archive P0, and Community P0 are accepted for the current sealed scope. Release-hardening remains a separate gate recorded in `docs/release-hardening-regression.md`.

## Known Limits

- Phone Repository tests are present under `Cutepetpost/entry/src/test`, but no runnable local Hvigor test task is available in this project.
- Physical-device networking depends on the phone and development machine being on the same LAN, firewall access, and a stable development machine IP.
- The phone app does not receive appointment status push updates; the user must refresh or re-enter the page.
- The admin client is a local static HTML console, not a backend root-path page.
- Pet avatar upload, health/vaccine edit/delete, pet archive search, and admin pet management remain outside Pet Archive P0.
- Community replies, comment deletion, comment likes, post editing, search, recommendations, notifications, moderation/admin community workflows, and third-party media processing remain outside Community P0.
- Refresh-token rotation remains outside release-hardening; auth failure requires re-login.

## Release Notes

Suggested git commit message:

```text
feat: seal pet archive p0 acceptance
```

Suggested version tag:

```text
v0.2.0-pet-archive-p0-accepted
```
