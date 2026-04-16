package com.petpal.server.community;

import com.petpal.server.common.enums.PostVisibility;
import com.petpal.server.common.error.AppException;
import com.petpal.server.community.dto.PostCommentCreateRequest;
import com.petpal.server.community.dto.PostCommentDto;
import com.petpal.server.community.dto.PostCreateRequest;
import com.petpal.server.community.dto.PostDto;
import java.sql.Timestamp;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CommunityMutationService {
  private static final DateTimeFormatter DATETIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
  private static final int MAX_POST_CONTENT_LENGTH = 500;
  private static final int MAX_COMMENT_CONTENT_LENGTH = 200;
  private static final int MAX_IMAGE_COUNT = 9;
  private static final int MAX_IMAGE_URL_LENGTH = 1024;

  private final JdbcClient jdbcClient;
  private final CommunityQueryService communityQueryService;

  public CommunityMutationService(JdbcClient jdbcClient, CommunityQueryService communityQueryService) {
    this.jdbcClient = jdbcClient;
    this.communityQueryService = communityQueryService;
  }

  @Transactional
  public PostDto createPost(long userId, PostCreateRequest request) {
    String content = requiredText(request.content(), MAX_POST_CONTENT_LENGTH, "INVALID_POST_FIELD", "Post content is required");
    List<String> imageUrls = normalizeImageUrls(request.imageUrls());
    if (request.petId() != null) {
      ensurePetOwnedByUser(userId, request.petId());
    }

    KeyHolder keyHolder = new GeneratedKeyHolder();
    jdbcClient.sql("""
      INSERT INTO post (user_id, pet_id, content, visibility, status, like_count, comment_count)
      VALUES (:userId, :petId, :content, :visibility, 'ACTIVE', 0, 0)
      """)
      .param("userId", userId)
      .param("petId", request.petId())
      .param("content", content)
      .param("visibility", PostVisibility.PUBLIC.name())
      .update(keyHolder, "id");

    long postId = keyHolder.getKey().longValue();
    insertImages(postId, imageUrls);
    return communityQueryService.detail(postId, userId);
  }

  @Transactional
  public void deletePost(long userId, Long postId) {
    ensurePostOwnedByUser(userId, postId);
    jdbcClient.sql("""
      UPDATE post
      SET deleted = 1,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = :postId
        AND user_id = :userId
        AND deleted = 0
        AND status = 'ACTIVE'
      """)
      .param("postId", postId)
      .param("userId", userId)
      .update();
  }

  @Transactional
  public void like(long userId, Long postId) {
    ensurePostExists(postId);
    Long existing = jdbcClient.sql("""
      SELECT COUNT(*)
      FROM post_like
      WHERE post_id = :postId AND user_id = :userId
      """)
      .param("postId", postId)
      .param("userId", userId)
      .query(Long.class)
      .single();
    if (existing != null && existing > 0) {
      return;
    }

    jdbcClient.sql("""
      INSERT INTO post_like (post_id, user_id)
      VALUES (:postId, :userId)
      """)
      .param("postId", postId)
      .param("userId", userId)
      .update();
    jdbcClient.sql("""
      UPDATE post
      SET like_count = like_count + 1,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = :postId
      """)
      .param("postId", postId)
      .update();
  }

  @Transactional
  public void unlike(long userId, Long postId) {
    ensurePostExists(postId);
    int deleted = jdbcClient.sql("""
      DELETE FROM post_like
      WHERE post_id = :postId AND user_id = :userId
      """)
      .param("postId", postId)
      .param("userId", userId)
      .update();
    if (deleted > 0) {
      jdbcClient.sql("""
        UPDATE post
        SET like_count = CASE WHEN like_count > 0 THEN like_count - 1 ELSE 0 END,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = :postId
        """)
        .param("postId", postId)
        .update();
    }
  }

  @Transactional
  public PostCommentDto comment(long userId, Long postId, PostCommentCreateRequest request) {
    ensurePostExists(postId);
    String content = requiredText(request.content(), MAX_COMMENT_CONTENT_LENGTH, "INVALID_COMMENT_FIELD", "Comment content is required");

    KeyHolder keyHolder = new GeneratedKeyHolder();
    jdbcClient.sql("""
      INSERT INTO comment (post_id, parent_id, user_id, content)
      VALUES (:postId, NULL, :userId, :content)
      """)
      .param("postId", postId)
      .param("userId", userId)
      .param("content", content)
      .update(keyHolder, "id");

    jdbcClient.sql("""
      UPDATE post
      SET comment_count = comment_count + 1,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = :postId
      """)
      .param("postId", postId)
      .update();

    return loadComment(keyHolder.getKey().longValue());
  }

  private void insertImages(long postId, List<String> imageUrls) {
    for (int i = 0; i < imageUrls.size(); i++) {
      jdbcClient.sql("""
        INSERT INTO post_image (post_id, image_url, sort_order)
        VALUES (:postId, :imageUrl, :sortOrder)
        """)
        .param("postId", postId)
        .param("imageUrl", imageUrls.get(i))
        .param("sortOrder", i)
        .update();
    }
  }

  private PostCommentDto loadComment(long commentId) {
    return jdbcClient.sql("""
      SELECT c.id,
             c.parent_id,
             c.user_id,
             u.nickname AS user_nickname,
             c.content,
             c.created_at
      FROM comment c
      JOIN user u ON u.id = c.user_id
      WHERE c.id = :commentId
      """)
      .param("commentId", commentId)
      .query((rs, rowNum) -> new PostCommentDto(
        rs.getLong("id"),
        rs.getObject("parent_id") == null ? null : rs.getLong("parent_id"),
        rs.getLong("user_id"),
        rs.getString("user_nickname"),
        rs.getString("content"),
        timestampToString(rs.getTimestamp("created_at"))
      ))
      .single();
  }

  private void ensurePetOwnedByUser(long userId, Long petId) {
    Long count = jdbcClient.sql("""
      SELECT COUNT(*)
      FROM pet
      WHERE id = :petId AND owner_id = :userId AND deleted = 0
      """)
      .param("petId", petId)
      .param("userId", userId)
      .query(Long.class)
      .single();
    if (count == null || count == 0) {
      throw new AppException(404, "PET_NOT_FOUND", "Pet not found");
    }
  }

  private void ensurePostOwnedByUser(long userId, Long postId) {
    Long count = jdbcClient.sql("""
      SELECT COUNT(*)
      FROM post
      WHERE id = :postId
        AND user_id = :userId
        AND deleted = 0
        AND status = 'ACTIVE'
      """)
      .param("postId", postId)
      .param("userId", userId)
      .query(Long.class)
      .single();
    if (count == null || count == 0) {
      throw new AppException(404, "POST_NOT_FOUND", "Post not found");
    }
  }

  private void ensurePostExists(Long postId) {
    Long count = jdbcClient.sql("""
      SELECT COUNT(*)
      FROM post
      WHERE id = :postId AND deleted = 0 AND status = 'ACTIVE'
      """)
      .param("postId", postId)
      .query(Long.class)
      .single();
    if (count == null || count == 0) {
      throw new AppException(404, "POST_NOT_FOUND", "Post not found");
    }
  }

  private String requiredText(String value, int maxLength, String code, String message) {
    if (value == null || value.trim().isEmpty()) {
      throw new AppException(400, code, message);
    }
    String trimmed = value.trim();
    if (trimmed.length() > maxLength) {
      throw new AppException(400, code, message);
    }
    return trimmed;
  }

  private List<String> normalizeImageUrls(List<String> values) {
    if (values == null) {
      return List.of();
    }
    if (values.size() > MAX_IMAGE_COUNT) {
      throw new AppException(400, "INVALID_POST_IMAGE", "Post supports up to 9 images");
    }
    List<String> normalized = new ArrayList<>();
    for (String value : values) {
      if (value == null || value.trim().isEmpty()) {
        throw new AppException(400, "INVALID_POST_IMAGE", "Post image URL is required");
      }
      String trimmed = value.trim();
      if (trimmed.length() > MAX_IMAGE_URL_LENGTH) {
        throw new AppException(400, "INVALID_POST_IMAGE", "Post image URL is too long");
      }
      normalized.add(trimmed);
    }
    return normalized;
  }

  private String timestampToString(Timestamp timestamp) {
    return timestamp == null ? null : timestamp.toLocalDateTime().format(DATETIME_FORMATTER);
  }
}
