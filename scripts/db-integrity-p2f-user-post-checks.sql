-- PetPal P2f user and post check constraints for an existing MySQL database.
-- Run manually only after taking a database backup.
-- Each table ALTER is separate so user and post changes can be handled independently.

-- Step 1: Pre-check existing rows that would violate the P2f CHECK constraints.
SELECT 'user_deleted_bool' AS check_name,
       COUNT(*) AS invalid_count
FROM user
WHERE deleted NOT IN (0, 1)
UNION ALL
SELECT 'post_visibility' AS check_name,
       COUNT(*) AS invalid_count
FROM post
WHERE visibility NOT IN ('PUBLIC', 'FOLLOWERS_ONLY', 'PRIVATE')
UNION ALL
SELECT 'post_like_count_non_negative' AS check_name,
       COUNT(*) AS invalid_count
FROM post
WHERE like_count < 0
UNION ALL
SELECT 'post_comment_count_non_negative' AS check_name,
       COUNT(*) AS invalid_count
FROM post
WHERE comment_count < 0
UNION ALL
SELECT 'post_deleted_bool' AS check_name,
       COUNT(*) AS invalid_count
FROM post
WHERE deleted NOT IN (0, 1);

-- Step 2: Confirm the P2f CHECK constraints are not already present.
SELECT tc.table_name,
       tc.constraint_name,
       tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = DATABASE()
  AND tc.constraint_type = 'CHECK'
  AND tc.constraint_name IN (
    'chk_user_deleted_bool',
    'chk_post_visibility',
    'chk_post_like_count_non_negative',
    'chk_post_comment_count_non_negative',
    'chk_post_deleted_bool'
  )
ORDER BY tc.table_name, tc.constraint_name;

-- Step 3: Continue only when all invalid_count values above are 0
-- and the existence check returns 0 rows.

ALTER TABLE user
  ADD CONSTRAINT chk_user_deleted_bool
  CHECK (deleted IN (0, 1));

ALTER TABLE post
  ADD CONSTRAINT chk_post_visibility
  CHECK (visibility IN ('PUBLIC', 'FOLLOWERS_ONLY', 'PRIVATE')),
  ADD CONSTRAINT chk_post_like_count_non_negative
  CHECK (like_count >= 0),
  ADD CONSTRAINT chk_post_comment_count_non_negative
  CHECK (comment_count >= 0),
  ADD CONSTRAINT chk_post_deleted_bool
  CHECK (deleted IN (0, 1));

-- Step 4: Constraint existence check after ALTER.
SELECT tc.table_name,
       tc.constraint_name,
       tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = DATABASE()
  AND tc.constraint_type = 'CHECK'
  AND tc.constraint_name IN (
    'chk_user_deleted_bool',
    'chk_post_visibility',
    'chk_post_like_count_non_negative',
    'chk_post_comment_count_non_negative',
    'chk_post_deleted_bool'
  )
ORDER BY tc.table_name, tc.constraint_name;

-- Step 5: Post-ALTER invalid row re-check.
SELECT 'user_deleted_bool' AS check_name,
       COUNT(*) AS invalid_count
FROM user
WHERE deleted NOT IN (0, 1)
UNION ALL
SELECT 'post_visibility' AS check_name,
       COUNT(*) AS invalid_count
FROM post
WHERE visibility NOT IN ('PUBLIC', 'FOLLOWERS_ONLY', 'PRIVATE')
UNION ALL
SELECT 'post_like_count_non_negative' AS check_name,
       COUNT(*) AS invalid_count
FROM post
WHERE like_count < 0
UNION ALL
SELECT 'post_comment_count_non_negative' AS check_name,
       COUNT(*) AS invalid_count
FROM post
WHERE comment_count < 0
UNION ALL
SELECT 'post_deleted_bool' AS check_name,
       COUNT(*) AS invalid_count
FROM post
WHERE deleted NOT IN (0, 1);

-- Rollback one CHECK at a time if needed:
-- ALTER TABLE post DROP CHECK chk_post_deleted_bool;
-- ALTER TABLE post DROP CHECK chk_post_comment_count_non_negative;
-- ALTER TABLE post DROP CHECK chk_post_like_count_non_negative;
-- ALTER TABLE post DROP CHECK chk_post_visibility;
-- ALTER TABLE user DROP CHECK chk_user_deleted_bool;
