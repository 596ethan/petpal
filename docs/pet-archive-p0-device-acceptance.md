# Pet Archive P0 Device Acceptance

This script verifies the Pet Archive P0 phone flow on a real HarmonyOS device.

## Final Acceptance Result

Pet Archive P0 real-device acceptance passed on 2026-04-14.

Accepted phone/backend setup:
- Phone backend URL: `http://192.168.1.3:18080/api`
- Local API helper URL: `http://127.0.0.1:18080`
- Test account: `13800000001 / 123456`

Accepted checks:

| Checkpoint | Result |
|---|---|
| Create pet | Passed |
| Partial update pet | Passed |
| Soft delete pet | Passed |
| Add health record | Passed |
| View health record list | Passed |
| Add vaccine record | Passed |

Evidence notes:
- The phone UI created `验收豆豆`.
- The API helper created and updated `P0-Acceptance-Pet-...-Updated`.
- Both records appeared in the phone pet list through backend-backed data.
- The API helper verified health sorting by `recordDate desc, id desc`.
- The API helper verified soft-deleted pets no longer appear in the pet list and return `PET_NOT_FOUND` on detail access.

## Preconditions

- Backend is running and reachable from the phone.
- The phone app points `PETPAL_API_DEV_BASE_URL` to the backend LAN URL.
- The phone is logged in with a test account such as `13800000001 / 123456`.
- Do not validate community, search, map, admin, appointment expansion, or multi-device behavior in this pass.

Optional API helper:

```powershell
.\scripts\pet-archive-p0-api-acceptance.ps1 -ApiBaseUrl http://127.0.0.1:18080 -Phone 13800000001 -Password 123456
```

The helper validates backend API behavior and leaves the main acceptance pet in place for phone inspection. It soft-deletes a separate temporary pet for the delete case.

## 1. Create Pet

Operation:
- Open the phone app and go to the `我的` tab.
- Tap `新建宠物档案`.
- Enter:
  - Name: `验收豆豆`
  - Breed: `边牧`
  - Species: `狗狗`
  - Gender: `公`
  - Birthday: `2024-04-01`
  - Weight: `8.6`
  - Avatar URL: leave empty
  - Neutered: keep `未绝育`
- Tap `保存宠物档案`.

Expected result:
- A success message appears: `宠物档案已创建`.
- `验收豆豆` appears in `我的宠物档案`.
- Species, breed, birthday, and neutered state are visible.
- Empty avatar does not crash or show a broken image; the text-avatar fallback is shown.

Failure triage:
- Network error: verify backend process, phone/backend network, and `PETPAL_API_DEV_BASE_URL`.
- Login error: log in again and retry.
- Validation error: verify name is not blank, birthday is `yyyy-MM-dd`, and weight is a positive number.
- Pet does not appear after success: switch tabs or re-enter `我的` and confirm the list reloads from backend.

## 2. Partial Update Pet

Operation:
- Open `验收豆豆` with `查看健康档案`.
- Tap `编辑资料`.
- Change only:
  - Name: `验收豆豆-已更新`
  - Weight: `9.1`
- Leave all other fields unchanged.
- Tap `保存修改`.

Expected result:
- A success message appears: `宠物档案已更新`.
- Detail title becomes `验收豆豆-已更新`.
- Weight becomes `9.1kg`.
- Omitted fields are preserved: species remains dog, breed remains `边牧`, birthday remains `2024-04-01`, gender remains male.
- Returning to `我的` shows the updated name.

Failure triage:
- Omitted fields become blank: inspect `PUT /api/pet/{petId}` partial update behavior and UI request body.
- Validation error: verify name is not blank and weight is a positive number.
- Detail still shows old data: verify the update endpoint persists and the detail page refreshes after save.

## 3. Soft Delete Pet

Operation:
- Return to `我的` and create a separate temporary pet:
  - Name: `验收待删除`
  - Species: `猫咪`
  - Gender: `未知`
  - Other fields: optional
- Open `验收待删除`.
- Tap `删除档案`.

Expected result:
- Toast appears: `已删除`.
- The app returns to the previous page.
- `我的宠物档案` refreshes and no longer shows `验收待删除`.
- The deleted pet detail page is not retained as the active screen.
- Re-entering the deleted pet detail, if possible, shows a not found state.

Failure triage:
- Deleted pet still appears in list: verify `pet.deleted = 1` and `GET /api/pet/list` filters `deleted = 0`.
- App remains on the deleted detail: inspect delete success routing.
- Deleted detail still loads: verify `GET /api/pet/{petId}` returns `404 PET_NOT_FOUND` for deleted pets.
- Delete fails: verify the current account owns the pet and the token is valid.

## 4. Add Health Record

Operation:
- Open `验收豆豆-已更新`.
- Tap `添加健康记录`.
- Enter:
  - Type: `体检`
  - Title: `P0 体检记录`
  - Description: `真机验收健康记录`
  - Record date: `2026-04-14`
  - Next date: `2026-05-14`
- Tap `保存健康记录`.

Expected result:
- A success message appears: `健康记录已添加`.
- Health timeline shows `P0 体检记录`.
- Record date is `2026-04-14`.
- Next reminder is `2026-05-14`.
- Data is refreshed from backend, not appended as mock-only UI state.

Failure triage:
- Date validation error: verify `yyyy-MM-dd`.
- `PET_NOT_FOUND`: verify the pet is not deleted and belongs to the current user.
- Save succeeds but list does not show it: verify `POST /api/pet/{petId}/health` persists and the phone reloads the list.
- Ordering is wrong: verify backend ordering `recordDate desc, id desc`.

## 5. View Health Record List

Operation:
- On the same detail page, add another health record:
  - Type: `用药`
  - Title: `P0 同日第二条`
  - Description: `用于排序验收`
  - Record date: `2026-04-14`
  - Next date: empty
- Tap `保存健康记录`.
- Observe the health timeline.

Expected result:
- Both `2026-04-14` records appear.
- Same-day records sort with the later created record first: `P0 同日第二条` appears before `P0 体检记录`.
- Empty next date displays an empty-state label such as `无下次提醒`, not `null`.

Failure triage:
- Same-day order is reversed: inspect backend `ORDER BY record_date DESC, id DESC`.
- `null` appears on phone: inspect repository mapping for nullable `nextDate`.
- Records disappear after refresh: verify persisted `pet_health_record` rows and petId.

## 6. Add Vaccine Record

Operation:
- Open `验收豆豆-已更新`.
- Tap `添加疫苗记录`.
- Enter:
  - Vaccine name: `P0 狂犬疫苗`
  - Vaccinated at: `2026-04-14`
  - Next due at: `2027-04-14`
  - Hospital: `P0 验收宠物医院`
- Tap `保存疫苗记录`.

Expected result:
- A success message appears: `疫苗记录已添加`.
- Vaccine list shows `P0 狂犬疫苗`.
- Vaccinated date is `2026-04-14`.
- Next due date is `2027-04-14`.
- Hospital is `P0 验收宠物医院`.
- Vaccine record does not automatically appear in the health timeline.

Failure triage:
- Save fails: verify vaccine name is not blank and date is `yyyy-MM-dd`.
- `PET_NOT_FOUND`: verify the pet is not deleted and belongs to the current user.
- Save succeeds but list does not show it: verify `POST /api/pet/{petId}/vaccine` persists and the phone reloads the vaccine list.
- Ordering is wrong: verify backend ordering `vaccinatedAt desc, id desc`.
- `null` appears on phone: inspect repository mapping for nullable `nextDueAt` or `hospital`.

## Acceptance Checklist

| Item | Acceptance point | Pass |
|---|---|---|
| Create pet | `验收豆豆` can be created and appears in my pet list | Passed |
| Create pet | Empty avatar has a safe fallback | Passed |
| Partial update | Only name and weight change; omitted fields stay unchanged | Passed |
| Partial update | My pet list shows the updated name after returning | Passed |
| Soft delete | `验收待删除` returns to previous page and shows `已删除` | Passed |
| Soft delete | Deleted pet no longer appears in my pet list | Passed |
| Soft delete | Deleted pet detail shows not found if re-entered | Passed |
| Add health record | `P0 体检记录` is added and visible after refresh | Passed |
| Health list | Same-day health records sort by later-created first | Passed |
| Add vaccine record | `P0 狂犬疫苗` is added and visible after refresh | Passed |
| Vaccine list | Vaccine record shows vaccinated date, next due date, and hospital | Passed |
| Error state | Invalid date or blank required field shows visible error | Passed |
| Mock fallback | Request failures do not silently fall back to mock data | Passed |

## Current Implementation Scope

Implemented in this sealed P0 scope:
- Create pet profile.
- Partial update pet profile.
- Soft delete pet profile.
- Add health record.
- List health records.
- Add vaccine record.
- List vaccine records.
- Enforce current-user ownership for pet archive operations.
- Hide soft-deleted pets from `GET /api/pet/list`.
- Return `404 PET_NOT_FOUND` for non-existent, non-owned, or deleted pet access.
- Sort health records by `recordDate desc, id desc`.
- Sort vaccine records by `vaccinatedAt desc, id desc`.
- Phone UI loading, empty, error, and not found states for the pet archive flow.

## Not Implemented

Intentionally not implemented in Pet Archive P0:
- Pet avatar upload; `avatarUrl` remains an optional URL-like text field.
- Health record edit/delete.
- Vaccine record edit/delete.
- Automatic vaccine-to-health timeline mirroring.
- Pet archive search.
- Pet archive image gallery.
- Push/message notifications.
- Admin management for pet archives.
- Community, map, and multi-device collaboration changes.

## Known Limits

- Backend port is environment-specific. The Pet Archive P0 real-device acceptance used `18080` because this Windows environment reserves the `8000-8099` TCP range, including `8080`.
- Physical-device testing requires the phone and development machine to be on the same LAN and the phone app to use the development machine LAN IP, not `127.0.0.1`.
- The admin static page must use the same backend port as the running backend when validating appointment/admin paths.
- Phone repository tests exist under `Cutepetpost/entry/src/test`; run the available Hvigor test task when validating repository changes.
- `promptAction.showToast` currently emits a deprecation warning during `assembleHap`; it does not block build or acceptance.
- The API helper validates backend behavior; final UI acceptance still requires real-device manual operation.

## Release Recommendation

Recommended git commit message:

```text
feat: seal pet archive p0 acceptance
```

Recommended tag:

```text
v0.2.0-pet-archive-p0-accepted
```
