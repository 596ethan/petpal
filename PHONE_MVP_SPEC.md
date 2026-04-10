# PetPal Phone MVP Slices

This document defines the first three implementation slices required by `AGENTS.md`.

## Slice 1: Password Login

### User goal
A phone user logs in with a mobile number and password and enters the app with a valid authenticated session.

### Entry screen
`Cutepetpost/entry/src/main/ets/pages/Login.ets`

### API contract
- `POST /api/user/login`
  - Request:
    - `phone: string`
    - `password: string`
  - Success:
    - `code: "OK"`
    - `data.profile`
    - `data.tokens.accessToken`
    - `data.tokens.refreshToken`
  - Failure:
    - invalid credentials return non-OK response with a user-safe message
- Protected phone flows must reject requests without a valid token.

### Success state
- Login succeeds with correct credentials.
- Token is stored on device.
- App navigates to the main phone experience.

### Failure state
- Wrong password keeps the user on the login screen.
- User sees an explicit error message.
- Protected API calls without a token fail and trigger login recovery.

### Test cases
- backend: login succeeds with correct credentials
- backend: login fails with wrong password
- backend: protected endpoint rejects unauthenticated access
- phone: token persistence after successful login
- phone: failed login shows error and does not navigate

## Slice 2: Appointment Browse Flow

### User goal
A phone user can browse providers, provider details, service items, and their own appointments.

### Entry screen
- `Cutepetpost/entry/src/main/ets/pages/Index.ets`
- `Cutepetpost/entry/src/main/ets/pages/ProviderDetail.ets`

### API contract
- `GET /api/provider/list`
- `GET /api/provider/{id}`
- `GET /api/provider/{id}/services`
- `GET /api/appointment/list`
  - returns appointments only for the authenticated current user

### Success state
- Provider list loads from real backend data.
- Provider detail and services load from real backend data.
- Appointment list shows only current user data.

### Failure state
- Request failure shows a visible error state.
- Empty provider list or appointment list shows a designed empty state.

### Test cases
- backend: provider list returns persisted records
- backend: provider detail returns expected provider
- backend: provider services return only provider-owned records
- backend: appointment list returns only current user records
- phone: list loading state
- phone: empty state
- phone: error state

## Slice 3: Appointment Create and Cancel

### User goal
A phone user selects a provider service and pet, chooses a time, adds an optional remark, creates an appointment, and cancels it when business rules allow.

### Entry screen
- `Cutepetpost/entry/src/main/ets/pages/ProviderDetail.ets`
- follow-up phone appointment flow screen to be added during implementation

### API contract
- `POST /api/appointment`
  - Request:
    - `petId: number`
    - `providerId: number`
    - `serviceId: number`
    - `appointmentTime: string`
    - `remark?: string`
  - Success:
    - created appointment with generated `orderNo`
    - initial status `PENDING_CONFIRM`
- `PUT /api/appointment/{id}/cancel`
  - Success only for cancellable appointments
- `PUT /admin/appointments/{id}/status`
  - supports `CONFIRMED`, `COMPLETED`, `CANCELLED` with legal transitions only

### Success state
- User submits an appointment successfully.
- New appointment appears in "my appointments".
- User can cancel a valid appointment.
- Admin status updates become visible on phone after refresh.

### Failure state
- Invalid payload is rejected.
- Illegal status transitions are rejected.
- Confirmed appointments within 2 hours cannot be cancelled by the user.

### Test cases
- backend: appointment creation generates `orderNo`
- backend: appointment initial status is `PENDING_CONFIRM`
- backend: user can cancel `PENDING_CONFIRM`
- backend: user cannot cancel confirmed appointment within 2 hours
- backend: illegal admin transition fails
- phone: submit success path
- phone: cancel success path
- phone: cancel failure messaging
