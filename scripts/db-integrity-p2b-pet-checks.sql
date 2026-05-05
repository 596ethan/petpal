-- PetPal P2b pet archive check constraints for an existing MySQL database.
-- Run manually only after taking a database backup.
-- Each ALTER is intentionally separate so a failing CHECK can be rolled back independently.

-- Step 1: Pre-check existing rows that would violate the P2b CHECK constraints.
SELECT 'pet_species' AS check_name,
       COUNT(*) AS invalid_count
FROM pet
WHERE species NOT IN ('DOG', 'CAT', 'RABBIT', 'BIRD', 'OTHER')
UNION ALL
SELECT 'pet_gender' AS check_name,
       COUNT(*) AS invalid_count
FROM pet
WHERE gender NOT IN ('MALE', 'FEMALE', 'UNKNOWN')
UNION ALL
SELECT 'pet_weight_range' AS check_name,
       COUNT(*) AS invalid_count
FROM pet
WHERE weight IS NOT NULL
  AND (weight < 0.01 OR weight > 999.99)
UNION ALL
SELECT 'pet_is_neutered_bool' AS check_name,
       COUNT(*) AS invalid_count
FROM pet
WHERE is_neutered NOT IN (0, 1)
UNION ALL
SELECT 'pet_deleted_bool' AS check_name,
       COUNT(*) AS invalid_count
FROM pet
WHERE deleted NOT IN (0, 1)
UNION ALL
SELECT 'pet_health_record_type' AS check_name,
       COUNT(*) AS invalid_count
FROM pet_health_record
WHERE record_type NOT IN ('VACCINE', 'CHECKUP', 'MEDICATION', 'SURGERY');

-- Step 2: Confirm the P2b CHECK constraints are not already present.
SELECT tc.table_name,
       tc.constraint_name,
       tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = DATABASE()
  AND tc.constraint_type = 'CHECK'
  AND tc.constraint_name IN (
    'chk_pet_species',
    'chk_pet_gender',
    'chk_pet_weight_range',
    'chk_pet_is_neutered_bool',
    'chk_pet_deleted_bool',
    'chk_pet_health_record_type'
  )
ORDER BY tc.table_name, tc.constraint_name;

-- Step 3: Continue only when all invalid_count values above are 0
-- and the existence check returns 0 rows.

ALTER TABLE pet
  ADD CONSTRAINT chk_pet_species
  CHECK (species IN ('DOG', 'CAT', 'RABBIT', 'BIRD', 'OTHER'));

ALTER TABLE pet
  ADD CONSTRAINT chk_pet_gender
  CHECK (gender IN ('MALE', 'FEMALE', 'UNKNOWN'));

ALTER TABLE pet
  ADD CONSTRAINT chk_pet_weight_range
  CHECK (weight IS NULL OR weight BETWEEN 0.01 AND 999.99);

ALTER TABLE pet
  ADD CONSTRAINT chk_pet_is_neutered_bool
  CHECK (is_neutered IN (0, 1));

ALTER TABLE pet
  ADD CONSTRAINT chk_pet_deleted_bool
  CHECK (deleted IN (0, 1));

ALTER TABLE pet_health_record
  ADD CONSTRAINT chk_pet_health_record_type
  CHECK (record_type IN ('VACCINE', 'CHECKUP', 'MEDICATION', 'SURGERY'));

-- Step 4: Constraint existence check after ALTER.
SELECT tc.table_name,
       tc.constraint_name,
       tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = DATABASE()
  AND tc.constraint_type = 'CHECK'
  AND tc.constraint_name IN (
    'chk_pet_species',
    'chk_pet_gender',
    'chk_pet_weight_range',
    'chk_pet_is_neutered_bool',
    'chk_pet_deleted_bool',
    'chk_pet_health_record_type'
  )
ORDER BY tc.table_name, tc.constraint_name;

-- Rollback one CHECK at a time if needed:
-- ALTER TABLE pet_health_record DROP CHECK chk_pet_health_record_type;
-- ALTER TABLE pet DROP CHECK chk_pet_deleted_bool;
-- ALTER TABLE pet DROP CHECK chk_pet_is_neutered_bool;
-- ALTER TABLE pet DROP CHECK chk_pet_weight_range;
-- ALTER TABLE pet DROP CHECK chk_pet_gender;
-- ALTER TABLE pet DROP CHECK chk_pet_species;
