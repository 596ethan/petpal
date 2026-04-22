# PetPal

PetPal is a phone-first MVP workspace for the HarmonyOS client, backend APIs, and a small admin surface required to fulfill phone appointments.

## Workspace
- `Cutepetpost`: HarmonyOS phone client and current primary deliverable.
- `petpal-server`: Spring Boot backend for authentication, provider, pet, and appointment APIs.
- `petpal-admin`: lightweight admin UI for appointment status operations required by the phone MVP.
- `deploy`: local infrastructure for Redis and MinIO. The default development database is a local MySQL service on the host.
- `docs`: architecture notes, slice specs, and API contracts.
- `scripts`: repeatable local development commands.

## Current MVP Chain
1. Password login
2. View profile
3. View pets
4. View providers and services
5. Create appointment
6. View my appointments
7. Cancel appointment when allowed
8. Admin confirms/completes appointment so the phone client reflects real status
9. Community P0: publish posts with uploaded images, like/unlike, add root comments, and delete own posts

## Accepted Scope
- Phone appointment main chain has passed real-device acceptance.
- Pet Archive P0 has passed real-device acceptance for create, partial update, soft delete, add health record, view health record list, and add vaccine record.
- Community P0 has passed code-freeze and image-proxy device acceptance under the `community-p0-code-sealed` / `community-p0-sealed` tags.
- Detailed acceptance records are in `docs/mvp-acceptance.md`, `docs/pet-archive-p0-device-acceptance.md`, and `docs/community-p0-device-acceptance.md`.

## Local Commands
Start local dependencies:

```powershell
.\scripts\dev-deps-up.ps1
```

This starts Redis and MinIO only. Start or verify local MySQL separately:

```text
host: localhost
port: 3306
database: petpal
user: root
password: 54321
```

Initialize a fresh local database with `petpal-server/src/main/resources/db/schema.sql` and `petpal-server/src/main/resources/db/seed.sql`. If a `petpal` database already exists, inspect it before applying SQL so existing local data is not accidentally dropped.

Run backend tests:

```powershell
.\scripts\test-backend.ps1
```

Run the backend app:

```powershell
.\scripts\run-backend.ps1
```

Open `Cutepetpost` in DevEco Studio for phone preview/build.

## Phone Device Debugging
For phone-device testing, the HarmonyOS app must call the backend through the development machine's LAN IP, not `127.0.0.1`.

The full acceptance records are in `docs/mvp-acceptance.md` and `docs/pet-archive-p0-device-acceptance.md`.

1. Start local dependencies and the backend. Use any available backend HTTP port, but keep the backend, phone app, and admin page on the same port. The appointment MVP accepted run used `19080`; the Pet Archive P0 accepted run used `18080` because this Windows environment reserves the `8000-8099` TCP range, including `8080`.

```powershell
.\scripts\dev-deps-up.ps1
.\scripts\run-backend.ps1
```

2. Find the development machine's LAN IP and update `PETPAL_API_DEV_BASE_URL` in `Cutepetpost/entry/src/main/ets/config/PetPalAppConfig.ets`, for example:

```typescript
export const PETPAL_API_DEV_BASE_URL: string = 'http://192.168.1.3:<backend-port>/api';
```

3. Keep `PETPAL_API_BASE_URL` pointing at `PETPAL_API_DEV_BASE_URL` for local phone testing.

4. Open `petpal-admin/index.html` in the development machine browser. Set API base URL to the same backend port, for example `http://127.0.0.1:18080`, and admin token to `petpal-admin-token-change-me`.

5. The backend uses the host MySQL service at `localhost:3306` with `root/54321` by default. Docker MySQL is no longer the default path; `.\scripts\dev-deps-up.ps1` only starts Redis and MinIO. If `petpal` does not exist, initialize it with `schema.sql` and `seed.sql` after checking that you are not overwriting useful local data.

6. If the admin page shows `failed to fetch` while command-line admin API requests work, check CORS/preflight handling. The backend must allow `OPTIONS /**` and the `X-PetPal-Admin-Token` header.

Default test account:

```text
phone: 13800000001
password: 123456
```

## Release-Hardening Notes

Authentication is BCrypt-only. Seed and test fixture accounts store BCrypt hashes for the known development password `123456`; plaintext password compatibility is intentionally disabled.

Old data strategy for this release:
- Only built-in/test seed users and known local development accounts are reset to BCrypt.
- No online "first login upgrades plaintext password" flow is implemented.
- If a persistent local database still has plaintext test users, reset the known accounts instead of adding compatibility code:

```sql
UPDATE user
SET password = '$2a$10$Trga2O1gLdnL6g8mvggVK.kdQdkQkkcEQ8AWzaS1oTD.t4eZLKfzi'
WHERE phone IN ('13800000001', '13800000002');
```

JWT refresh-token rotation is not implemented in this MVP. Protected APIs accept only `type=access` JWTs; using a refresh token as an access token returns `401 UNAUTHORIZED`. The phone client should clear session state and require login again on `401`/`403`.

Upload hardening:
- `/api/file/upload` accepts multipart field `file` only.
- Image uploads are limited to 5MB.
- Stable upload error codes are `FILE_REQUIRED`, `INVALID_FILE_TYPE`, `FILE_TOO_LARGE`, `FILE_UPLOAD_FAILED`, and `FILE_NOT_FOUND`.
- Returned image URLs must use backend image proxy paths such as `/api/file/object/{fileKey}`; the phone must not depend on public MinIO object URLs.

## Development Rule
Before each substantive feature slice, update the concrete slice spec in `docs/phone-mvp.md` with the user goal, entry screen, API contract, success state, failure state, and test cases.
