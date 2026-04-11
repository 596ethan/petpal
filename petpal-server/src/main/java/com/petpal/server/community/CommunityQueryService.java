package com.petpal.server.community;

import com.petpal.server.common.enums.PostVisibility;
import com.petpal.server.common.error.AppException;
import com.petpal.server.community.dto.PostCommentDto;
import com.petpal.server.community.dto.PostDto;
import java.sql.Timestamp;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;

@Service
public class CommunityQueryService {
  private static final DateTimeFormatter DATETIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
  private static final Pattern TOPIC_PATTERN = Pattern.compile("#([\\p{IsAlphabetic}\\p{IsIdeographic}0-9_]+)");

  private final JdbcClient jdbcClient;

  public CommunityQueryService(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public List<PostDto> feed() {
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
      WHERE p.deleted = 0
        AND p.status = 'ACTIVE'
        AND p.visibility = 'PUBLIC'
      ORDER BY p.created_at DESC, p.id DESC
      """)
      .query((rs, rowNum) -> mapPost(
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
      ))
      .list();
  }

  public PostDto detail(Long postId) {
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
      .query((rs, rowNum) -> mapPost(
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
      ))
      .optional()
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

  private PostDto mapPost(Long id, Long userId, String userNickname, String userAvatarUrl, Long petId, String petName, String content, long likeCount, long commentCount, PostVisibility visibility, String createdAt) {
    List<String> topics = extractTopics(content);
    return new PostDto(
      id,
      userId,
      userNickname,
      userAvatarUrl,
      petId,
      petName,
      content,
      List.of(),
      topics,
      visibility,
      likeCount,
      commentCount,
      false,
      createdAt
    );
  }

  private List<String> extractTopics(String content) {
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
}
