-- Step 1: Read-only check before adding the unique guard.
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

-- Step 2: Manually keep one active row per duplicate group, then cancel or soft-delete the others.
-- Example:
-- UPDATE appointment
-- SET status = 'CANCELLED'
-- WHERE id IN (15);
--
-- UPDATE appointment
-- SET deleted = 1
-- WHERE id IN (15);

-- Step 3: Confirm the duplicate query returns no rows before applying the ALTER.
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

-- Step 4: Add the generated guard column and unique index.
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
