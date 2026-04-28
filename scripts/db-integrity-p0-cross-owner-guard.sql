-- PetPal P0 data-integrity hardening for an existing MySQL database.
-- Run manually only after taking a database backup.

-- Step 1: Pre-check post pet ownership mismatches.
SELECT po.id AS post_id,
       po.user_id AS post_user_id,
       po.pet_id,
       pe.owner_id AS pet_owner_id
FROM post po
JOIN pet pe ON pe.id = po.pet_id
WHERE po.pet_id IS NOT NULL
  AND pe.owner_id <> po.user_id;

-- Step 2: Pre-check appointment pet ownership mismatches.
SELECT a.id AS appointment_id,
       a.user_id,
       a.pet_id,
       p.owner_id
FROM appointment a
JOIN pet p ON p.id = a.pet_id
WHERE p.owner_id <> a.user_id;

-- Step 3: Pre-check appointment service/provider mismatches.
SELECT a.id AS appointment_id,
       a.provider_id,
       a.service_id,
       si.provider_id AS service_provider_id
FROM appointment a
JOIN service_item si ON si.id = a.service_id
WHERE si.provider_id <> a.provider_id;

-- Step 4: Clean the known seed/demo mismatch before adding constraints.
UPDATE post
SET user_id = 1
WHERE id = 2
  AND user_id = 2
  AND pet_id = 2;

-- Step 5: Re-run the three pre-checks above and continue only when all return 0 rows.

-- Step 6: Add support unique keys for composite foreign keys.
ALTER TABLE pet
  ADD UNIQUE KEY uk_pet_owner_id (owner_id, id);

ALTER TABLE service_item
  ADD UNIQUE KEY uk_service_item_provider_id (provider_id, id);

-- Step 7: Add composite foreign keys that block cross-owner and cross-provider writes.
ALTER TABLE post
  ADD CONSTRAINT fk_post_user_pet
  FOREIGN KEY (user_id, pet_id) REFERENCES pet (owner_id, id);

ALTER TABLE appointment
  ADD CONSTRAINT fk_appointment_user_pet
  FOREIGN KEY (user_id, pet_id) REFERENCES pet (owner_id, id),
  ADD CONSTRAINT fk_appointment_provider_service
  FOREIGN KEY (provider_id, service_id) REFERENCES service_item (provider_id, id);

-- Rollback order if needed:
-- ALTER TABLE appointment DROP FOREIGN KEY fk_appointment_provider_service;
-- ALTER TABLE appointment DROP FOREIGN KEY fk_appointment_user_pet;
-- ALTER TABLE post DROP FOREIGN KEY fk_post_user_pet;
-- ALTER TABLE service_item DROP INDEX uk_service_item_provider_id;
-- ALTER TABLE pet DROP INDEX uk_pet_owner_id;
