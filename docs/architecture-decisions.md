# PetPal Architecture Decisions

This document records cross-slice architecture decisions that affect the phone MVP.

## File Upload And Image Serving

### Decision
- Uploaded files are stored in MinIO.
- The MinIO bucket does not need to be public.
- Phone clients must not receive MinIO direct object URLs as durable image URLs.
- The backend must return a phone-readable backend URL for uploaded images, such as `/api/file/object/{fileKey}`.
- The backend image endpoint reads the object from MinIO with server-side credentials and streams the bytes to the client.

### Reason
- A successful MinIO upload does not prove the phone can read the object.
- Private MinIO buckets return `403` for direct object URLs.
- `localhost` or private MinIO URLs are not valid phone-facing image URLs.
- Keeping MinIO private avoids coupling phone behavior to bucket policy and local deployment details.

### Consequences
- Phone UI and repositories only consume backend URLs returned in `imageUrls`.
- Community feed and detail screens should render images through backend-served URLs.
- Backend upload tests must verify both:
  - upload response returns `fileKey` and a backend URL
  - `GET /api/file/object/{fileKey}` can stream image bytes
- If deployment sits behind a proxy, generated image URLs must remain externally reachable from the phone.

### Failure Triage
When images render blank:
1. Verify `PostDto.imageUrls` is non-empty.
2. Verify `imageUrls` do not contain `localhost` or direct private MinIO bucket URLs.
3. Open the image URL from the phone or emulator network context.
4. Check `petpal-server` file serving logs and MinIO connectivity.
5. Check phone UI only after backend URL accessibility is confirmed.

## Slice Acceptance Records

### Decision
- Accepted slice behavior is recorded in `docs/*acceptance.md`.
- Temporary screenshots, layout dumps, local API logs, and `_tmp_*` files are not retained in git.
- A slice is sealed only when the acceptance document states what passed, what remains out of scope, and any known risks.

### Reason
- Acceptance records are useful; scattered temporary files are not.
- Keeping evidence in Markdown makes future agent runs and human reviews easier.

### Consequences
- Before sealing, review `git status --short` and remove or ignore temporary artifacts.
- If evidence is needed, summarize the important observation in the acceptance document instead of adding raw dumps.
