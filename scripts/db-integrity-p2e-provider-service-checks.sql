-- PetPal P2e provider and service item check constraints for an existing MySQL database.
-- Run manually only after taking a database backup.
-- Each table ALTER is separate so provider and service-item changes can be handled independently.

-- Step 1: Pre-check existing rows that would violate the P2e CHECK constraints.
SELECT 'service_provider_type' AS check_name,
       COUNT(*) AS invalid_count
FROM service_provider
WHERE type NOT IN ('HOSPITAL', 'GROOMING', 'BOARDING')
UNION ALL
SELECT 'service_provider_rating_range' AS check_name,
       COUNT(*) AS invalid_count
FROM service_provider
WHERE rating < 0.0
   OR rating > 5.0
UNION ALL
SELECT 'service_provider_deleted_bool' AS check_name,
       COUNT(*) AS invalid_count
FROM service_provider
WHERE deleted NOT IN (0, 1)
UNION ALL
SELECT 'service_item_price_non_negative' AS check_name,
       COUNT(*) AS invalid_count
FROM service_item
WHERE price < 0.00
UNION ALL
SELECT 'service_item_duration_positive' AS check_name,
       COUNT(*) AS invalid_count
FROM service_item
WHERE duration <= 0
UNION ALL
SELECT 'service_item_deleted_bool' AS check_name,
       COUNT(*) AS invalid_count
FROM service_item
WHERE deleted NOT IN (0, 1);

-- Step 2: Confirm the P2e CHECK constraints are not already present.
SELECT tc.table_name,
       tc.constraint_name,
       tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = DATABASE()
  AND tc.constraint_type = 'CHECK'
  AND tc.constraint_name IN (
    'chk_service_provider_type',
    'chk_service_provider_rating_range',
    'chk_service_provider_deleted_bool',
    'chk_service_item_price_non_negative',
    'chk_service_item_duration_positive',
    'chk_service_item_deleted_bool'
  )
ORDER BY tc.table_name, tc.constraint_name;

-- Step 3: Continue only when all invalid_count values above are 0
-- and the existence check returns 0 rows.

ALTER TABLE service_provider
  ADD CONSTRAINT chk_service_provider_type
  CHECK (type IN ('HOSPITAL', 'GROOMING', 'BOARDING')),
  ADD CONSTRAINT chk_service_provider_rating_range
  CHECK (rating BETWEEN 0.0 AND 5.0),
  ADD CONSTRAINT chk_service_provider_deleted_bool
  CHECK (deleted IN (0, 1));

ALTER TABLE service_item
  ADD CONSTRAINT chk_service_item_price_non_negative
  CHECK (price >= 0.00),
  ADD CONSTRAINT chk_service_item_duration_positive
  CHECK (duration > 0),
  ADD CONSTRAINT chk_service_item_deleted_bool
  CHECK (deleted IN (0, 1));

-- Step 4: Constraint existence check after ALTER.
SELECT tc.table_name,
       tc.constraint_name,
       tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = DATABASE()
  AND tc.constraint_type = 'CHECK'
  AND tc.constraint_name IN (
    'chk_service_provider_type',
    'chk_service_provider_rating_range',
    'chk_service_provider_deleted_bool',
    'chk_service_item_price_non_negative',
    'chk_service_item_duration_positive',
    'chk_service_item_deleted_bool'
  )
ORDER BY tc.table_name, tc.constraint_name;

-- Step 5: Post-ALTER invalid row re-check.
SELECT 'service_provider_type' AS check_name,
       COUNT(*) AS invalid_count
FROM service_provider
WHERE type NOT IN ('HOSPITAL', 'GROOMING', 'BOARDING')
UNION ALL
SELECT 'service_provider_rating_range' AS check_name,
       COUNT(*) AS invalid_count
FROM service_provider
WHERE rating < 0.0
   OR rating > 5.0
UNION ALL
SELECT 'service_provider_deleted_bool' AS check_name,
       COUNT(*) AS invalid_count
FROM service_provider
WHERE deleted NOT IN (0, 1)
UNION ALL
SELECT 'service_item_price_non_negative' AS check_name,
       COUNT(*) AS invalid_count
FROM service_item
WHERE price < 0.00
UNION ALL
SELECT 'service_item_duration_positive' AS check_name,
       COUNT(*) AS invalid_count
FROM service_item
WHERE duration <= 0
UNION ALL
SELECT 'service_item_deleted_bool' AS check_name,
       COUNT(*) AS invalid_count
FROM service_item
WHERE deleted NOT IN (0, 1);

-- Rollback one CHECK at a time if needed:
-- ALTER TABLE service_item DROP CHECK chk_service_item_deleted_bool;
-- ALTER TABLE service_item DROP CHECK chk_service_item_duration_positive;
-- ALTER TABLE service_item DROP CHECK chk_service_item_price_non_negative;
-- ALTER TABLE service_provider DROP CHECK chk_service_provider_deleted_bool;
-- ALTER TABLE service_provider DROP CHECK chk_service_provider_rating_range;
-- ALTER TABLE service_provider DROP CHECK chk_service_provider_type;
