# Appointment Conflict Consistency Plan

## Status
Completed on 2026-04-26.

## Summary
目标是最小且正确地修复“重复活跃预约”。保留当前后端业务预检查和手机端提示，同时增加数据库唯一约束兜底并发。范围只限预约创建一致性，不做真实排班系统。

## Key Changes
- 在 `appointment` 表增加 active guard generated column：
  - active 条件：`deleted = 0` 且 `status in ('PENDING_CONFIRM', 'CONFIRMED')`
  - active 行 guard 为 `1`
  - 非 active 行 guard 为 `NULL`
- 增加唯一索引：
  - `user_id, pet_id, provider_id, appointment_time, active_duplicate_guard`
- 后端保留 `ensureNoActiveDuplicateAppointment(...)`，用于提前返回可读业务错误。
- 后端补数据库唯一冲突兜底，把唯一约束冲突统一转成：
  - HTTP `409`
  - code `APPOINTMENT_CONFLICT`
  - message `该宠物在此时间已有预约，请选择其他时间`
- 手机端保留当前 `APPOINTMENT_CONFLICT` 中文提示和成功后清空时间段。

## Data Preparation
先只读确认 live DB 是否已有 active duplicate，再做人工清理，再上唯一约束。

只读查询：

```sql
SELECT user_id,
       pet_id,
       provider_id,
       appointment_time,
       COUNT(*) AS duplicate_count,
       GROUP_CONCAT(id ORDER BY id) AS appointment_ids
FROM appointment
WHERE deleted = 0
  AND status IN ('PENDING_CONFIRM', 'CONFIRMED')
GROUP BY user_id, pet_id, provider_id, appointment_time
HAVING COUNT(*) > 1;
```

人工清理思路：
- 保留一条要继续生效的预约。
- 其他 active duplicate 改成 `CANCELLED` 或软删除。
- 再次执行上面的只读查询，确认结果为空。

live DB 一次性 ALTER：

```sql
ALTER TABLE appointment
  ADD COLUMN active_duplicate_guard TINYINT GENERATED ALWAYS AS (
    CASE
      WHEN deleted = 0 AND status IN ('PENDING_CONFIRM', 'CONFIRMED') THEN 1
      ELSE NULL
    END
  );

ALTER TABLE appointment
  ADD UNIQUE KEY uk_appointment_active_duplicate (
    user_id,
    pet_id,
    provider_id,
    appointment_time,
    active_duplicate_guard
  );
```

同样的 SQL 已落到 `scripts/appointment-active-duplicate-guard.sql`，方便直接执行。

## Test Plan
- `createAppointmentRejectsDuplicateActiveAppointment`
- `createAppointmentAllowsRebookingAfterCancelled`
- `createAppointmentAllowsRebookingAfterCompleted`
- `appointmentTableUniqueConstraintBlocksActiveDuplicateInsert`
- `AppointmentServiceTest.createTranslatesActiveDuplicateConstraintViolationIntoAppointmentConflict`
- `PetPalRepository.test.ets` 保留手机端 `409 APPOINTMENT_CONFLICT` 文案透传校验
- `.\scripts\test-backend.ps1`
- `hvigorw.js test`
- `hvigorw.js assembleHap`

## Assumptions
- 冲突规则不含 `service_id`：同一宠物在同一机构同一时间，即使换服务，也视为冲突。
- `CANCELLED`、`COMPLETED`、`deleted = 1` 不阻止重约。
- `schema.sql` 是重建基线；当前没有 Flyway/Liquibase 迁移机制。live DB ALTER 需要手动执行上面的 SQL。
