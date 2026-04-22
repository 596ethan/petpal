# Index Tabs Refactor Plan

> 计划日期：2026-04-23  
> 状态：accepted  
> 目标分支：`codex/refactor/index-tabs`

## Owner

- Codex

## Entry Criteria

- Post-MVP quality cleanup has been accepted.
- Stable tag exists: `post-mvp-quality-cleanup-2026-04-22`.
- Current data layer cleanup is complete and merged to `main`.
- `docs/phone-mvp.md` remains the phone MVP source of truth.
- No implementation starts until this plan is reviewed and accepted.

## Background

The previous cleanup round intentionally deferred file-level cleanup for `Index.ets`.
That prerequisite is now met:

- Phone data requests have been routed through a clearer service path.
- `DemoDataStore.java` has been removed.
- Backend and phone verification passed.
- Manual end-to-end verification passed.
- A cleanup acceptance record exists in `docs/post-mvp-quality-cleanup-acceptance.md`.

`Cutepetpost/entry/src/main/ets/pages/Index.ets` is now around 1478 lines and mixes:

- page lifecycle and refresh state
- four tab views
- community composer state and actions
- pet creation form state and actions
- repeated cards and shared visual helpers

This round should reduce the risk of changing `Index.ets` by splitting the tab-level UI structure without changing product behavior.

## Goal

1. Make `Index.ets` smaller and easier to maintain.
2. Keep the accepted phone MVP behavior unchanged.
3. Split by visible tab boundaries before considering deeper component or state refactors.

## Current Tab Boundaries

Current tab builders in `Index.ets`:

- `HomeTab`
- `CommunityTab`
- `BookingTab`
- `MineTab`
- `FloatingTabBar` / `NavPill`

Major shared builders currently used across tabs:

- `SectionLead`
- `CapsuleChip`
- `SoftAvatar`
- `EmptyStatePanel`
- `LoginRequiredPanel`
- `NotePanel`
- `StoryImageBlock`
- post/provider/appointment/profile/pet cards

## Scope

### 1. Extract tab-level components

Create a small `index-tabs` area under the phone client source tree, for example:

```text
Cutepetpost/entry/src/main/ets/pages/index-tabs/
```

Planned files:

- `HomeTab.ets`
- `CommunityTab.ets`
- `BookingTab.ets`
- `MineTab.ets`
- `IndexTabBar.ets`
- `IndexTabShared.ets`

`Index.ets` remains the entry page and keeps:

- `@Entry`
- top-level page state
- `aboutToAppear`
- `onPageShow`
- backend refresh orchestration
- repository calls
- navigation callbacks
- mutation actions such as create pet, upload image, publish post, like, unlike, delete, cancel appointment

### 2. Pass explicit typed inputs into tabs

Each extracted tab should receive only the state and callbacks it needs.

Examples:

- Home: `posts`, `providers`, `pets`, `appointments`, `refreshError`, `onOpenCommunity`, `onOpenProvider`
- Community: `isAuthenticated`, `refreshing`, `posts`, composer state, message/error state, upload/publish/like/delete callbacks
- Booking: `isAuthenticated`, `appointments`, `providers`, cancel/open-provider callbacks
- Mine: `isAuthenticated`, `user`, `pets`, `posts`, `appointments`, pet creation state, create/open-detail callbacks
- Tab bar: `currentTab`, tab switch callback

Use explicit interfaces for grouped input where it keeps signatures readable.
Do not pass anonymous object literals without declared interfaces, because ArkTS tests in this repo have previously failed on untyped object literals.

### 3. Keep behavior unchanged

The refactor should not change:

- tab labels or selected-tab behavior
- backend API paths
- repository calls
- login-required behavior
- loading, empty, error, not-found, and submitting states
- post publishing, image upload, like/unlike, delete, and comment entry behavior
- pet creation behavior
- appointment cancellation behavior
- provider and detail navigation routes

### 4. Use a fallback if ArkTS component boundaries fight callback props

Preferred implementation is extracted `@Component` structs with typed props and callbacks.

If `hvigor test` or `assembleHap` exposes ArkTS restrictions around cross-file callback props, fall back to a narrower pass:

- move stateless shared builders and cards first
- keep action-heavy composer/form builders inside `Index.ets`
- still extract the four tab shell builders once compile-safe

The fallback still counts only if `Index.ets` becomes structurally smaller and behavior remains unchanged.

## Explicit Non-Goals

- No backend changes.
- No repository/data-layer changes.
- No new product features.
- No visual redesign.
- No copy rewrite except if a moved string must remain identical.
- No route changes.
- No split of `PetPalRepository.ets`.
- No split of `PostDetail.ets`, `PetDetail.ets`, or `ProviderDetail.ets`.
- No tablet/watch adaptation.

## Implementation Order

1. Create `pages/index-tabs/` support files.
2. Move shared visual helpers that are safe and stateless.
3. Extract `IndexTabBar` first because it has the smallest surface.
4. Extract `HomeTab` and `BookingTab` because they are mostly read-only display.
5. Extract `CommunityTab` with composer state and callbacks.
6. Extract `MineTab` with pet creation state and callbacks.
7. Re-run ArkTS verification after each meaningful step if the compiler surface changes.
8. Review `Index.ets` to ensure it now reads as orchestration rather than a full UI dump.

## Verification Plan

Required automated checks:

- `hvigorw.js test --mode module -p module=entry@default -p product=default --no-daemon --no-parallel --no-incremental --analyze=false`
- `hvigorw.js assembleHap --mode module -p module=entry@default -p product=default --no-daemon --no-parallel --no-incremental --analyze=false`

Backend tests are not required for this UI-only refactor unless implementation touches repository, backend API calls, or data contracts. If any such file is touched unexpectedly, run:

- `.\scripts\test-backend.ps1`

Manual smoke checks after implementation:

- login still enters the main page
- tab switch works for Home, Community, Booking, Mine
- provider card navigation still opens provider detail
- appointment list still renders and cancel action still works when cancellable
- community composer opens, image upload path still works, publish/like/delete still works
- Mine tab shows profile and pets
- pet creation still creates and refreshes the pet list
- pet detail navigation still opens the selected pet

## Acceptance Criteria

- `Index.ets` keeps `@Entry` and orchestration logic but no longer contains all four full tab bodies.
- The four main tab views are in separate tab-level files.
- Shared helpers are moved only where they reduce duplication or unblock tab extraction.
- No accepted MVP behavior changes.
- `hvigor test` passes.
- `assembleHap` passes.
- Manual smoke check passes or the remaining manual check is clearly stated.
- `git status --short` is reviewed before final report.

## Final Acceptance Record

- Status: accepted
- Acceptance date: 2026-04-23
- Final branch: `main`
- Final commit: `1454b51`
- Merged branch: `codex/refactor/index-tabs`
- Branch cleanup: local and remote `codex/refactor/index-tabs` deleted after merge

Implemented files:

- `Cutepetpost/entry/src/main/ets/pages/Index.ets`
- `Cutepetpost/entry/src/main/ets/pages/index-tabs/HomeTab.ets`
- `Cutepetpost/entry/src/main/ets/pages/index-tabs/CommunityTab.ets`
- `Cutepetpost/entry/src/main/ets/pages/index-tabs/BookingTab.ets`
- `Cutepetpost/entry/src/main/ets/pages/index-tabs/MineTab.ets`
- `Cutepetpost/entry/src/main/ets/pages/index-tabs/IndexTabBar.ets`
- `Cutepetpost/entry/src/main/ets/pages/index-tabs/IndexTabShared.ets`

Verification results:

- `hvigorw.js test --mode module -p module=entry@default -p product=default --no-daemon --no-parallel --no-incremental --analyze=false`: passed
- `hvigorw.js assembleHap --mode module -p module=entry@default -p product=default --no-daemon --no-parallel --no-incremental --analyze=false`: passed
- Manual verification reported by the user: passed

Manual verification coverage:

- four-tab switching and active tab visual state
- Community composer opening
- Community publish flow
- like and unlike actions
- Mine tab pet creation form opening
- pet archive creation flow

Notes:

- No backend, repository, route, or API contract changes were made in this refactor.
- The interaction regression found after the first extraction was fixed by switching extracted builders to `$$` parameter passing and direct parent object literals, so parent state changes refresh child tab UI correctly.

## Risks

- ArkTS may reject callback or state-passing shapes that look valid in TypeScript. Keep inputs explicitly typed and compile early.
- Splitting too deeply in one pass could create noisy churn. Keep this round to tab-level extraction.
- Community and Mine tabs carry mutation-heavy forms. If those increase compile risk, extract their shell first and leave a follow-up for form-level split.
- UI behavior can regress without type errors. Manual smoke checks remain required even if build passes.

## Suggested Commit Message

```text
refactor: split index tabs
```
