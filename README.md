# PetPal

[English](README.md) | [简体中文](README.zh-CN.md)

PetPal is a phone-first MVP workspace centered on the HarmonyOS client. This repository contains the phone app, the Spring Boot backend, a minimal admin page for appointment fulfillment, and the local development infrastructure used by the current MVP.

## Current Status

- Appointment main flow has passed real-device acceptance: login, browse providers and services, create an appointment, view my appointments, update status from admin, and refresh on phone.
- Pet Archive P0 has passed real-device acceptance: create pet, partial update, soft delete, add health records, view health records, add vaccine records, and view vaccine records.
- Community P0 is sealed for the current scope: publish posts with uploaded images, like or unlike posts, add root comments, and delete your own posts.
- Database integrity hardening is aligned through P2g and recorded as a closure candidate, not a sealed final state.

Primary references:

- [docs/phone-mvp.md](docs/phone-mvp.md)
- [docs/mvp-acceptance.md](docs/mvp-acceptance.md)
- [docs/pet-archive-p0-device-acceptance.md](docs/pet-archive-p0-device-acceptance.md)
- [docs/community-p0-device-acceptance.md](docs/community-p0-device-acceptance.md)
- [docs/db-integrity-p2-closure-candidate.md](docs/db-integrity-p2-closure-candidate.md)

## Workspace Layout

- `Cutepetpost`: HarmonyOS phone client and the main product surface.
- `petpal-server`: Spring Boot backend for auth, provider, appointment, pet archive, community, and file upload APIs.
- `petpal-admin`: static admin page for provider and appointment operations needed by the phone MVP.
- `deploy`: local infrastructure definitions for Redis and MinIO.
- `docs`: MVP slices, acceptance records, architecture notes, and supporting decisions.
- `scripts`: repeatable PowerShell commands for local development and verification.

## MVP Scope In This Repo

Current accepted phone-first scope:

1. Password login
2. Browse providers and services
3. Create an appointment
4. View current-user appointments
5. Cancel an appointment when allowed
6. Update appointment status from admin
7. Pet Archive P0
8. Community P0

Intentionally not part of the current accepted MVP unless a new slice says otherwise:

- search
- map features
- notifications
- reviews
- SMS login
- third-party login
- multi-device collaboration

## Local Development

Start local dependencies:

```powershell
.\scripts\dev-deps-up.ps1
```

This starts Redis and MinIO only. MySQL is expected to run on the host machine:

```text
host: localhost
port: 3306
database: petpal
user: root
password: 54321
```

For a fresh local database, apply:

1. `petpal-server/src/main/resources/db/schema.sql`
2. `petpal-server/src/main/resources/db/seed.sql`

If a local `petpal` database already exists, inspect it before applying SQL so you do not wipe useful development data by accident.

Run backend tests:

```powershell
.\scripts\test-backend.ps1
```

Run the backend:

```powershell
.\scripts\run-backend.ps1
```

Backend defaults from `application.yml`:

- HTTP port: `18080`
- Redis: `localhost:6379`
- MinIO API: `http://localhost:9000`
- MinIO console: `http://localhost:9001`
- Admin token: `petpal-admin-token-change-me`

Open `Cutepetpost` in DevEco Studio to build and run the phone app.

## Phone Debugging Notes

- Use the development machine LAN IP in `Cutepetpost/entry/src/main/ets/config/PetPalAppConfig.ets`.
- Do not use `127.0.0.1` from a physical phone.
- Keep the backend, phone app, and admin page on the same backend HTTP port.
- On this Windows setup, `18080` is the practical default. Avoid relying on `8080` or other `8000-8099` ports.

Current config example:

```typescript
export const PETPAL_DEV_SERVER_ORIGIN: string = 'http://192.168.1.3:18080';
export const PETPAL_SERVER_ORIGIN: string = PETPAL_DEV_SERVER_ORIGIN;
export const PETPAL_API_BASE_URL: string = `${PETPAL_SERVER_ORIGIN}/api`;
```

Test account:

```text
phone: 13800000001
password: 123456
```

Admin page usage:

1. Open `petpal-admin/index.html` in a browser on the development machine.
2. Set API base URL to the same backend port, for example `http://127.0.0.1:18080`.
3. Use the default admin token `petpal-admin-token-change-me`.

If the admin page shows `failed to fetch`, check CORS and preflight handling first, especially `OPTIONS /**` and the `X-PetPal-Admin-Token` header.

## Implementation Notes

- Authentication is BCrypt-only for stored passwords.
- Protected APIs accept access JWTs only. Refresh JWTs are not valid access tokens.
- Community image uploads use `POST /api/file/upload` with multipart field `file`.
- Upload size is limited to 5 MB.
- Returned image URLs must stay on backend proxy paths such as `/api/file/object/{fileKey}`.

## Recommended Reading Order

1. [docs/phone-mvp.md](docs/phone-mvp.md)
2. the accepted slice or acceptance doc you are touching
3. the directly affected module code only

That matches the repository working rules in [AGENTS.md](AGENTS.md).
