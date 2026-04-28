-- PetPal P2a core ordinary foreign keys for an existing MySQL database.
-- Run manually only after taking a database backup.
-- Each ALTER is intentionally separate so a failing FK can be rolled back independently.

-- Step 1: Pre-check pets whose owner does not exist.
SELECT p.id,
       p.owner_id
FROM pet p
LEFT JOIN user u ON p.owner_id = u.id
WHERE u.id IS NULL;

-- Step 2: Pre-check health records whose pet does not exist.
SELECT h.id,
       h.pet_id
FROM pet_health_record h
LEFT JOIN pet p ON h.pet_id = p.id
WHERE p.id IS NULL;

-- Step 3: Pre-check vaccine records whose pet does not exist.
SELECT v.id,
       v.pet_id
FROM pet_vaccine v
LEFT JOIN pet p ON v.pet_id = p.id
WHERE p.id IS NULL;

-- Step 4: Pre-check service items whose provider does not exist.
SELECT si.id,
       si.provider_id
FROM service_item si
LEFT JOIN service_provider sp ON si.provider_id = sp.id
WHERE sp.id IS NULL;

-- Step 5: Confirm the P2a foreign keys are not already present.
SELECT rc.table_name,
       rc.constraint_name,
       rc.referenced_table_name
FROM information_schema.referential_constraints rc
WHERE rc.constraint_schema = DATABASE()
  AND rc.constraint_name IN (
    'fk_pet_owner',
    'fk_pet_health_record_pet',
    'fk_pet_vaccine_pet',
    'fk_service_item_provider'
  )
ORDER BY rc.table_name, rc.constraint_name;

-- Step 6: Continue only when the four pre-check queries above return 0 rows
-- and the existence check returns 0 rows.

ALTER TABLE pet
  ADD CONSTRAINT fk_pet_owner
  FOREIGN KEY (owner_id) REFERENCES user (id);

ALTER TABLE pet_health_record
  ADD CONSTRAINT fk_pet_health_record_pet
  FOREIGN KEY (pet_id) REFERENCES pet (id);

ALTER TABLE pet_vaccine
  ADD CONSTRAINT fk_pet_vaccine_pet
  FOREIGN KEY (pet_id) REFERENCES pet (id);

ALTER TABLE service_item
  ADD CONSTRAINT fk_service_item_provider
  FOREIGN KEY (provider_id) REFERENCES service_provider (id);

-- Step 7: Constraint existence check after ALTER.
SELECT rc.table_name,
       rc.constraint_name,
       rc.referenced_table_name
FROM information_schema.referential_constraints rc
WHERE rc.constraint_schema = DATABASE()
  AND rc.constraint_name IN (
    'fk_pet_owner',
    'fk_pet_health_record_pet',
    'fk_pet_vaccine_pet',
    'fk_service_item_provider'
  )
ORDER BY rc.table_name, rc.constraint_name;

-- Rollback one FK at a time if needed:
-- ALTER TABLE service_item DROP FOREIGN KEY fk_service_item_provider;
-- ALTER TABLE pet_vaccine DROP FOREIGN KEY fk_pet_vaccine_pet;
-- ALTER TABLE pet_health_record DROP FOREIGN KEY fk_pet_health_record_pet;
-- ALTER TABLE pet DROP FOREIGN KEY fk_pet_owner;
