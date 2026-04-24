# Appointment Time Input MVP Plan

> Plan date: 2026-04-24  
> Status: accepted  
> Target branch: `codex/fix/appointment-time-input-mvp`

## Owner

- Codex

## Entry Criteria

- Slice 3 already defines appointment creation and cancellation.
- The phone appointment page still requires users to manually type the appointment time.
- The backend does not expose real provider schedule inventory or available slots.

## Goal

Improve the phone appointment creation form without pretending to have a real schedule system.

- Replace manual time typing with date and time-slot selection.
- Treat the selected value as an appointment intent time.
- Keep the existing `POST /api/appointment` contract unchanged.
- Keep provider confirmation as the final source of truth.

## Scope

### 1. Phone time input

- Show the copy: `选择预约意向时间，最终以机构确认为准`.
- Date candidates:
  - today
  - tomorrow
  - the day after tomorrow
- Time-slot candidates:
  - `09:00`
  - `10:30`
  - `14:00`
  - `15:30`
  - `17:00`
- For today, only show slots later than current time plus 30 minutes.
- For tomorrow and the day after tomorrow, show the full slot set.
- Submit `appointmentTime` as `yyyy-MM-ddTHH:mm:00`.

### 2. Submit validation

- Keep the submit button tappable.
- Validate before calling the backend.
- Show a clear message for the first missing field:
  - missing service: `请选择服务项目`
  - missing pet: `请选择宠物`
  - missing time: `请选择预约意向时间`
- Keep the existing submitting guard to avoid duplicate appointment creation.

### 3. Non-goals

- No appointment table changes.
- No provider schedule table.
- No available-slot API.
- No admin schedule-management UI.
- No changes to appointment status transition rules.

## Verification Plan

Backend:

```powershell
.\scripts\test-backend.ps1
```

Phone:

```powershell
hvigorw.js test
hvigorw.js assembleHap
```

Manual verification:

1. Configure `PETPAL_SERVER_ORIGIN` with the current development machine LAN IP when using a simulator or phone.
2. Log in with `13800000001 / 123456`.
3. Open a provider detail page from the appointment tab.
4. Confirm the page shows `选择预约意向时间，最终以机构确认为准`.
5. Confirm today's past slots are not selectable.
6. Create an appointment with selected service, pet, and future intent time.
7. Confirm the new appointment appears in the appointment list.
8. Submit without selecting time and confirm `请选择预约意向时间`.
9. Confirm cancel appointment still works.
10. Confirm admin status updates remain visible on phone refresh.

## Acceptance Criteria

- Users no longer type raw appointment datetime text.
- Today does not expose past or near-past time slots.
- The UI clearly presents the time as an intent time.
- Existing appointment API contract remains unchanged.
- Backend tests pass.
- Harmony tests and HAP build pass.
- Manual appointment creation and cancellation checks pass.
