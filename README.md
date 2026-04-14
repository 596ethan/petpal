# PetPal

PetPal is a phone-first MVP workspace for the HarmonyOS client, backend APIs, and a small admin surface required to fulfill phone appointments.

## Workspace
- `Cutepetpost`: HarmonyOS phone client and current primary deliverable.
- `petpal-server`: Spring Boot backend for authentication, provider, pet, and appointment APIs.
- `petpal-admin`: lightweight admin UI for appointment status operations required by the phone MVP.
- `deploy`: local infrastructure for MySQL, Redis, and MinIO.
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

## Accepted Scope
- Phone appointment main chain has passed real-device acceptance.
- Pet Archive P0 has passed real-device acceptance for create, partial update, soft delete, add health record, view health record list, and add vaccine record.
- Detailed acceptance records are in `docs/mvp-acceptance.md` and `docs/pet-archive-p0-device-acceptance.md`.

## Local Commands
Start local dependencies:

```powershell
.\scripts\dev-deps-up.ps1
```

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

5. If local `MySQL80` already uses port `3306`, run the project MySQL container on another host port such as `3307`, then start the backend with a datasource URL pointing at that database port. This is independent from the backend HTTP port.

6. If the admin page shows `failed to fetch` while command-line admin API requests work, check CORS/preflight handling. The backend must allow `OPTIONS /**` and the `X-PetPal-Admin-Token` header.

Default test account:

```text
phone: 13800000001
password: 123456
```

## Development Rule
Before each substantive feature slice, update the concrete slice spec in `docs/phone-mvp.md` with the user goal, entry screen, API contract, success state, failure state, and test cases.
