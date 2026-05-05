-- PetPal P2d community ordinary foreign keys for an existing MySQL database.
-- Run manually only after taking a database backup.
-- Each ALTER is grouped by table so a failing FK can be rolled back by table.

-- Step 1: Pre-check existing rows that would violate the P2d foreign keys.
SELECT 'user_follow_follower' AS check_name,
       COUNT(*) AS orphan_count
FROM user_follow uf
LEFT JOIN user u ON uf.follower_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 'user_follow_following' AS check_name,
       COUNT(*) AS orphan_count
FROM user_follow uf
LEFT JOIN user u ON uf.following_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 'post_user' AS check_name,
       COUNT(*) AS orphan_count
FROM post p
LEFT JOIN user u ON p.user_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 'post_image_post' AS check_name,
       COUNT(*) AS orphan_count
FROM post_image pi
LEFT JOIN post p ON pi.post_id = p.id
WHERE p.id IS NULL
UNION ALL
SELECT 'post_like_post' AS check_name,
       COUNT(*) AS orphan_count
FROM post_like pl
LEFT JOIN post p ON pl.post_id = p.id
WHERE p.id IS NULL
UNION ALL
SELECT 'post_like_user' AS check_name,
       COUNT(*) AS orphan_count
FROM post_like pl
LEFT JOIN user u ON pl.user_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 'comment_post' AS check_name,
       COUNT(*) AS orphan_count
FROM comment c
LEFT JOIN post p ON c.post_id = p.id
WHERE p.id IS NULL
UNION ALL
SELECT 'comment_parent' AS check_name,
       COUNT(*) AS orphan_count
FROM comment c
LEFT JOIN comment parent ON c.parent_id = parent.id
WHERE c.parent_id IS NOT NULL
  AND parent.id IS NULL
UNION ALL
SELECT 'comment_user' AS check_name,
       COUNT(*) AS orphan_count
FROM comment c
LEFT JOIN user u ON c.user_id = u.id
WHERE u.id IS NULL;

-- Step 2: Confirm the P2d foreign keys are not already present.
SELECT rc.table_name,
       rc.constraint_name,
       rc.referenced_table_name
FROM information_schema.referential_constraints rc
WHERE rc.constraint_schema = DATABASE()
  AND rc.constraint_name IN (
    'fk_user_follow_follower',
    'fk_user_follow_following',
    'fk_post_user',
    'fk_post_image_post',
    'fk_post_like_post',
    'fk_post_like_user',
    'fk_comment_post',
    'fk_comment_parent',
    'fk_comment_user'
  )
ORDER BY rc.table_name, rc.constraint_name;

-- Step 3: Continue only when all orphan_count values above are 0
-- and the existence check returns 0 rows.

ALTER TABLE user_follow
  ADD CONSTRAINT fk_user_follow_follower
  FOREIGN KEY (follower_id) REFERENCES user (id),
  ADD CONSTRAINT fk_user_follow_following
  FOREIGN KEY (following_id) REFERENCES user (id);

ALTER TABLE post
  ADD CONSTRAINT fk_post_user
  FOREIGN KEY (user_id) REFERENCES user (id);

ALTER TABLE post_image
  ADD CONSTRAINT fk_post_image_post
  FOREIGN KEY (post_id) REFERENCES post (id);

ALTER TABLE post_like
  ADD CONSTRAINT fk_post_like_post
  FOREIGN KEY (post_id) REFERENCES post (id),
  ADD CONSTRAINT fk_post_like_user
  FOREIGN KEY (user_id) REFERENCES user (id);

ALTER TABLE comment
  ADD CONSTRAINT fk_comment_post
  FOREIGN KEY (post_id) REFERENCES post (id),
  ADD CONSTRAINT fk_comment_parent
  FOREIGN KEY (parent_id) REFERENCES comment (id),
  ADD CONSTRAINT fk_comment_user
  FOREIGN KEY (user_id) REFERENCES user (id);

-- Step 4: Constraint existence check after ALTER.
SELECT rc.table_name,
       rc.constraint_name,
       rc.referenced_table_name
FROM information_schema.referential_constraints rc
WHERE rc.constraint_schema = DATABASE()
  AND rc.constraint_name IN (
    'fk_user_follow_follower',
    'fk_user_follow_following',
    'fk_post_user',
    'fk_post_image_post',
    'fk_post_like_post',
    'fk_post_like_user',
    'fk_comment_post',
    'fk_comment_parent',
    'fk_comment_user'
  )
ORDER BY rc.table_name, rc.constraint_name;

-- Step 5: Post-ALTER orphan re-check.
SELECT 'user_follow_follower' AS check_name,
       COUNT(*) AS orphan_count
FROM user_follow uf
LEFT JOIN user u ON uf.follower_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 'user_follow_following' AS check_name,
       COUNT(*) AS orphan_count
FROM user_follow uf
LEFT JOIN user u ON uf.following_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 'post_user' AS check_name,
       COUNT(*) AS orphan_count
FROM post p
LEFT JOIN user u ON p.user_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 'post_image_post' AS check_name,
       COUNT(*) AS orphan_count
FROM post_image pi
LEFT JOIN post p ON pi.post_id = p.id
WHERE p.id IS NULL
UNION ALL
SELECT 'post_like_post' AS check_name,
       COUNT(*) AS orphan_count
FROM post_like pl
LEFT JOIN post p ON pl.post_id = p.id
WHERE p.id IS NULL
UNION ALL
SELECT 'post_like_user' AS check_name,
       COUNT(*) AS orphan_count
FROM post_like pl
LEFT JOIN user u ON pl.user_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 'comment_post' AS check_name,
       COUNT(*) AS orphan_count
FROM comment c
LEFT JOIN post p ON c.post_id = p.id
WHERE p.id IS NULL
UNION ALL
SELECT 'comment_parent' AS check_name,
       COUNT(*) AS orphan_count
FROM comment c
LEFT JOIN comment parent ON c.parent_id = parent.id
WHERE c.parent_id IS NOT NULL
  AND parent.id IS NULL
UNION ALL
SELECT 'comment_user' AS check_name,
       COUNT(*) AS orphan_count
FROM comment c
LEFT JOIN user u ON c.user_id = u.id
WHERE u.id IS NULL;

-- Rollback one FK at a time if needed:
-- ALTER TABLE comment DROP FOREIGN KEY fk_comment_user;
-- ALTER TABLE comment DROP FOREIGN KEY fk_comment_parent;
-- ALTER TABLE comment DROP FOREIGN KEY fk_comment_post;
-- ALTER TABLE post_like DROP FOREIGN KEY fk_post_like_user;
-- ALTER TABLE post_like DROP FOREIGN KEY fk_post_like_post;
-- ALTER TABLE post_image DROP FOREIGN KEY fk_post_image_post;
-- ALTER TABLE post DROP FOREIGN KEY fk_post_user;
-- ALTER TABLE user_follow DROP FOREIGN KEY fk_user_follow_following;
-- ALTER TABLE user_follow DROP FOREIGN KEY fk_user_follow_follower;
