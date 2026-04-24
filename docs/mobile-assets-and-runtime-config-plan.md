# Mobile Assets And Runtime Config Plan

> Plan date: 2026-04-23  
> Status: accepted  
> Target branch: `codex/fix/mobile-assets-and-runtime-config`

## Owner

- Codex

## Entry Criteria

- The phone client still used a hard-coded LAN IP for the dev backend.
- Existing community media data still contained old absolute LAN URLs.
- Live MySQL data had already drifted away from `schema.sql` and `seed.sql`.
- The immediate goal was to remove runtime and data noise before changing more UI behavior.

## Background

This round was not about redesigning the community UI. The real blocker was that runtime address rules and media URL rules were not aligned:

- the phone client pointed to a hard-coded LAN IP
- uploaded media and stored media URLs were not normalized
- live development data contained stale values that could pollute manual verification

If those were left unresolved, later manual verification would keep producing noisy or misleading results.

## Goal

1. Remove the hard-coded LAN IP from the phone client default runtime config.
2. Make API base URL selection explicit and singular.
3. Normalize backend media URL behavior so the app no longer depends on stale LAN object URLs.
4. Rebuild local development data from current scripts and verify against a clean baseline.

## Scope

### 1. Phone runtime base URL

- Replace the old `PETPAL_API_DEV_BASE_URL` hard-coded LAN value.
- Keep a single runtime source of truth: `PETPAL_SERVER_ORIGIN -> PETPAL_API_BASE_URL`.
- Require only one config change when switching between localhost and a LAN IP.

### 2. Media URL normalization

- Stop treating uploaded media URLs as durable host-bound absolute URLs.
- Make upload responses return backend proxy paths.
- Normalize community post image URLs on write and on read.
- Resolve proxy paths against the current backend origin in the phone repository layer.

### 3. Local database baseline

- Rebuild local `petpal` from the current `schema.sql` and `seed.sql`.
- Use rebuilt local data instead of patching stale live rows piecemeal.
- Verify key tables after rebuild: `service_provider`, `service_item`, `appointment`, `pet`, `post`, `post_image`.

### 4. Minimum seed-data cleanup

- Update `糯米` and `七七` avatar URLs to stable, reachable image URLs.
- Remove stale old LAN media references from the local development baseline.
- Keep `seed.sql` aligned with the new runtime and media rules.

## Explicit Non-Goals

- No community pet selector work in this round.
- No appointment time UX redesign.
- No new backend product features.
- No unrelated refactor outside the runtime/media chain.

## Planned Files

- `Cutepetpost/entry/src/main/ets/config/PetPalAppConfig.ets`
- `Cutepetpost/entry/src/main/ets/repository/PetPalRepository.ets`
- `petpal-server/src/main/java/com/petpal/server/file/FileController.java`
- `petpal-server/src/main/java/com/petpal/server/community/CommunityMutationService.java`
- `petpal-server/src/main/java/com/petpal/server/community/CommunityQueryService.java`
- `petpal-server/src/main/resources/db/seed.sql`
- related tests and contracts where needed

## Implementation Order

1. Normalize phone runtime base URL configuration.
2. Normalize backend media URL write/read behavior.
3. Update `seed.sql`.
4. Rebuild local `petpal` and verify rebuilt rows.
5. Run backend and Harmony verification.
6. Run manual verification on the phone/simulator.

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

Manual verification at minimum:

1. Change the phone client backend address once.
2. Log in successfully.
3. Verify `糯米` and `七七` avatars in the pet list.
4. Verify existing post images in the community list.
5. Verify existing post images in post detail.
6. Publish a new post with an uploaded image and verify it renders correctly.

## Acceptance Criteria

- Changing the backend address once is enough to restore both API access and media access.
- `糯米` and `七七` avatars render correctly.
- Existing community images no longer depend on stale old LAN URLs.
- `.\scripts\test-backend.ps1` passes.
- `hvigorw.js test` passes.
- `hvigorw.js assembleHap` passes.
- Manual verification for pet list, post list, and post detail passes.

## Final Acceptance Record

- Status: accepted
- Branch used: `codex/fix/mobile-assets-and-runtime-config`
- Automated verification:
  - `.\scripts\test-backend.ps1`: passed
  - `hvigorw.js test`: passed
  - `hvigorw.js assembleHap`: passed
- Data actions:
  - local `petpal` was rebuilt from current `schema.sql` and `seed.sql`
  - local `pet.avatar_url` for `糯米` and `七七` was verified after rebuild
  - stale old LAN media references were removed from the rebuilt local baseline
- Manual verification:
  - login passed
  - pet list avatars passed
  - community post list images passed
  - post detail images passed
  - uploaded media path validation passed

## Suggested Commit Message

```text
fix: stabilize mobile assets and runtime config
```
