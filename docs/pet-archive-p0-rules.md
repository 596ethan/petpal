# Pet Archive P0 Rules

This document is the stage-specific execution contract for the Pet Archive P0 slice. It does not replace `AGENTS.md`; it narrows the next implementation stage only.

## Scope

Do only:
- Create pet profiles.
- Partially update pet profiles.
- Soft-delete pet profiles.
- Add health records.
- List health records.
- Add vaccine records.
- Keep existing pet detail and vaccine list reads working against real backend data.

Do not do:
- Appointment feature expansion.
- Community module work.
- Admin UI or admin API work.
- Search, map, messaging, review, tablet, watch, or multi-device work.
- Large unrelated refactors.
- Mock fallback for pet archive P0 failures.

## Execution Gates

1. Complete PR1 docs and rules first.
2. After PR1 locks the contract, PR2 backend and PR3 phone repository may proceed in parallel.
3. PR4 phone UI starts only after PR3 repository method signatures and input types are stable.
4. Final integration happens after PR2, PR3, and PR4 are complete.

Hard rules:
- Phone UI Agent must not invent repository method signatures, error codes, or field names; it must follow the backend contract and the landed repository signatures.
- Backend Agent must lock the Pet Archive P0 error codes and HTTP semantics before implementation; Coordinator review is required before Phone Repository Agent and Phone UI Agent depend on those errors.
- PR4 must not modify the same data submission flow concurrently with PR3; Phone UI Agent only starts wiring data submission after repository signatures and input types are stable.

## API Semantics

All endpoints require phone auth with `Authorization: Bearer <accessToken>`.

- `POST /api/pet` creates a current-user pet profile.
- `PUT /api/pet/{petId}` is a partial update. Omitted fields keep existing values. Present fields are validated. Required fields cannot be updated to blank strings.
- `DELETE /api/pet/{petId}` soft-deletes a pet by setting `pet.deleted = 1` and updating `updated_at`.
- `GET /api/pet/list` returns only current user's non-deleted pets.
- `GET /api/pet/{petId}` returns only current user's non-deleted pet.
- `POST /api/pet/{petId}/health` adds a health record to a current-user non-deleted pet.
- `GET /api/pet/{petId}/health` returns records ordered by `recordDate desc, id desc`.
- `POST /api/pet/{petId}/vaccine` adds a vaccine record to a current-user non-deleted pet.
- `GET /api/pet/{petId}/vaccine` returns records ordered by `vaccinatedAt desc, id desc`.

Dates use `yyyy-MM-dd`. Pet weight is stored as a kg number. Avatar upload is out of scope; `avatarUrl` is an optional URL-like string only. Vaccine records do not automatically create health timeline records.

## Error Semantics

- Missing required fields return HTTP `400`.
- Invalid date format returns HTTP `400`.
- Invalid weight returns HTTP `400`.
- Blank required fields return HTTP `400`.
- Non-existent, non-owned, or deleted pets return HTTP `404` with code `PET_NOT_FOUND` for detail, update, delete, health create, and vaccine create.
- Authentication failures follow the existing phone auth behavior.

Recommended P0 error codes:
- `BAD_REQUEST` for framework validation failures.
- `INVALID_PET_FIELD` for invalid pet field values.
- `INVALID_HEALTH_RECORD_FIELD` for invalid health record field values.
- `INVALID_VACCINE_RECORD_FIELD` for invalid vaccine record field values.
- `PET_NOT_FOUND` for non-existent, non-owned, or deleted pet access.

## Frontend Behavior

- The phone client must submit P0 mutations to the backend through `PetPalRepository`.
- The phone client must show explicit loading, empty, error, and not found states where applicable.
- The phone client must not silently fall back to mock data after P0 pet archive request failures.
- On delete success, the phone client returns to the previous screen, refreshes the pet list, and shows `已删除`.
- The phone client must not keep the deleted pet detail screen alive as the active state.
- If a deleted pet detail is opened again, the phone client shows a not found state.

## Subagent Write Areas

Coordinator:
- `docs/phone-mvp.md`
- `docs/pet-archive-p0-rules.md`
- final `docs/api-contracts.md` review
- final integration verification

Backend Agent:
- `petpal-server/src/main/java/com/petpal/server/pet/**`
- necessary pet DTO files
- `petpal-server/src/test/java/com/petpal/server/PetPalServerMvcTest.java`
- `docs/api-contracts.md`

Phone Repository Agent:
- `Cutepetpost/entry/src/main/ets/repository/PetPalRepository.ets`
- necessary `Cutepetpost/entry/src/main/ets/models/**` type changes
- `Cutepetpost/entry/src/test/**`

Phone UI Agent:
- `Cutepetpost/entry/src/main/ets/pages/**`
- `Cutepetpost/entry/src/main/resources/base/profile/main_pages.json` only if a new page is required

Agents must not edit outside their write areas unless the Coordinator explicitly reassigns the file.

## Test Checklist

Backend:
- Create pet persists and appears in `/api/pet/list`.
- Partial update changes submitted fields and preserves omitted fields.
- Blank required field update fails.
- Invalid date and invalid weight fail.
- Soft delete removes pet from list.
- Deleted pet detail/update/delete/health create/vaccine create return `PET_NOT_FOUND`.
- Non-owned pet detail/update/delete/health create/vaccine create return `PET_NOT_FOUND`.
- Health records sort by `recordDate desc, id desc`.
- Vaccine records sort by `vaccinatedAt desc, id desc`.

Phone repository:
- Create/update/delete/add health/add vaccine use the locked path, method, body, and auth behavior.
- Success responses map to phone models.
- Backend errors pass through to the UI layer.

Phone manual acceptance:
- Create pet.
- Partially update pet.
- Soft-delete pet.
- Add health record.
- View health records list.
- Add vaccine record.
- Confirm deleted pet is removed from list and detail re-entry shows not found.

## Completion Gate

This stage is complete only when:
- Backend P0 pet write APIs use real persistence and no request echo stubs remain.
- Backend tests cover the P0 business rules and `mvn test` passes.
- Phone repository supports all P0 mutations and key tests are updated.
- Phone UI can complete the six P0 flows against real APIs.
- No pet archive P0 failure silently falls back to mock data.
- Manual phone acceptance passes.
