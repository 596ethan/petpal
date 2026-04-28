-- PetPal P1 business unique constraints and check constraints for an existing MySQL database.
-- Run manually only after taking a database backup.
-- This script is prepared in this slice but must not be executed blindly.

-- Step 1: Pre-check duplicate follow pairs.
SELECT follower_id,
       following_id,
       COUNT(*) AS duplicate_count
FROM user_follow
GROUP BY follower_id, following_id
HAVING COUNT(*) > 1;

-- Step 2: Pre-check self-follow rows.
SELECT id,
       follower_id,
       following_id
FROM user_follow
WHERE follower_id = following_id;

-- Step 3: Pre-check duplicate post image sort rows per post.
SELECT post_id,
       sort_order,
       COUNT(*) AS duplicate_count
FROM post_image
GROUP BY post_id, sort_order
HAVING COUNT(*) > 1;

-- Step 4: Pre-check negative post image sort rows.
SELECT id,
       post_id,
       sort_order
FROM post_image
WHERE sort_order < 0;

-- Step 5: Pre-check duplicate active service-item names per provider.
SELECT provider_id,
       name,
       COUNT(*) AS duplicate_count
FROM service_item
WHERE deleted = 0
GROUP BY provider_id, name
HAVING COUNT(*) > 1;

-- Step 6: Confirm the P1 constraints and generated column are not already present.
SELECT tc.table_name,
       tc.constraint_name,
       tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = DATABASE()
  AND (
    (tc.table_name = 'user_follow' AND tc.constraint_name IN ('uk_user_follow_pair', 'chk_user_follow_not_self'))
    OR (tc.table_name = 'post_image' AND tc.constraint_name IN ('uk_post_image_sort', 'chk_post_image_sort_non_negative'))
    OR (tc.table_name = 'service_item' AND tc.constraint_name = 'uk_service_item_active_name')
  )
ORDER BY tc.table_name, tc.constraint_name;

SELECT c.table_name,
       c.column_name,
       c.generation_expression
FROM information_schema.columns c
WHERE c.table_schema = DATABASE()
  AND c.table_name = 'service_item'
  AND c.column_name = 'active_name_guard';

-- Step 7: Continue only when the five pre-check queries above return 0 rows
-- and the existence checks return 0 rows.

ALTER TABLE user_follow
  ADD UNIQUE KEY uk_user_follow_pair (follower_id, following_id),
  ADD CONSTRAINT chk_user_follow_not_self CHECK (follower_id <> following_id);

ALTER TABLE post_image
  ADD UNIQUE KEY uk_post_image_sort (post_id, sort_order),
  ADD CONSTRAINT chk_post_image_sort_non_negative CHECK (sort_order >= 0);

ALTER TABLE service_item
  ADD COLUMN active_name_guard TINYINT GENERATED ALWAYS AS (
    CASE
      WHEN deleted = 0 THEN 1
      ELSE NULL
    END
  ),
  ADD UNIQUE KEY uk_service_item_active_name (provider_id, name, active_name_guard);

-- Step 8: Constraint existence checks after ALTER.
SELECT tc.table_name,
       tc.constraint_name,
       tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = DATABASE()
  AND (
    (tc.table_name = 'user_follow' AND tc.constraint_name IN ('uk_user_follow_pair', 'chk_user_follow_not_self'))
    OR (tc.table_name = 'post_image' AND tc.constraint_name IN ('uk_post_image_sort', 'chk_post_image_sort_non_negative'))
    OR (tc.table_name = 'service_item' AND tc.constraint_name = 'uk_service_item_active_name')
  )
ORDER BY tc.table_name, tc.constraint_name;

SELECT c.table_name,
       c.column_name,
       c.generation_expression
FROM information_schema.columns c
WHERE c.table_schema = DATABASE()
  AND c.table_name = 'service_item'
  AND c.column_name = 'active_name_guard';

-- Rollback order if needed:
-- ALTER TABLE service_item DROP INDEX uk_service_item_active_name;
-- ALTER TABLE service_item DROP COLUMN active_name_guard;
-- ALTER TABLE post_image DROP CHECK chk_post_image_sort_non_negative;
-- ALTER TABLE post_image DROP INDEX uk_post_image_sort;
-- ALTER TABLE user_follow DROP CHECK chk_user_follow_not_self;
-- ALTER TABLE user_follow DROP INDEX uk_user_follow_pair;
