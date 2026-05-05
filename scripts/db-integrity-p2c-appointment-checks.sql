-- PetPal P2c appointment check constraints for an existing MySQL database.
-- Run manually only after taking a database backup.
-- Each ALTER is intentionally separate so a failing CHECK can be rolled back independently.

-- Step 1: Pre-check existing rows that would violate the P2c CHECK constraints.
SELECT 'appointment_status' AS check_name,
       COUNT(*) AS invalid_count
FROM appointment
WHERE status NOT IN ('PENDING_CONFIRM', 'CONFIRMED', 'COMPLETED', 'CANCELLED', 'EXPIRED')
UNION ALL
SELECT 'appointment_deleted_bool' AS check_name,
       COUNT(*) AS invalid_count
FROM appointment
WHERE deleted NOT IN (0, 1);

-- Step 2: Confirm the P2c CHECK constraints are not already present.
SELECT tc.table_name,
       tc.constraint_name,
       tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = DATABASE()
  AND tc.constraint_type = 'CHECK'
  AND tc.constraint_name IN (
    'chk_appointment_status',
    'chk_appointment_deleted_bool'
  )
ORDER BY tc.table_name, tc.constraint_name;

-- Step 3: Continue only when all invalid_count values above are 0
-- and the existence check returns 0 rows.

ALTER TABLE appointment
  ADD CONSTRAINT chk_appointment_status
  CHECK (status IN ('PENDING_CONFIRM', 'CONFIRMED', 'COMPLETED', 'CANCELLED', 'EXPIRED'));

ALTER TABLE appointment
  ADD CONSTRAINT chk_appointment_deleted_bool
  CHECK (deleted IN (0, 1));

-- Step 4: Constraint existence check after ALTER.
SELECT tc.table_name,
       tc.constraint_name,
       tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = DATABASE()
  AND tc.constraint_type = 'CHECK'
  AND tc.constraint_name IN (
    'chk_appointment_status',
    'chk_appointment_deleted_bool'
  )
ORDER BY tc.table_name, tc.constraint_name;

-- Step 5: Post-ALTER invalid row re-check.
SELECT 'appointment_status' AS check_name,
       COUNT(*) AS invalid_count
FROM appointment
WHERE status NOT IN ('PENDING_CONFIRM', 'CONFIRMED', 'COMPLETED', 'CANCELLED', 'EXPIRED')
UNION ALL
SELECT 'appointment_deleted_bool' AS check_name,
       COUNT(*) AS invalid_count
FROM appointment
WHERE deleted NOT IN (0, 1);

-- Rollback one CHECK at a time if needed:
-- ALTER TABLE appointment DROP CHECK chk_appointment_deleted_bool;
-- ALTER TABLE appointment DROP CHECK chk_appointment_status;
