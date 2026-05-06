-- PetPal DB integrity P2 summary review for an existing MySQL database.
-- Read-only: this script contains SELECT statements only.

SELECT DATABASE() AS database_name,
       VERSION() AS mysql_version,
       CURRENT_USER() AS mysql_current_user;

-- All live FOREIGN KEY, UNIQUE, and CHECK constraints.
SELECT tc.table_name,
       tc.constraint_name,
       tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = DATABASE()
  AND tc.constraint_type IN ('FOREIGN KEY', 'UNIQUE', 'CHECK')
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;

-- Foreign-key targets.
SELECT rc.table_name,
       rc.constraint_name,
       rc.referenced_table_name,
       rc.update_rule,
       rc.delete_rule
FROM information_schema.referential_constraints rc
WHERE rc.constraint_schema = DATABASE()
ORDER BY rc.table_name, rc.constraint_name;

-- CHECK clauses.
SELECT cc.constraint_name,
       tc.table_name,
       cc.check_clause
FROM information_schema.check_constraints cc
JOIN information_schema.table_constraints tc
  ON tc.constraint_schema = cc.constraint_schema
 AND tc.constraint_name = cc.constraint_name
WHERE cc.constraint_schema = DATABASE()
ORDER BY tc.table_name, cc.constraint_name;

-- Expected P0/P1/P2a-P2f DDL constraints and live presence.
-- P2g is a data-repair/audit slice and does not add DDL constraints.
WITH expected_constraints AS (
  SELECT 'P0' AS stage, 'pet' AS table_name, 'uk_pet_owner_id' AS constraint_name, 'UNIQUE' AS constraint_type UNION ALL
  SELECT 'P0', 'service_item', 'uk_service_item_provider_id', 'UNIQUE' UNION ALL
  SELECT 'P0', 'post', 'fk_post_user_pet', 'FOREIGN KEY' UNION ALL
  SELECT 'P0', 'appointment', 'fk_appointment_user_pet', 'FOREIGN KEY' UNION ALL
  SELECT 'P0', 'appointment', 'fk_appointment_provider_service', 'FOREIGN KEY' UNION ALL
  SELECT 'P1', 'user_follow', 'uk_user_follow_pair', 'UNIQUE' UNION ALL
  SELECT 'P1', 'user_follow', 'chk_user_follow_not_self', 'CHECK' UNION ALL
  SELECT 'P1', 'post_image', 'uk_post_image_sort', 'UNIQUE' UNION ALL
  SELECT 'P1', 'post_image', 'chk_post_image_sort_non_negative', 'CHECK' UNION ALL
  SELECT 'P1', 'service_item', 'uk_service_item_active_name', 'UNIQUE' UNION ALL
  SELECT 'P2a', 'pet', 'fk_pet_owner', 'FOREIGN KEY' UNION ALL
  SELECT 'P2a', 'pet_health_record', 'fk_pet_health_record_pet', 'FOREIGN KEY' UNION ALL
  SELECT 'P2a', 'pet_vaccine', 'fk_pet_vaccine_pet', 'FOREIGN KEY' UNION ALL
  SELECT 'P2a', 'service_item', 'fk_service_item_provider', 'FOREIGN KEY' UNION ALL
  SELECT 'P2b', 'pet', 'chk_pet_species', 'CHECK' UNION ALL
  SELECT 'P2b', 'pet', 'chk_pet_gender', 'CHECK' UNION ALL
  SELECT 'P2b', 'pet', 'chk_pet_weight_range', 'CHECK' UNION ALL
  SELECT 'P2b', 'pet', 'chk_pet_is_neutered_bool', 'CHECK' UNION ALL
  SELECT 'P2b', 'pet', 'chk_pet_deleted_bool', 'CHECK' UNION ALL
  SELECT 'P2b', 'pet_health_record', 'chk_pet_health_record_type', 'CHECK' UNION ALL
  SELECT 'P2c', 'appointment', 'chk_appointment_status', 'CHECK' UNION ALL
  SELECT 'P2c', 'appointment', 'chk_appointment_deleted_bool', 'CHECK' UNION ALL
  SELECT 'P2d', 'user_follow', 'fk_user_follow_follower', 'FOREIGN KEY' UNION ALL
  SELECT 'P2d', 'user_follow', 'fk_user_follow_following', 'FOREIGN KEY' UNION ALL
  SELECT 'P2d', 'post', 'fk_post_user', 'FOREIGN KEY' UNION ALL
  SELECT 'P2d', 'post_image', 'fk_post_image_post', 'FOREIGN KEY' UNION ALL
  SELECT 'P2d', 'post_like', 'fk_post_like_post', 'FOREIGN KEY' UNION ALL
  SELECT 'P2d', 'post_like', 'fk_post_like_user', 'FOREIGN KEY' UNION ALL
  SELECT 'P2d', 'comment', 'fk_comment_post', 'FOREIGN KEY' UNION ALL
  SELECT 'P2d', 'comment', 'fk_comment_parent', 'FOREIGN KEY' UNION ALL
  SELECT 'P2d', 'comment', 'fk_comment_user', 'FOREIGN KEY' UNION ALL
  SELECT 'P2e', 'service_provider', 'chk_service_provider_type', 'CHECK' UNION ALL
  SELECT 'P2e', 'service_provider', 'chk_service_provider_rating_range', 'CHECK' UNION ALL
  SELECT 'P2e', 'service_provider', 'chk_service_provider_deleted_bool', 'CHECK' UNION ALL
  SELECT 'P2e', 'service_item', 'chk_service_item_price_non_negative', 'CHECK' UNION ALL
  SELECT 'P2e', 'service_item', 'chk_service_item_duration_positive', 'CHECK' UNION ALL
  SELECT 'P2e', 'service_item', 'chk_service_item_deleted_bool', 'CHECK' UNION ALL
  SELECT 'P2f', 'user', 'chk_user_deleted_bool', 'CHECK' UNION ALL
  SELECT 'P2f', 'post', 'chk_post_visibility', 'CHECK' UNION ALL
  SELECT 'P2f', 'post', 'chk_post_like_count_non_negative', 'CHECK' UNION ALL
  SELECT 'P2f', 'post', 'chk_post_comment_count_non_negative', 'CHECK' UNION ALL
  SELECT 'P2f', 'post', 'chk_post_deleted_bool', 'CHECK'
)
SELECT ec.stage,
       ec.table_name,
       ec.constraint_name,
       ec.constraint_type,
       CASE WHEN tc.constraint_name IS NULL THEN 'missing' ELSE 'present' END AS live_status
FROM expected_constraints ec
LEFT JOIN information_schema.table_constraints tc
  ON tc.table_schema = DATABASE()
 AND tc.table_name = ec.table_name
 AND tc.constraint_name = ec.constraint_name
 AND tc.constraint_type = ec.constraint_type
ORDER BY ec.stage, ec.table_name, ec.constraint_name;

-- Invalid, conflicting, or drift rows for P0/P1/P2a-P2g covered checks.
SELECT 'P0' AS stage,
       'post_pet_owner_mismatch' AS check_name,
       COUNT(*) AS invalid_count
FROM post po
JOIN pet pe ON pe.id = po.pet_id
WHERE po.pet_id IS NOT NULL
  AND pe.owner_id <> po.user_id
UNION ALL
SELECT 'P0', 'appointment_pet_owner_mismatch', COUNT(*)
FROM appointment a
JOIN pet p ON p.id = a.pet_id
WHERE p.owner_id <> a.user_id
UNION ALL
SELECT 'P0', 'appointment_provider_service_mismatch', COUNT(*)
FROM appointment a
JOIN service_item si ON si.id = a.service_id
WHERE si.provider_id <> a.provider_id
UNION ALL
SELECT 'P1', 'duplicate_user_follow_pair', COUNT(*)
FROM (
  SELECT follower_id, following_id
  FROM user_follow
  GROUP BY follower_id, following_id
  HAVING COUNT(*) > 1
) dup_user_follow
UNION ALL
SELECT 'P1', 'user_follow_self_follow', COUNT(*)
FROM user_follow
WHERE follower_id = following_id
UNION ALL
SELECT 'P1', 'duplicate_post_image_sort', COUNT(*)
FROM (
  SELECT post_id, sort_order
  FROM post_image
  GROUP BY post_id, sort_order
  HAVING COUNT(*) > 1
) dup_post_image
UNION ALL
SELECT 'P1', 'post_image_negative_sort', COUNT(*)
FROM post_image
WHERE sort_order < 0
UNION ALL
SELECT 'P1', 'duplicate_active_service_item_name', COUNT(*)
FROM (
  SELECT provider_id, name
  FROM service_item
  WHERE deleted = 0
  GROUP BY provider_id, name
  HAVING COUNT(*) > 1
) dup_service_item
UNION ALL
SELECT 'P2a', 'pet_owner_orphan', COUNT(*)
FROM pet p
LEFT JOIN user u ON p.owner_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 'P2a', 'pet_health_record_pet_orphan', COUNT(*)
FROM pet_health_record h
LEFT JOIN pet p ON h.pet_id = p.id
WHERE p.id IS NULL
UNION ALL
SELECT 'P2a', 'pet_vaccine_pet_orphan', COUNT(*)
FROM pet_vaccine v
LEFT JOIN pet p ON v.pet_id = p.id
WHERE p.id IS NULL
UNION ALL
SELECT 'P2a', 'service_item_provider_orphan', COUNT(*)
FROM service_item si
LEFT JOIN service_provider sp ON si.provider_id = sp.id
WHERE sp.id IS NULL
UNION ALL
SELECT 'P2b', 'pet_species', COUNT(*)
FROM pet
WHERE species NOT IN ('DOG', 'CAT', 'RABBIT', 'BIRD', 'OTHER')
UNION ALL
SELECT 'P2b', 'pet_gender', COUNT(*)
FROM pet
WHERE gender NOT IN ('MALE', 'FEMALE', 'UNKNOWN')
UNION ALL
SELECT 'P2b', 'pet_weight_range', COUNT(*)
FROM pet
WHERE weight IS NOT NULL
  AND (weight < 0.01 OR weight > 999.99)
UNION ALL
SELECT 'P2b', 'pet_is_neutered_bool', COUNT(*)
FROM pet
WHERE is_neutered NOT IN (0, 1)
UNION ALL
SELECT 'P2b', 'pet_deleted_bool', COUNT(*)
FROM pet
WHERE deleted NOT IN (0, 1)
UNION ALL
SELECT 'P2b', 'pet_health_record_type', COUNT(*)
FROM pet_health_record
WHERE record_type NOT IN ('VACCINE', 'CHECKUP', 'MEDICATION', 'SURGERY')
UNION ALL
SELECT 'P2c', 'appointment_status', COUNT(*)
FROM appointment
WHERE status NOT IN ('PENDING_CONFIRM', 'CONFIRMED', 'COMPLETED', 'CANCELLED', 'EXPIRED')
UNION ALL
SELECT 'P2c', 'appointment_deleted_bool', COUNT(*)
FROM appointment
WHERE deleted NOT IN (0, 1)
UNION ALL
SELECT 'P2d', 'user_follow_follower_orphan', COUNT(*)
FROM user_follow uf
LEFT JOIN user u ON uf.follower_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 'P2d', 'user_follow_following_orphan', COUNT(*)
FROM user_follow uf
LEFT JOIN user u ON uf.following_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 'P2d', 'post_user_orphan', COUNT(*)
FROM post p
LEFT JOIN user u ON p.user_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 'P2d', 'post_image_post_orphan', COUNT(*)
FROM post_image pi
LEFT JOIN post p ON pi.post_id = p.id
WHERE p.id IS NULL
UNION ALL
SELECT 'P2d', 'post_like_post_orphan', COUNT(*)
FROM post_like pl
LEFT JOIN post p ON pl.post_id = p.id
WHERE p.id IS NULL
UNION ALL
SELECT 'P2d', 'post_like_user_orphan', COUNT(*)
FROM post_like pl
LEFT JOIN user u ON pl.user_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 'P2d', 'comment_post_orphan', COUNT(*)
FROM comment c
LEFT JOIN post p ON c.post_id = p.id
WHERE p.id IS NULL
UNION ALL
SELECT 'P2d', 'comment_parent_orphan', COUNT(*)
FROM comment c
LEFT JOIN comment parent ON c.parent_id = parent.id
WHERE c.parent_id IS NOT NULL
  AND parent.id IS NULL
UNION ALL
SELECT 'P2d', 'comment_user_orphan', COUNT(*)
FROM comment c
LEFT JOIN user u ON c.user_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 'P2e', 'service_provider_type', COUNT(*)
FROM service_provider
WHERE type NOT IN ('HOSPITAL', 'GROOMING', 'BOARDING')
UNION ALL
SELECT 'P2e', 'service_provider_rating_range', COUNT(*)
FROM service_provider
WHERE rating < 0.0
   OR rating > 5.0
UNION ALL
SELECT 'P2e', 'service_provider_deleted_bool', COUNT(*)
FROM service_provider
WHERE deleted NOT IN (0, 1)
UNION ALL
SELECT 'P2e', 'service_item_price_non_negative', COUNT(*)
FROM service_item
WHERE price < 0.00
UNION ALL
SELECT 'P2e', 'service_item_duration_positive', COUNT(*)
FROM service_item
WHERE duration <= 0
UNION ALL
SELECT 'P2e', 'service_item_deleted_bool', COUNT(*)
FROM service_item
WHERE deleted NOT IN (0, 1)
UNION ALL
SELECT 'P2f', 'user_deleted_bool', COUNT(*)
FROM user
WHERE deleted NOT IN (0, 1)
UNION ALL
SELECT 'P2f', 'post_visibility', COUNT(*)
FROM post
WHERE visibility NOT IN ('PUBLIC', 'FOLLOWERS_ONLY', 'PRIVATE')
UNION ALL
SELECT 'P2f', 'post_like_count_non_negative', COUNT(*)
FROM post
WHERE like_count < 0
UNION ALL
SELECT 'P2f', 'post_comment_count_non_negative', COUNT(*)
FROM post
WHERE comment_count < 0
UNION ALL
SELECT 'P2f', 'post_deleted_bool', COUNT(*)
FROM post
WHERE deleted NOT IN (0, 1)
UNION ALL
SELECT 'P2g', 'post_derived_count_drift', COUNT(*)
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

-- Remaining P2 candidates that were not closed by P2a-P2g.
SELECT 'service_review_appointment_orphan' AS check_name,
       COUNT(*) AS candidate_count
FROM service_review sr
LEFT JOIN appointment a ON sr.appointment_id = a.id
WHERE a.id IS NULL
UNION ALL
SELECT 'service_review_user_orphan', COUNT(*)
FROM service_review sr
LEFT JOIN user u ON sr.user_id = u.id
WHERE u.id IS NULL
UNION ALL
SELECT 'service_review_provider_orphan', COUNT(*)
FROM service_review sr
LEFT JOIN service_provider sp ON sr.provider_id = sp.id
WHERE sp.id IS NULL
UNION ALL
SELECT 'service_review_rating_out_of_range', COUNT(*)
FROM service_review
WHERE rating < 1
   OR rating > 5;

-- Live status values for columns without stable DB CHECK decisions yet.
SELECT 'user.status' AS column_name,
       status AS value,
       COUNT(*) AS row_count
FROM user
GROUP BY status
UNION ALL
SELECT 'post.status', status, COUNT(*)
FROM post
GROUP BY status
UNION ALL
SELECT 'service_provider.status', status, COUNT(*)
FROM service_provider
GROUP BY status
ORDER BY column_name, value;
