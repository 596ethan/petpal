package com.petpal.server.community;

import com.petpal.server.common.enums.PostVisibility;
import com.petpal.server.common.error.AppException;
import com.petpal.server.community.dto.PostCommentDto;
import com.petpal.server.community.dto.PostDto;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;

@Service
public class CommunityQueryService {
  private static final DateTimeFormatter DATETIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
  private static final Pattern TOPIC_PATTERN = Pattern.compile("#([\\p{IsAlphabetic}\\p{IsIdeographic}0-9_]+)");
  private static final int DEFAULT_FEED_LIMIT = 20;
  private static final int MAX_FEED_LIMIT = 50;

  private final JdbcClient jdbcClient;

  public CommunityQueryService(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public List<PostDto> feed(Long currentUserId) {
    return feed(currentUserId, null, null);
  }

  public List<PostDto> feed(Long currentUserId, Integer requestedLimit, Long beforeId) {
    int limit = normalizeLimit(requestedLimit);
    Long normalizedBeforeId = normalizeBeforeId(beforeId);
    // 动态流只返回公开、未删除、启用的帖子；beforeId 用于手机端下拉分页。
    List<PostRow> rows = jdbcClient.sql("""
      SELECT p.id,
             p.user_id,
             u.nickname AS user_nickname,
             u.avatar_url AS user_avatar_url,
             p.pet_id,
             pet.name AS pet_name,
             p.content,
             p.like_count,
             p.comment_count,
             p.visibility,
             p.created_at
      FROM post p
      JOIN user u ON u.id = p.user_id
      LEFT JOIN pet ON pet.id = p.pet_id
      WHERE p.deleted = 0
        AND p.status = 'ACTIVE'
        AND p.visibility = 'PUBLIC'
        AND (:beforeId IS NULL OR p.id < :beforeId)
      ORDER BY p.created_at DESC, p.id DESC
      LIMIT :limit
      """)
      .param("beforeId", normalizedBeforeId)
      .param("limit", limit)
      .query((rs, rowNum) -> mapPostRow(rs))
      .list();
    if (rows.isEmpty()) {
      return List.of();
    }

    List<Long> postIds = rows.stream().map(PostRow::id).toList();
    // 图片和点赞状态批量查，避免列表每条帖子额外访问数据库。
    Map<Long, List<String>> imagesByPostId = loadImages(postIds);
    Set<Long> likedPostIds = loadLikedPostIds(postIds, currentUserId);
    return rows.stream()
      .map(row -> mapPost(row, imagesByPostId.getOrDefault(row.id(), List.of()), likedPostIds.contains(row.id())))
      .toList();
  }

  public PostDto detail(Long postId, Long currentUserId) {
    return jdbcClient.sql("""
      SELECT p.id,
             p.user_id,
             u.nickname AS user_nickname,
             u.avatar_url AS user_avatar_url,
             p.pet_id,
             pet.name AS pet_name,
             p.content,
             p.like_count,
             p.comment_count,
             p.visibility,
             p.created_at
      FROM post p
      JOIN user u ON u.id = p.user_id
      LEFT JOIN pet ON pet.id = p.pet_id
      WHERE p.id = :postId
        AND p.deleted = 0
        AND p.status = 'ACTIVE'
      """)
      .param("postId", postId)
      .query((rs, rowNum) -> mapPostRow(rs))
      .optional()
      .map(row -> mapPost(row, loadImages(row.id()), isLikedByCurrentUser(row.id(), currentUserId)))
      .orElseThrow(() -> new AppException(404, "POST_NOT_FOUND", "Post not found"));
  }

  public List<PostCommentDto> comments(Long postId) {
    ensurePostExists(postId);
    return jdbcClient.sql("""
      SELECT c.id,
             c.parent_id,
             c.user_id,
             u.nickname AS user_nickname,
             c.content,
             c.created_at
      FROM comment c
      JOIN user u ON u.id = c.user_id
      WHERE c.post_id = :postId
        AND c.parent_id IS NULL
      ORDER BY c.created_at ASC, c.id ASC
      """)
      .param("postId", postId)
      .query((rs, rowNum) -> new PostCommentDto(
        rs.getLong("id"),
        rs.getObject("parent_id") == null ? null : rs.getLong("parent_id"),
        rs.getLong("user_id"),
        rs.getString("user_nickname"),
        rs.getString("content"),
        timestampToString(rs.getTimestamp("created_at"))
      ))
      .list();
  }

  private PostDto mapPost(PostRow row, List<String> imageUrls, boolean liked) {
    List<String> topics = extractTopics(row.content());
    return new PostDto(
      row.id(),
      row.userId(),
      row.userNickname(),
      row.userAvatarUrl(),
      row.petId(),
      row.petName(),
      row.content(),
      imageUrls,
      topics,
      row.visibility(),
      row.likeCount(),
      row.commentCount(),
      liked,
      row.createdAt()
    );
  }

  private List<String> loadImages(Long postId) {
    return jdbcClient.sql("""
      SELECT image_url
      FROM post_image
      WHERE post_id = :postId
      ORDER BY sort_order ASC, id ASC
      """)
      .param("postId", postId)
      .query(String.class)
      .list();
  }

  private Map<Long, List<String>> loadImages(List<Long> postIds) {
    List<PostImageRow> imageRows = jdbcClient.sql("""
      SELECT post_id, image_url
      FROM post_image
      WHERE post_id IN (:postIds)
      ORDER BY post_id ASC, sort_order ASC, id ASC
      """)
      .param("postIds", postIds)
      .query((rs, rowNum) -> new PostImageRow(rs.getLong("post_id"), rs.getString("image_url")))
      .list();
    Map<Long, List<String>> imagesByPostId = new LinkedHashMap<>();
    for (PostImageRow imageRow : imageRows) {
      imagesByPostId.computeIfAbsent(imageRow.postId(), id -> new ArrayList<>()).add(imageRow.imageUrl());
    }
    return imagesByPostId;
  }

  private boolean isLikedByCurrentUser(Long postId, Long currentUserId) {
    if (currentUserId == null) {
      return false;
    }
    Long count = jdbcClient.sql("""
      SELECT COUNT(*)
      FROM post_like
      WHERE post_id = :postId AND user_id = :userId
      """)
      .param("postId", postId)
      .param("userId", currentUserId)
      .query(Long.class)
      .single();
    return count != null && count > 0;
  }

  private Set<Long> loadLikedPostIds(List<Long> postIds, Long currentUserId) {
    if (currentUserId == null) {
      return Set.of();
    }
    return new LinkedHashSet<>(jdbcClient.sql("""
      SELECT post_id
      FROM post_like
      WHERE user_id = :userId AND post_id IN (:postIds)
      """)
      .param("userId", currentUserId)
      .param("postIds", postIds)
      .query(Long.class)
      .list());
  }

  private List<String> extractTopics(String content) {
    // 话题暂时从正文里的 #xxx 提取，保持社区 P0 不额外增加标签表。
    Matcher matcher = TOPIC_PATTERN.matcher(content == null ? "" : content);
    LinkedHashSet<String> topics = new LinkedHashSet<>();
    while (matcher.find()) {
      topics.add(matcher.group(1));
    }
    if (topics.isEmpty()) {
      return List.of("社区");
    }
    return new ArrayList<>(topics);
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

  private String timestampToString(Timestamp timestamp) {
    return timestamp == null ? null : timestamp.toLocalDateTime().format(DATETIME_FORMATTER);
  }

  private PostRow mapPostRow(ResultSet rs) throws SQLException {
    return new PostRow(
      rs.getLong("id"),
      rs.getLong("user_id"),
      rs.getString("user_nickname"),
      rs.getString("user_avatar_url"),
      rs.getObject("pet_id") == null ? null : rs.getLong("pet_id"),
      rs.getString("pet_name"),
      rs.getString("content"),
      rs.getLong("like_count"),
      rs.getLong("comment_count"),
      PostVisibility.valueOf(rs.getString("visibility")),
      timestampToString(rs.getTimestamp("created_at"))
    );
  }

  private int normalizeLimit(Integer requestedLimit) {
    // 限制单页数量，防止客户端传入过大的 limit 拉垮列表接口。
    if (requestedLimit == null) {
      return DEFAULT_FEED_LIMIT;
    }
    return Math.min(Math.max(requestedLimit, 1), MAX_FEED_LIMIT);
  }

  private Long normalizeBeforeId(Long beforeId) {
    return beforeId == null || beforeId <= 0 ? null : beforeId;
  }

  private record PostRow(Long id, Long userId, String userNickname, String userAvatarUrl, Long petId, String petName, String content, long likeCount, long commentCount, PostVisibility visibility, String createdAt) {
  }

  private record PostImageRow(Long postId, String imageUrl) {
  }
}
