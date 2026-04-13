# PetPal MVP API Contract

This contract records the current implementation only.

## Common Response

Implemented response envelope:

```json
{
  "code": "OK",
  "message": "success",
  "data": {},
  "requestId": null
}
```

Errors use the same top-level shape when handled by the backend exception layer. Phone APIs use `Authorization: Bearer <accessToken>` for protected endpoints.

## Login

Implemented:

`POST /api/user/login`

Request:

```json
{
  "phone": "13800000001",
  "password": "123456"
}
```

Success data:

```json
{
  "profile": {
    "id": 1,
    "phone": "13800000001",
    "nickname": "Xiaoman",
    "avatarUrl": "https://placehold.co/96x96",
    "bio": "Cat and dog care journal",
    "followingCount": 0,
    "followerCount": 0
  },
  "tokens": {
    "accessToken": "<jwt>",
    "refreshToken": "<jwt>"
  }
}
```

Known failure:

- Wrong credentials return `401` with code `INVALID_CREDENTIALS`.

## Providers And Services

Implemented:

- `GET /api/provider/list`
- `GET /api/provider/{id}`
- `GET /api/provider/{id}/services`

Provider data includes:

```json
{
  "id": 1,
  "name": "Cloud Vet Center",
  "type": "HOSPITAL",
  "address": "188 Dingxiang Rd, Pudong",
  "phone": "021-12345678",
  "rating": 4.8,
  "coverUrl": "https://placehold.co/800x400",
  "businessHours": "09:00-20:00"
}
```

Service data includes:

```json
{
  "id": 1,
  "providerId": 1,
  "name": "Wellness Check",
  "price": 199,
  "durationMinutes": 30
}
```

## Appointments

Implemented:

- `POST /api/appointment`
- `GET /api/appointment/list`
- `PUT /api/appointment/{id}/cancel`

`POST /api/appointment` requires phone auth.

Request:

```json
{
  "petId": 1,
  "providerId": 1,
  "serviceId": 1,
  "appointmentTime": "2099-01-02T10:00:00",
  "remark": "Check appetite"
}
```

Success data includes:

```json
{
  "id": 2,
  "orderNo": "PP209901020001",
  "petName": "Nuomi",
  "providerName": "Cloud Vet Center",
  "serviceName": "Wellness Check",
  "status": "PENDING_CONFIRM",
  "appointmentTime": "2099-01-02T10:00:00",
  "remark": "Check appetite"
}
```

Implemented validation:

- Invalid time format returns `400` with code `INVALID_APPOINTMENT_TIME`.
- Past appointment time returns `400` with code `APPOINTMENT_TIME_IN_PAST`.
- Pet not owned by current user returns `400` with code `PET_NOT_AVAILABLE`.
- Service not available under the selected provider returns `400` with code `SERVICE_NOT_AVAILABLE`.
- Confirmed appointments inside the cancellation boundary return `409` with code `APPOINTMENT_NOT_CANCELLABLE`.

Appointment statuses currently used:

- `PENDING_CONFIRM`
- `CONFIRMED`
- `COMPLETED`
- `CANCELLED`
- `EXPIRED`

## Admin Appointment Status

Implemented:

- `GET /admin/appointments`
- `PUT /admin/appointments/{id}/status`

Admin auth accepts both headers:

- `X-PetPal-Admin-Token: <token>`
- `Authorization: Bearer <token>`

Wrong or missing token returns `401` JSON with code `ADMIN_UNAUTHORIZED`.

Status update request:

```json
{
  "status": "CONFIRMED"
}
```

Implemented transitions are enforced by backend rules. Illegal transitions return `409` with code `INVALID_APPOINTMENT_STATUS`.

## Known Limits

- Refresh-token rotation is not implemented.
- Phone client repository tests exist, but this DevEco/Hvigor project currently does not expose a local unit-test task.
- Community feed still has demo fallback and is not part of the appointment MVP acceptance path.
