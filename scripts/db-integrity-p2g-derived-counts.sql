-- PetPal P2g post derived count repair for an existing MySQL database.
-- Run manually only after taking a database backup.
-- This repairs stored post counters from their source tables.

-- Step 1: Pre-check posts whose stored counters differ from source tables.
SELECT p.id,
       p.user_id,
       p.deleted,
       p.status,
       p.like_count AS stored_like_count,
       COALESCE(pl.actual_count, 0) AS actual_like_count,
       p.comment_count AS stored_comment_count,
       COALESCE(c.actual_count, 0) AS actual_comment_count
FROM post p
LEFT JOIN (
  SELECT post_id, COUNT(*) AS actual_count
  FROM post_like
  GROUP BY post_id
) pl ON pl.post_id = p.id
LEFT JOIN (
  SELECT post_id, COUNT(*) AS actual_count
  FROM comment
  WHERE parent_id IS NULL
  GROUP BY post_id
) c ON c.post_id = p.id
WHERE p.like_count <> COALESCE(pl.actual_count, 0)
   OR p.comment_count <> COALESCE(c.actual_count, 0)
ORDER BY p.id;

-- Step 2: Repair every mismatched post counter from source tables.
UPDATE post p
LEFT JOIN (
  SELECT post_id, COUNT(*) AS actual_count
  FROM post_like
  GROUP BY post_id
) pl ON pl.post_id = p.id
LEFT JOIN (
  SELECT post_id, COUNT(*) AS actual_count
  FROM comment
  WHERE parent_id IS NULL
  GROUP BY post_id
) c ON c.post_id = p.id
SET p.like_count = COALESCE(pl.actual_count, 0),
    p.comment_count = COALESCE(c.actual_count, 0)
WHERE p.like_count <> COALESCE(pl.actual_count, 0)
   OR p.comment_count <> COALESCE(c.actual_count, 0);

-- Step 3: Post-repair drift count must be 0.
SELECT COUNT(*) AS post_derived_count_drift
FROM post p
LEFT JOIN (
  SELECT post_id, COUNT(*) AS actual_count
  FROM post_like
  GROUP BY post_id
) pl ON pl.post_id = p.id
LEFT JOIN (
  SELECT post_id, COUNT(*) AS actual_count
  FROM comment
  WHERE parent_id IS NULL
  GROUP BY post_id
) c ON c.post_id = p.id
WHERE p.like_count <> COALESCE(pl.actual_count, 0)
   OR p.comment_count <> COALESCE(c.actual_count, 0);

-- Step 4: Post-repair detail check. This should return 0 rows.
SELECT p.id,
       p.user_id,
       p.deleted,
       p.status,
       p.like_count AS stored_like_count,
       COALESCE(pl.actual_count, 0) AS actual_like_count,
       p.comment_count AS stored_comment_count,
       COALESCE(c.actual_count, 0) AS actual_comment_count
FROM post p
LEFT JOIN (
  SELECT post_id, COUNT(*) AS actual_count
  FROM post_like
  GROUP BY post_id
) pl ON pl.post_id = p.id
LEFT JOIN (
  SELECT post_id, COUNT(*) AS actual_count
  FROM comment
  WHERE parent_id IS NULL
  GROUP BY post_id
) c ON c.post_id = p.id
WHERE p.like_count <> COALESCE(pl.actual_count, 0)
   OR p.comment_count <> COALESCE(c.actual_count, 0)
ORDER BY p.id;
