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

Release-hardening standard errors:

| Scenario | HTTP | code | Message stability | Phone display |
|---|---:|---|---|---|
| Missing upload file | 400 | `FILE_REQUIRED` | Stable | Show backend message |
| Non-image upload | 400 | `INVALID_FILE_TYPE` | Stable | Show backend message |
| Upload over 5MB | 400 | `FILE_TOO_LARGE` | Stable | Show backend message |
| Multipart size limit exceeded | 400 | `FILE_TOO_LARGE` | Stable | Show backend message |
| JSON parse failure | 400 | `BAD_REQUEST` | Stable generic message | Show backend message |
| Parameter type mismatch | 400 | `BAD_REQUEST` | Stable generic message | Show backend message |
| Storage upload failure | 500 | `FILE_UPLOAD_FAILED` | Stable | Show backend message |
| Uploaded object missing | 404 | `FILE_NOT_FOUND` | Stable | Image/detail fallback or failure state |

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
- Password storage is BCrypt-only. Plaintext stored passwords are not accepted.
- Access tokens include `type=access`; refresh tokens include `type=refresh`.
- Protected APIs reject refresh tokens used as access tokens with `401` and code `UNAUTHORIZED`.
- Refresh-token rotation is not implemented in this MVP. The phone client clears session state and sends the user back to login on auth failure.

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

## Pet Archive P0

Implemented:

- `POST /api/pet`
- `GET /api/pet/list`
- `GET /api/pet/{petId}`
- `PUT /api/pet/{petId}`
- `DELETE /api/pet/{petId}`
- `POST /api/pet/{petId}/health`
- `GET /api/pet/{petId}/health`
- `POST /api/pet/{petId}/vaccine`
- `GET /api/pet/{petId}/vaccine`

All pet archive endpoints require phone auth.

Pet create request:

```json
{
  "name": "Momo",
  "species": "RABBIT",
  "breed": "Mini Rex",
  "gender": "UNKNOWN",
  "birthday": "2024-02-03",
  "weight": 2.4,
  "avatarUrl": "https://placehold.co/120x120?text=momo",
  "neutered": false
}
```

Pet data includes:

```json
{
  "id": 3,
  "name": "Momo",
  "species": "RABBIT",
  "breed": "Mini Rex",
  "gender": "UNKNOWN",
  "birthday": "2024-02-03",
  "weight": 2.4,
  "avatarUrl": "https://placehold.co/120x120?text=momo",
  "neutered": false
}
```

`PUT /api/pet/{petId}` uses partial update semantics. Omitted fields keep their existing values. Present fields are validated, and required fields cannot be updated to blank strings.

`DELETE /api/pet/{petId}` soft-deletes the pet by setting `deleted = 1`. Deleted pets are not returned by `GET /api/pet/list` and return `404` with code `PET_NOT_FOUND` for detail, update, delete, health create, and vaccine create.

Health record create request:

```json
{
  "recordType": "CHECKUP",
  "title": "Morning check",
  "description": "Stable",
  "recordDate": "2026-04-01",
  "nextDate": "2026-05-01"
}
```

Health record list ordering is `recordDate desc, id desc`.

Vaccine record create request:

```json
{
  "vaccineName": "Rabies",
  "vaccinatedAt": "2026-08-01",
  "nextDueAt": "2027-08-01",
  "hospital": "Cloud Vet Center"
}
```

Vaccine record list ordering is `vaccinatedAt desc, id desc`.

Implemented validation:

- Missing required create fields return `400` with code `BAD_REQUEST`.
- Invalid pet field values, including invalid date and invalid weight, return `400` with code `INVALID_PET_FIELD`.
- Invalid health record field values return `400` with code `INVALID_HEALTH_RECORD_FIELD`.
- Invalid vaccine record field values return `400` with code `INVALID_VACCINE_RECORD_FIELD`.
- Non-existent, non-owned, or deleted pets return `404` with code `PET_NOT_FOUND` for pet archive P0 operations.

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

## Community P0

Implemented:

- `GET /api/post/feed`
- `GET /api/post/{postId}`
- `POST /api/post`
- `DELETE /api/post/{postId}`
- `POST /api/post/{postId}/like`
- `DELETE /api/post/{postId}/like`
- `POST /api/post/{postId}/comment`
- `GET /api/post/{postId}/comment`

Community write endpoints require phone auth. Feed, detail, and comment reads are public, and include current-user `liked` state when a valid access token is supplied.

Post create request:

```json
{
  "petId": 1,
  "content": "Nuomi finished the vaccine today.",
  "imageUrls": [
    "/api/file/object/community/example.jpg"
  ]
}
```

Post data includes:

```json
{
  "id": 1,
  "userId": 1,
  "userNickname": "Xiaoman",
  "userAvatarUrl": "https://placehold.co/96x96",
  "petId": 1,
  "petName": "Nuomi",
  "content": "Nuomi finished the vaccine today.",
  "imageUrls": [],
  "topics": [],
  "visibility": "PUBLIC",
  "likeCount": 0,
  "commentCount": 0,
  "liked": false,
  "createdAt": "2026-04-15T22:46:00"
}
```

Implemented community validation:

- Unauthenticated writes return auth failure.
- Blank post content returns `400 INVALID_POST_FIELD`.
- Non-owned optional `petId` returns `404 PET_NOT_FOUND`.
- More than 9 post images, blank image URLs, or too-long image URLs return `400 INVALID_POST_IMAGE`.
- Deleted or missing posts return `404 POST_NOT_FOUND` for detail, delete, like, unlike, comment create, and comment list.
- Like and unlike are idempotent and backed by the `(post_id, user_id)` unique constraint.
- Root comments are ordered by `created_at asc, id asc`.

## File Upload

Implemented:

- `POST /api/file/upload`
- `GET /api/file/object/{fileKey}`

Upload request is multipart form-data with field name `file`.

Success data:

```json
{
  "fileKey": "community/example.jpg",
  "url": "/api/file/object/community/example.jpg"
}
```

Upload limits and errors:

- Only image content types are accepted.
- The maximum image size is 5MB.
- Missing file returns `400 FILE_REQUIRED`.
- Non-image file returns `400 INVALID_FILE_TYPE`.
- Oversized file or multipart size limit returns `400 FILE_TOO_LARGE`.
- Storage failure returns `500 FILE_UPLOAD_FAILED`.
- Missing object reads return `404 FILE_NOT_FOUND`.
- The returned `url` is a backend proxy path. The phone client may resolve it against the current backend origin for display, but must not persist MinIO direct URLs as durable image URLs.

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
- Comment replies, comment deletion, comment likes, post editing, search, recommendations, notifications, moderation workflows, and third-party media processing remain outside Community P0.
