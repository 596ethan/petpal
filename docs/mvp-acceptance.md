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

## Not Implemented

- No settings screen for API base URL.
- No refresh-token rotation.
- No push or message notification for appointment status changes.
- No full community production fallback removal; community remains outside the current appointment MVP path.
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

## Phone Device Debugging

Backend startup:

```powershell
.\scripts\dev-deps-up.ps1
.\scripts\run-backend.ps1
```

The accepted test run used backend port `19080`. If local Windows reserves the `8000-8099` port range or another process blocks `8080`, start the backend on `19080` and point the clients to that port.

If local `MySQL80` already uses port `3306`, the accepted test run used a Docker MySQL container mapped to host port `3307`; the backend still exposed HTTP on `19080`.

Phone base URL:

Edit `Cutepetpost/entry/src/main/ets/config/PetPalAppConfig.ets`:

```typescript
export const PETPAL_API_DEV_BASE_URL: string = 'http://192.168.1.3:19080/api';
export const PETPAL_API_BASE_URL: string = PETPAL_API_DEV_BASE_URL;
```

Use the development machine's LAN IP for phone testing. Do not use `127.0.0.1` from a physical phone.

Admin client:

- Open `petpal-admin/index.html` in the development machine browser.
- Do not open the backend root URL directly as the admin page.
- In the admin page, set API base URL to `http://127.0.0.1:19080`.
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

## Acceptance Conclusion

The main chain passed real-device acceptance:

Phone login -> view providers/services -> create appointment -> my appointments visible -> admin updates status -> phone refresh shows status change.

The Phone MVP is accepted for the current scope.

## Known Limits

- Phone Repository tests are present under `Cutepetpost/entry/src/test`, but no runnable local Hvigor test task is available in this project.
- Physical-device networking depends on the phone and development machine being on the same LAN, firewall access, and a stable development machine IP.
- The phone app does not receive appointment status push updates; the user must refresh or re-enter the page.
- The admin client is a local static HTML console, not a backend root-path page.
- Community production fallback cleanup remains outside the accepted appointment MVP path.

## Release Notes

Suggested git commit message:

```text
docs: record phone mvp acceptance
```

Suggested version tag:

```text
v0.1.0-phone-mvp-accepted
```
