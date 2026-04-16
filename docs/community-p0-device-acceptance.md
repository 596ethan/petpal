# Community P0 Device Acceptance

This document is the Community P0 seal record. The execution spec is `docs/community-p0-seal-spec.md`.

## Seal Status

- Status: sealed
- Reason: backend tests, HAP build, backend/API image proxy smoke test, and device image proxy re-verification passed.
- Acceptance owner: Codex
- Acceptance date: 2026-04-15
- Device or emulator: `127.0.0.1:5555` via HDC
- Backend base URL: `http://192.168.1.3:18080/api`
- Test account: `13800000001 / 123456`

## Entry Criteria Record

- [x] Backend tests passed.
- [x] Harmony build passed.
- [x] Image proxy fix is in workspace.
- [x] Backend/MinIO can be started for re-verification.

Evidence:
- Backend test command/result: `.\scripts\test-backend.ps1` passed; `Tests run: 35, Failures: 0, Errors: 0, Skipped: 0`; Maven `BUILD SUCCESS`.
- Harmony build command/result: `hvigorw.js assembleHap --mode module -p module=entry@default -p product=default --no-daemon --no-parallel --no-incremental --analyze=false` passed; Hvigor `BUILD SUCCESSFUL`.
- Backend/MinIO start note: MySQL `3306`, Redis `6379`, MinIO `9000/9001` were listening; backend was started on `18080` and accepted login through `http://192.168.1.3:18080/api/user/login`.

## 已通过项

- [x] Backend tests for Community P0 and prior MVP rules passed.
- [x] HAP build completed successfully.
- [x] Backend API accepts `/api/file/upload` and returns a backend proxy URL under `/api/file/object/{fileKey}`.
- [x] Backend API persists `imageUrls` with the created post.
- [x] Backend API feed/detail return the same uploaded backend image URL.
- [x] Backend image proxy endpoint returns the image bytes with HTTP `200`.
- [x] Backend API delete hides the post from feed and detail.
- [x] Device visual verification of selecting an existing gallery image, upload, feed render, detail render, and delete-hidden behavior passed.

## 图片复验结果

- 复验日期: 2026-04-15
- 设备/模拟器: `127.0.0.1:5555`
- 后端地址: `http://192.168.1.3:18080/api`
- 测试账号: `13800000001 / 123456`
- Device unique content: `CommunityImageProxyDevice202604152251`
- Device upload URL: `http://192.168.1.3:18080/api/file/object/community/28ab2c67-8fc9-46c2-8a37-5a2329ae1dc4.jpg`
- Feed image result: pass
- Detail image result: pass
- Delete hidden from feed: pass
- Delete hidden from detail: pass
- Final result: pass

API smoke evidence:
- Unique content: `CommunityImageProxyApi202604152246`
- Upload URL: `http://192.168.1.3:18080/api/file/object/community/7f41eb78-ffb8-4e07-a813-1541ba3c04d7.png`
- Upload URL backend proxy: true
- `GET` uploaded object status: `200`
- Feed image URL matched upload URL.
- Detail image URL matched upload URL.
- Feed hidden after delete: true
- Detail hidden after delete: true

Device evidence:
- App `com.example.cutepetpost` is installed on `127.0.0.1:5555`.
- App launch succeeded with `aa start -a EntryAbility -b com.example.cutepetpost`.
- Community tab opened.
- Composer opened from `写一条`.
- Device content field accepted `CommunityImageProxyDevice202604152251`.
- System image picker opened from `Add images 0/9`.
- Existing gallery screenshot was selectable.
- Picker showed `已选 1/9`; tapping `完成` returned to the composer.
- Composer showed `Image uploaded.` and a thumbnail preview.
- Publishing showed `Post published.`
- Feed displayed `CommunityImageProxyDevice202604152251` with the uploaded screenshot image.
- Detail displayed the same post and image under `图片与片段`.
- Deleting the post returned to feed, and `CommunityImageProxyDevice202604152251` was no longer visible.
- Database lookup found post id `7` with `deleted=1`.
- `GET /api/post/7` returned `404`, confirming deleted detail is not exposed.

复验脚本范围：
1. 进入手机端社区页，打开发布入口。
2. 点击 `Add images 0/9`，从系统相册选择 1 张图片。
3. 等待上传完成，确认发布器中出现图片缩略图，并记录上传返回 URL。
4. 确认上传 URL 是后端可读地址，例如 `/api/file/object/{fileKey}`，不是 `localhost`、MinIO 私有直链或本地 fake URL。
5. 输入唯一正文，发布带图动态。
6. 在 feed 中定位唯一正文，确认图片真实渲染，不是空白、占位块或加载失败。
7. 进入该动态 detail，确认 `图片与片段` 区域显示同一张上传图。
8. 删除该动态。
9. 返回或刷新 feed，确认唯一正文和图片不可见。
10. 再次打开该动态 detail 时，应进入 `Post not found` 或等价不可见状态。

## 已知限制

- 上传仅支持图片文件，最大 5MB。
- 社区发布最多 9 张图片。
- 图片可见性依赖手机能访问后端 LAN URL。
- MinIO bucket 不要求公开，手机端不依赖 MinIO 直链。
- 反向代理部署时，生成的 `/api/file/object/{fileKey}` 外部可达性需单独确认。
- Device image proxy re-verification depends on a selectable image already existing in the device or emulator gallery.

## 暂不支持范围

- 评论回复、评论删除、评论点赞。
- 动态编辑。
- 搜索、推荐、通知。
- 审核/管理后台社区工作流。
- 第三方媒体处理、裁剪、压缩、转码。

## Cleanup Record

- [x] 根目录 `_tmp_community_*` 布局 dump 和截图已删除或确认不提交。
- [x] `_tmp_impeccable/` 已删除或确认不提交。
- [x] 其他 `_tmp_*`、`*.tmp`、临时日志 `*.log` 已删除或确认不提交。
- [x] `git status --short` 已复核。

## Commit And Tag

Recommended commit message:
- `docs: seal community p0 acceptance`

Recommended tag:
- Seal candidate: `community-p0-seal-candidate`
- Fully sealed after completed verification: `community-p0-sealed`

Current tag recommendation:
- `community-p0-sealed`

## Exit Criteria Record

- [x] Image proxy re-verification passed.
- [x] `docs/community-p0-device-acceptance.md` updated.
- [x] temp files cleaned or excluded.
- [x] commit message and tag finalized.
