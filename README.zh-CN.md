# PetPal

[English](README.md) | [简体中文](README.zh-CN.md)

PetPal 是一个以 HarmonyOS 手机端为核心的 MVP 仓库。这个仓库包含手机应用、Spring Boot 后端、用于履约预约状态的最小管理端页面，以及当前 MVP 本地开发需要的基础设施。

## 当前状态

- 预约主链已经通过真机验收：登录、浏览机构和服务、创建预约、查看我的预约、管理端改状态、手机端刷新看到状态变化。
- 宠物档案 P0 已经通过真机验收：创建宠物、部分更新、软删除、新增健康记录、查看健康记录、新增疫苗记录、查看疫苗记录。
- 社区 P0 在当前范围内已经 sealed：发布带图片的帖子、点赞/取消点赞、发布根评论、删除自己的帖子。
- 数据库完整性加固已经推进到 P2g，并记录为 closure candidate，还不是 sealed 最终状态。

主要参考文档：

- [docs/phone-mvp.md](docs/phone-mvp.md)
- [docs/mvp-acceptance.md](docs/mvp-acceptance.md)
- [docs/pet-archive-p0-device-acceptance.md](docs/pet-archive-p0-device-acceptance.md)
- [docs/community-p0-device-acceptance.md](docs/community-p0-device-acceptance.md)
- [docs/db-integrity-p2-closure-candidate.md](docs/db-integrity-p2-closure-candidate.md)

## 仓库结构

- `Cutepetpost`：HarmonyOS 手机客户端，也是当前主交付面。
- `petpal-server`：Spring Boot 后端，承载登录、机构、预约、宠物档案、社区、文件上传等接口。
- `petpal-admin`：静态管理页，负责手机 MVP 需要的机构和预约管理操作。
- `deploy`：Redis 和 MinIO 的本地基础设施定义。
- `docs`：MVP 切片、验收记录、架构说明和相关决策文档。
- `scripts`：可重复执行的本地开发与验证脚本。

## 当前仓库内的 MVP 范围

当前已接受的手机优先范围：

1. 手机号密码登录
2. 浏览机构和服务
3. 创建预约
4. 查看当前用户的预约
5. 在规则允许时取消预约
6. 管理端更新预约状态
7. 宠物档案 P0
8. 社区 P0

除非新的切片明确纳入，否则当前不在已接受 MVP 范围内：

- 搜索
- 地图功能
- 通知
- 评价
- 短信登录
- 第三方登录
- 多端协同

## 本地开发

启动本地依赖：

```powershell
.\scripts\dev-deps-up.ps1
```

这个脚本只会启动 Redis 和 MinIO。MySQL 需要本机自行运行：

```text
host: localhost
port: 3306
database: petpal
user: root
password: 54321
```

如果是全新本地库，初始化顺序是：

1. `petpal-server/src/main/resources/db/schema.sql`
2. `petpal-server/src/main/resources/db/seed.sql`

如果本地已经有 `petpal` 库，先检查现有数据，再决定是否执行初始化 SQL，避免把有用的开发数据直接覆盖掉。

运行后端测试：

```powershell
.\scripts\test-backend.ps1
```

启动后端：

```powershell
.\scripts\run-backend.ps1
```

`application.yml` 当前默认值：

- HTTP 端口：`18080`
- Redis：`localhost:6379`
- MinIO API：`http://localhost:9000`
- MinIO Console：`http://localhost:9001`
- 管理端 token：`petpal-admin-token-change-me`

手机端请直接用 DevEco Studio 打开 `Cutepetpost` 进行构建和运行。

## 手机联调说明

- `Cutepetpost/entry/src/main/ets/config/PetPalAppConfig.ets` 里要填开发机的局域网 IP。
- 真机联调不要用 `127.0.0.1`。
- 后端、手机端、管理端要指向同一个后端 HTTP 端口。
- 这台 Windows 环境里，`18080` 是当前更稳妥的默认值，不建议依赖 `8080` 或其他 `8000-8099` 端口。

当前配置示例：

```typescript
export const PETPAL_DEV_SERVER_ORIGIN: string = 'http://192.168.1.3:18080';
export const PETPAL_SERVER_ORIGIN: string = PETPAL_DEV_SERVER_ORIGIN;
export const PETPAL_API_BASE_URL: string = `${PETPAL_SERVER_ORIGIN}/api`;
```

测试账号：

```text
phone: 13800000001
password: 123456
```

管理端使用方式：

1. 在开发机浏览器里打开 `petpal-admin/index.html`。
2. API Base URL 填同一个后端端口，比如 `http://127.0.0.1:18080`。
3. 默认 token 用 `petpal-admin-token-change-me`。

如果管理端页面报 `failed to fetch`，先查 CORS 和预检请求，重点看 `OPTIONS /**` 和 `X-PetPal-Admin-Token` 请求头。

## 实现说明

- 账号密码现在只接受 BCrypt 存储格式。
- 受保护接口只接受 access JWT，refresh JWT 不能当 access token 用。
- 社区图片上传接口是 `POST /api/file/upload`，multipart 字段名必须是 `file`。
- 上传大小限制是 5 MB。
- 返回的图片地址必须走后端代理路径，比如 `/api/file/object/{fileKey}`。

## 建议阅读顺序

1. [docs/phone-mvp.md](docs/phone-mvp.md)
2. 你这次要改动对应的切片文档或验收文档
3. 直接受影响的模块代码

这和仓库里的 [AGENTS.md](AGENTS.md) 规则保持一致。
