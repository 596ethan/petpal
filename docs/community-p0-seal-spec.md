# Community P0 Seal Spec

## Owner

- Coordinator: 负责按本 spec 协调 Community P0 封口，不扩大到社区二期或新功能 slice。
- Device acceptance: 负责真机/模拟器手工复验图片代理链路，并记录结果到 `docs/community-p0-device-acceptance.md`。
- Final commit/tag: 负责清理工作区、确认 `git status --short`、准备最终 commit message 和 tag。

## Entry Criteria

- Backend tests passed.
- Harmony build passed.
- Image proxy fix is in workspace.
- Backend/MinIO can be started for re-verification.

## Seal Plan

本次只处理 Community P0 收尾材料，不修改业务代码，不进入下一个功能 slice，不处理社区二期。验收依据为 `docs/phone-mvp.md` 中 Slice 5 Community P0 合同，以及 `docs/architecture-decisions.md` 中图片服务决策记录。

图片代理复验只覆盖：
- 选择图片。
- 上传图片。
- 发布带图动态。
- feed 显示图片。
- detail 显示图片。
- 删除后不可见。

## Image Proxy Re-Verification Script

前置条件：
- 后端、MySQL、Redis、MinIO 已运行。
- 手机端使用开发机 LAN IP，不使用 `127.0.0.1`。
- 登录测试账号 `13800000001 / 123456`。
- 手机相册中准备 1 张真实图片。
- 使用唯一正文，例如 `CommunityImageProxy<yyyyMMddHHmm>`。

步骤：
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

记录字段：
- Unique content:
- Upload URL:
- Feed image result: pass / fail
- Detail image result: pass / fail
- Delete hidden from feed: pass / fail
- Delete hidden from detail: pass / fail
- Evidence summary:
- Final result: pass / fail

## Final Outputs

更新 `docs/community-p0-device-acceptance.md`，包含：
- 已通过项：
  - 登录后可发布社区动态。
  - 图片通过 `/api/file/upload` 上传。
  - 发布时 `imageUrls` 随动态保存。
  - feed 可渲染后端返回的图片 URL。
  - detail 可渲染同一图片 URL。
  - 删除自己的动态后，feed/detail 不再暴露该动态。
- 图片复验结果：
  - 复验日期、设备/模拟器、后端地址、测试账号。
  - 唯一正文、上传 URL、feed/detail 图片结果、删除后不可见结果。
  - 最终结论：图片代理修复通过/未通过。
- 已知限制：
  - 上传仅支持图片文件，最大 5MB。
  - 社区发布最多 9 张图片。
  - 图片可见性依赖手机能访问后端 LAN URL。
  - MinIO bucket 不要求公开，手机端不依赖 MinIO 直链。
  - 反向代理部署时，生成的 `/api/file/object/{fileKey}` 外部可达性需单独确认。
- 暂不支持范围：
  - 评论回复、评论删除、评论点赞。
  - 动态编辑。
  - 搜索、推荐、通知。
  - 审核/管理后台社区工作流。
  - 第三方媒体处理、裁剪、压缩、转码。

## Cleanup Rules

应删除或排除：
- 根目录 `_tmp_community_*` 布局 dump 和截图。
- `_tmp_community_layout_*.json`、`_tmp_community_*.jpeg`、`_tmp_community_acceptance.png`。
- `_tmp_impeccable/`。
- 其他 `_tmp_*`、`*.tmp`、临时日志 `*.log`。

应保留：
- `docs/community-p0-device-acceptance.md`。
- `docs/community-p0-seal-spec.md`。
- `docs/architecture-decisions.md` 中图片服务决策。
- `docs/phone-mvp.md` 中 Community P0 slice 合同。

不应提交：
- `.codex/config.toml` 本地配置。
- `.hvigor/`、`.preview/`、`.hvigor-home/`、`node_modules/`、`target/`。
- 临时截图、layout dump、临时日志。
- 与 Community P0 封口无关的源码或文档改动。

## Commit And Tag

推荐 commit message：
- `docs: seal community p0 acceptance`

推荐 tag：
- 若复验材料仍只是候选状态：`community-p0-seal-candidate`
- 若图片复验、文档更新、清理检查全部完成：`community-p0-sealed`

## Exit Criteria

- Image proxy re-verification passed.
- `docs/community-p0-device-acceptance.md` updated.
- temp files cleaned or excluded.
- commit message and tag finalized.
