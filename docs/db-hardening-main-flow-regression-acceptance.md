# DB Hardening Main Flow Regression Acceptance

## Status

- Status: passed
- Review date: 2026-05-06
- Branch: `main`
- Baseline commit: `273a609`
- Baseline tag: `db-integrity-p2-closure-candidate`
- Final conclusion: regression passed for closure candidate

## Environment

- Live database: local MySQL `petpal`
- MySQL version from read-only summary: `8.0.40`
- Backend base URL for local smoke: `http://127.0.0.1:18080`
- Phone build backend origin used in this run: `http://192.168.1.6:18080`
- HDC target: `127.0.0.1:5555`
- Device model: `emulator`
- Device product name: `emulator`
- Device API version: `21`
- Test account: `13800000001 / 123456`
- API smoke prefix: `DBREG-20260506160133`
- Phone UI prefix: `DBREG-20260506162842`

## Entry Criteria Record

- `git status --short --branch` started from clean `main...origin/main`.
- `git log -1 --oneline` matched `273a609 docs: move p2 closure follow-ups to backlog`.
- Tag `db-integrity-p2-closure-candidate` exists locally.

## Live DB Read-Only Baseline

Command:

```powershell
$env:MYSQL_PWD='54321'
mysql -uroot petpal --batch --raw --execute="source scripts/db-integrity-p2-summary-readonly.sql"
```

Observed result:

- All expected P0/P1/P2a-P2f DDL constraints were `present`.
- Missing DDL constraint count: `0`.
- All P0/P1/P2a-P2g invalid or drift counts were `0`.
- `post_derived_count_drift = 0`.
- `service_review_appointment_orphan = 0`
- `service_review_user_orphan = 0`
- `service_review_provider_orphan = 0`
- `service_review_rating_out_of_range = 0`

## Automated Checks

Backend tests:

```powershell
.\scripts\test-backend.ps1
```

Result:

- `Tests run: 63, Failures: 0, Errors: 0, Skipped: 0`
- Maven `BUILD SUCCESS`

Dependency/runtime prep:

```powershell
.\scripts\dev-deps-up.ps1
```

Result:

- Redis container `petpal-redis` was already running on `6379`.
- MinIO container `petpal-minio` was already running on `9000/9001`.
- MySQL was already listening on `3306`.

Phone build:

```powershell
$localHome='D:\HongMengprogram\20260317\Cutepetpost\.hvigor-home'
$env:DEVECO_SDK_HOME='D:\Program Files\Huawei\DevEco Studio\sdk'
$env:USERPROFILE=$localHome
$env:HOME=$localHome
$env:HOMEDRIVE='D:'
$env:HOMEPATH='\HongMengprogram\20260317\Cutepetpost\.hvigor-home'
& 'D:\Program Files\Huawei\DevEco Studio\tools\node\node.exe' `
  'D:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js' `
  --mode module -p module=entry@default -p product=default `
  assembleHap --no-daemon --no-parallel --no-incremental --analyze=false
```

Result:

- Hvigor `BUILD SUCCESSFUL in 9 s 726 ms`
- Signing was skipped because no signing config is configured.

Installed artifact:

- `Cutepetpost\entry\build\default\outputs\default\entry-default-unsigned.hap`
- `hdc install -r ...entry-default-unsigned.hap` succeeded.

## API Smoke Record

All live smoke below ran against `http://127.0.0.1:18080` with prefix `DBREG-20260506160133`.

Baseline/API availability:

- `POST /api/user/login` succeeded for user id `1`.
- Protected `GET /api/appointment/list` without token returned HTTP `403`.
- `GET /api/provider/list` returned `3` providers.
- Provider smoke used provider id `1`, service id `1`.
- Seed pet smoke used pet id `1`.

Appointment flow:

- Created appointment id `28` with remark `DBREG-20260506160133 appointment-status-chain`.
- Admin status flow via `PUT /admin/appointments/{id}/status` moved it to `CONFIRMED` then `COMPLETED`.
- Created appointment id `29` with remark `DBREG-20260506160133 appointment-cancel-chain`.
- User cancel via `PUT /api/appointment/{id}/cancel` moved it to `CANCELLED`.
- Final list state:
  - appointment `28` -> `COMPLETED`
  - appointment `29` -> `CANCELLED`

Pet archive flow:

- Created main pet id `7`.
- Partial update preserved omitted fields and changed the name to `DBREG-20260506160133-pet-main-updated`.
- Added health record id `5`.
- Added vaccine record id `5`.
- Created delete-target pet id `8`, deleted it, then confirmed `GET /api/pet/8` returned `404 PET_NOT_FOUND`.

Community flow:

- Uploaded one image and received backend proxy URL:
  - `/api/file/object/community/edfaac1a-778f-44a6-9706-e86a310b3ba5.png`
- `GET` on that object URL returned HTTP `200`.
- Created post id `10`.
- Feed and detail returned the same backend proxy image URL.
- Like/unlike flow passed.
- Created root comment id `14`.
- Deleted post `10`.
- Post-delete checks:
  - `GET /api/post/10` -> `404 POST_NOT_FOUND`
  - `GET /api/post/10/comment` -> `404 POST_NOT_FOUND`

Admin note:

- Appointment status transitions were verified through the admin HTTP endpoint with `X-PetPal-Admin-Token`.
- The static `petpal-admin` page UI itself was not re-exercised in the phone continuation run.

## Device Record

Device control used in this run:

- Midscene automation was unavailable because no `MIDSCENE_*` model environment variables were configured.
- HDC `uitest dumpLayout`, `uitest uiInput`, screenshots, and accepted manual operator input were used for the phone UI continuation.

Confirmed device-side evidence:

- Wrong-password login stayed on the login page and showed `手机号或密码错误`.
- Correct-password login for `13800000001 / 123456` succeeded.
- The home page also showed a backend-driven unauthenticated failure toast containing `Authentication required` during pre-login spot checks, which confirmed the app was calling the real backend instead of silently switching to local mock data.

Appointment chain:

- Phone UI created appointment `PP1778058308444273` with remark `DBREG-20260506162842-APPT-`.
- The phone list first showed that appointment in `待确认`.
- Admin endpoint moved the same appointment to `CONFIRMED`; after phone refresh and re-login, the phone list showed `已确认`.
- Admin endpoint then moved the same appointment to `COMPLETED`; after phone refresh and re-login, the phone list showed `已完成`.
- Phone UI created appointment `PP1778077567499153` with remark `DBREG-20260506162842-CANCEL1`.
- Phone UI cancelled `PP1778077567499153`; the phone list then showed `已取消`.

Pet archive chain:

- Phone UI created pet `DBREG-20260506162842-PET1`.
- Phone UI updated that pet to `DBREG-20260506162842-PET1-U1` and changed weight from `4.2` to `4.5` without resetting omitted fields.
- Phone UI added health record `DBREG-20260506162842-H1`.
- Phone UI added vaccine record `DBREG-20260506162842-V1`.
- Phone UI created temporary pet `DBREG-20260506162842-PETDEL`, then deleted it.
- The deleted temporary pet no longer appeared in the `我的` pet list.

Community chain:

- Phone UI published post `DBREG-20260506162842-POST1`.
- The post detail page rendered the uploaded image.
- The uploaded image URL persisted as `/api/file/object/community/875386c1-778e-4467-98fb-189303d63b3c.jpg`.
- Phone UI completed like then unlike on the post.
- Phone UI added root comment `DBREG-20260506162842-C1`.
- Phone UI deleted the post.
- After delete, the community list no longer exposed `DBREG-20260506162842-POST1`.

## Post-Run Verification

Phone UI records were cross-checked against live backend state:

- Appointment `PP1778058308444273` was `COMPLETED` in MySQL and rendered as `已完成` on the phone.
- Appointment `PP1778077567499153` was `CANCELLED` in MySQL and rendered as `已取消` on the phone.
- Pet `DBREG-20260506162842-PET1-U1` persisted with `breed = AuditCat`, `weight = 4.50`.
- Temporary pet `DBREG-20260506162842-PETDEL` remained only as `deleted = 1` before final cleanup.
- Health record `DBREG-20260506162842-H1` and vaccine record `DBREG-20260506162842-V1` persisted before cleanup.
- Community post `DBREG-20260506162842-POST1` was soft deleted (`deleted = 1`) before cleanup.
- Deleted post API checks returned:
  - `GET /api/post/11` -> `404 POST_NOT_FOUND`
  - `GET /api/post/11/comment` -> `404 POST_NOT_FOUND`

## Cleanup Record

Cleanup method:

- Prefix-limited SQL cleanup only for `DBREG-20260506162842` rows in `post_like`, `comment`, `post_image`, `post`, `pet_health_record`, `pet_vaccine`, `appointment`, and `pet`.
- No broad delete without a prefix filter was used.

Cleanup verification result:

- `appointment_rows = 0`
- `pet_rows = 0`
- `health_rows = 0`
- `vaccine_rows = 0`
- `post_rows = 0`
- `comment_rows = 0`
- `post_image_rows = 0`

Known leftover object:

- Relational rows were removed, but the uploaded MinIO object remained accessible by direct object URL because the current MVP APIs do not provide object deletion:
  - `community/875386c1-778e-4467-98fb-189303d63b3c.jpg`
  - `GET /api/file/object/community/875386c1-778e-4467-98fb-189303d63b3c.jpg` still returned HTTP `200` after SQL cleanup.

## Temporary Local Config

- Local-only phone config change used for this build:
  - file: `Cutepetpost/entry/src/main/ets/config/PetPalAppConfig.ets`
  - from: `http://192.168.1.3:18080`
  - to: `http://192.168.1.6:18080`
- That file was restored before final closeout; it did not remain as a git change.

## Conclusion

This run meets the acceptance criteria for `regression passed for closure candidate`.

What passed:

- live DB read-only integrity baseline
- backend automated tests
- dependency/runtime availability
- HAP build and reinstall
- live API smoke for appointment, pet archive, and community flows
- phone wrong-password and correct-password login checks
- phone appointment create/status-refresh/cancel chain
- phone pet create/update/delete/health/vaccine chain
- phone community upload/post/like/unlike/comment/delete chain
- targeted cleanup of created relational data
- device evidence that backend failures surface from the real backend instead of silently falling back to mock data

Residual note:

- One uploaded MinIO object remains reachable by direct object URL because there is no current deletion API for stored objects. This residual object was recorded explicitly and was not mixed into the relational cleanup result.
