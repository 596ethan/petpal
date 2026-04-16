# PetPal Phone MVP Slices

This document defines the implementation slices required by `AGENTS.md`.

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
    - `appointmentTime: string` in ISO 8601 local datetime format, for example `2026-04-12T15:30:00`
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
- Invalid time format is rejected with a 400 JSON response.
- Past appointment time is rejected with a 400 JSON response.
- Pet not owned by the current user is rejected with a 400 JSON response.
- Service that does not belong to the selected provider is rejected with a 400 JSON response.
- Illegal status transitions are rejected.
- Confirmed appointments within 2 hours cannot be cancelled by the user.
- Phone client shows a clear error message and does not silently fall back to mock data for appointment creation.

### Test cases
- backend: appointment creation generates `orderNo`
- backend: appointment initial status is `PENDING_CONFIRM`
- backend: appointment creation rejects invalid time format
- backend: appointment creation rejects past time
- backend: appointment creation rejects pet not owned by current user
- backend: appointment creation rejects service/provider mismatch
- backend: user can cancel `PENDING_CONFIRM`
- backend: user cannot cancel confirmed appointment within 2 hours
- backend: illegal admin transition fails
- phone: submit success path
- phone: cancel success path
- phone: cancel failure messaging

## Slice 4: Pet Archive P0

### User goal
A phone user can maintain the core pet archive lifecycle: create a pet profile, update pet information, delete a pet profile, add health records, view health records, and add vaccine records.

### Entry screen
- `Cutepetpost/entry/src/main/ets/pages/Index.ets`
- `Cutepetpost/entry/src/main/ets/pages/PetDetail.ets`
- follow-up phone pet form screen or in-page form to be added during implementation

### API contract
- All pet archive P0 endpoints require phone auth with `Authorization: Bearer <accessToken>`.
- `POST /api/pet`
  - Request:
    - `name: string`
    - `species: "DOG" | "CAT" | "RABBIT" | "BIRD" | "OTHER"`
    - `breed?: string`
    - `gender: "MALE" | "FEMALE" | "UNKNOWN"`
    - `birthday?: string` in `yyyy-MM-dd`
    - `weight?: number` in kg
    - `avatarUrl?: string`
    - `neutered?: boolean`
  - Success:
    - created pet profile owned by the current user
- `PUT /api/pet/{petId}`
  - Partial update. Fields not present in the request keep their existing values.
  - If a field is present, the backend validates it.
  - Required fields cannot be updated to blank strings.
- `DELETE /api/pet/{petId}`
  - Soft deletes the pet profile.
  - Does not hard-delete health records, vaccine records, or historical appointments.
- `GET /api/pet/list`
  - Returns only current user's non-deleted pets.
- `GET /api/pet/{petId}`
  - Returns the current user's non-deleted pet profile.
- `POST /api/pet/{petId}/health`
  - Request:
    - `recordType: "VACCINE" | "CHECKUP" | "MEDICATION" | "SURGERY"`
    - `title: string`
    - `description?: string`
    - `recordDate: string` in `yyyy-MM-dd`
    - `nextDate?: string` in `yyyy-MM-dd`
- `GET /api/pet/{petId}/health`
  - Returns records ordered by `recordDate desc, id desc`.
- `POST /api/pet/{petId}/vaccine`
  - Request:
    - `vaccineName: string`
    - `vaccinatedAt: string` in `yyyy-MM-dd`
    - `nextDueAt?: string` in `yyyy-MM-dd`
    - `hospital?: string`
- `GET /api/pet/{petId}/vaccine`
  - Returns records ordered by `vaccinatedAt desc, id desc`.

### Success state
- Creating a pet persists it to the backend and refreshes the phone pet list.
- Partial update changes only submitted fields and preserves omitted fields.
- Deleting a pet removes it from the phone pet list and returns the user to the previous screen with a success message.
- Adding a health record persists it and the health timeline refreshes in backend sort order.
- Adding a vaccine record persists it and the vaccine list refreshes in backend sort order.

### Failure state
- Missing required fields, invalid dates, and invalid weight return clear 400 responses.
- Non-existent, non-owned, or deleted pets return `404` with code `PET_NOT_FOUND` for detail, update, delete, health create, and vaccine create.
- Deleted pets are not returned by `GET /api/pet/list`.
- Phone client shows visible loading, empty, error, and not found states.
- Phone client must not silently fall back to mock data for pet archive P0 failures.

### Test cases
- backend: pet creation persists and appears in current user's pet list
- backend: partial update preserves omitted fields
- backend: partial update rejects blank required fields
- backend: delete soft-deletes the pet and removes it from list
- backend: deleted pet detail/update/delete/health create/vaccine create return `PET_NOT_FOUND`
- backend: non-owned pet detail/update/delete/health create/vaccine create return `PET_NOT_FOUND`
- backend: health record creation persists and list returns `recordDate desc, id desc`
- backend: vaccine record creation persists and list returns `vaccinatedAt desc, id desc`
- phone repository: create/update/delete/add health/add vaccine use the locked paths, methods, auth headers, and bodies
- phone repository: backend errors are surfaced without mock fallback
- phone: create success path
- phone: update success path
- phone: delete success path with return, list refresh, and "已删除" message
- phone: health record add success path
- phone: vaccine record add success path
- phone: deleted pet detail shows a not found state

## Slice 5: Community P0

### User goal
A logged-in phone user can publish a community post, attach uploaded images, like or unlike posts, publish root comments, view comment lists, and delete their own posts.

### Entry screen
- `Cutepetpost/entry/src/main/ets/pages/Index.ets`
- `Cutepetpost/entry/src/main/ets/pages/PostDetail.ets`

### API contract
- Community P0 write endpoints require phone auth with `Authorization: Bearer <accessToken>`.
- Feed/detail/comment reads are public, but when a valid token is present the backend returns the current user's `liked` state.
- `POST /api/post`
  - Request:
    - `content: string`
    - `petId?: number`
    - `imageUrls?: string[]`, maximum 9
  - Success:
    - created public post owned by the current user
    - returned `PostDto` includes `id`, `userId`, `userNickname`, `userAvatarUrl`, `petId`, `petName`, `content`, `imageUrls`, `topics`, `visibility`, `likeCount`, `commentCount`, `liked`, `createdAt`
- `DELETE /api/post/{postId}`
  - Success:
    - soft deletes the current user's post
- `POST /api/post/{postId}/like`
  - Success:
    - idempotently records the current user's like
- `DELETE /api/post/{postId}/like`
  - Success:
    - idempotently removes the current user's like
- `POST /api/post/{postId}/comment`
  - Request:
    - `content: string`
  - Success:
    - created root comment owned by the current user
    - returned `PostCommentDto` includes `id`, `parentId`, `userId`, `userNickname`, `content`, `createdAt`
- `GET /api/post/{postId}/comment`
  - Returns root comments ordered by `created_at asc, id asc`.
- `POST /api/file/upload`
  - Request:
    - multipart form-data field `file`
  - Success:
    - `fileKey: string`
    - `url: string`
  - Failure:
    - non-image files return `400 INVALID_FILE_TYPE`
    - oversized files return `400 FILE_TOO_LARGE`
    - missing file returns `400 FILE_REQUIRED`
    - storage failure returns `500 FILE_UPLOAD_FAILED`

### Success state
- Publishing a post persists it and refreshes the community feed.
- Uploaded images are stored through `/api/file/upload` and associated with the created post.
- Liking and unliking update `liked` and `likeCount` from backend state.
- Publishing a comment persists it, refreshes the comment list, and updates `commentCount`.
- Deleting the current user's post removes it from feed and makes detail/comment reads return not found.

### Loading, empty, error, not-found, and submitting states
- Feed and detail loads show visible loading state.
- Empty feed and empty comment list show designed empty states.
- Request failures show visible error messages.
- Missing or deleted post detail shows a not-found state.
- Publish, delete, like, unlike, comment, and upload actions show submitting state and do not allow duplicate taps while submitting.
- Phone client must not silently fall back to mock data for Community P0 failures.

### Community P0 rules
- Comment scope: Community P0 only supports root comments. It does not support comment replies, comment deletion, or comment likes.
- Soft delete visibility: deleted posts do not appear in feed; detail, delete, like, unlike, comment create, and comment list for a deleted post return `404 POST_NOT_FOUND`.
- Like consistency: `post_like` has a unique constraint on `(post_id, user_id)`; like and unlike are idempotent; `likeCount` is maintained from backend state and is not corrected by frontend-only increments.
- Upload prerequisite: Phone UI must not wire a fake upload flow. Publishing-page image upload may be wired only after `/api/file/upload` multipart contract, MinIO configuration, and error codes are stable.

### Out of scope
- Comment replies
- Comment deletion
- Comment likes
- Post editing
- Search
- Recommendations
- Notifications
- Moderation/admin community workflows
- Third-party media processing

### Test cases
- backend: unauthenticated community writes are rejected
- backend: post creation persists current `userId`, validates non-blank content, validates owned optional `petId`, and stores up to 9 images
- backend: feed excludes deleted posts and returns `imageUrls`, `liked`, `likeCount`, and `commentCount`
- backend: detail for deleted or missing posts returns `POST_NOT_FOUND`
- backend: only the author can delete a post; non-author delete returns `POST_NOT_FOUND`
- backend: like is idempotent and uses the `(post_id, user_id)` unique constraint
- backend: unlike is idempotent and never makes `likeCount` negative
- backend: comment creation persists a root comment and increments `commentCount`
- backend: comments for a post return `created_at asc, id asc`
- backend: deleted post detail/delete/like/unlike/comment create/comment list return `POST_NOT_FOUND`
- backend: upload rejects missing, non-image, and oversized files with stable error codes
- backend: upload stores a valid image and returns `fileKey` and `url`
- phone repository: create/delete/like/unlike/comment/upload use the locked paths, methods, auth headers, and bodies
- phone repository: community read requests include auth when a session exists
- phone repository: backend errors are surfaced without mock fallback
- phone: publish post success path
- phone: image upload success path before publish
- phone: like/unlike success path
- phone: author delete success path
- phone: comment create and list success path
- phone: loading, empty, error, not-found, and submitting states
- e2e: after login, publish a post with an uploaded image, see it in feed, like and unlike it, open detail, publish a root comment, see it in the comment list, delete the post, and verify feed/detail/comment list no longer expose it
