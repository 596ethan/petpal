# Community Pet Selector Plan

> Plan date: 2026-04-23  
> Status: accepted  
> Target branch: `codex/fix/community-pet-selector`  
> Prerequisite: runtime/media stabilization completed first

## Owner

- Codex

## Entry Criteria

- Runtime base URL and media URL behavior had already been stabilized.
- The phone client community composer still required manual pet ID input.
- The current page already loaded the user's pet list and could reuse it directly.

## Background

The community composer asked the user to type an internal pet ID. That was a real UX problem:

- users do not know internal IDs
- the backend contract already accepts `petId`
- the missing piece was only the phone-side selection UI

This round therefore stayed narrow: replace pet ID text input with an explicit pet selector, without changing the backend contract.

## Goal

1. Remove the manual pet ID text input from the community composer.
2. Let the user choose either:
   - no linked pet
   - one of the current user's pets
3. Keep the existing backend request shape and validation unchanged.
4. Avoid regressions in image upload, publish, detail, and comment flows.

## Scope

### 1. Replace the input mode

- Remove `宠物编号（可选）` text input from the composer.
- Add explicit UI selection:
  - `不关联宠物`
  - loaded pets such as `糯米`, `七七`

### 2. Keep the request contract unchanged

- When a pet is selected, submit `petId`.
- When no pet is selected, omit `petId`.
- Do not change the backend controller, DTO, or validation behavior.

### 3. Reuse already-loaded pets

- Use the pet list already loaded into `Index.ets`.
- Do not add a new API.
- Do not change the post detail comment logic.

## Explicit Non-Goals

- No backend API changes.
- No post detail comment changes.
- No broader composer redesign.
- No appointment-related UI work.

## Planned Files

- `Cutepetpost/entry/src/main/ets/pages/index-tabs/CommunityTab.ets`
- `Cutepetpost/entry/src/main/ets/pages/Index.ets`

## Implementation Order

1. Replace the composer pet-ID input with explicit pet selection UI.
2. Wire the selected pet ID into the existing `PostCreateInput`.
3. Remove the old front-end number-parsing path.
4. Run Harmony verification and manual composer regression checks.

## Verification Plan

Phone:

```powershell
hvigorw.js test
hvigorw.js assembleHap
```

Manual verification at minimum:

1. Open the community composer.
2. Confirm the old pet ID input is gone.
3. Confirm selectable options include `不关联宠物`, `糯米`, `七七`.
4. Publish one post linked to a pet.
5. Publish one post with no linked pet.
6. Verify the existing upload/detail/comment flows still work.

## Acceptance Criteria

- The composer no longer requires the user to understand internal pet IDs.
- Selecting a pet still hits the existing backend validation path.
- Publishing with no linked pet still works.
- Existing community publish flow does not regress.
- `hvigorw.js test` passes.
- `hvigorw.js assembleHap` passes.

## Final Acceptance Record

- Status: accepted
- Implemented on top of the stabilized runtime/media branch
- Automated verification:
  - `hvigorw.js test`: passed
  - `hvigorw.js assembleHap`: passed
- Manual verification:
  - composer no longer shows the pet ID text input
  - linked-pet publish path passed
  - no-linked-pet publish path passed
  - existing community publish flow passed

## Suggested Commit Message

```text
fix: replace community pet id input with pet selector
```
