package com.petpal.server.user;

import com.petpal.server.user.dto.UserProfileDto;
import java.util.Optional;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class UserAccountRepository {
  private final JdbcClient jdbcClient;

  public UserAccountRepository(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public Optional<UserAccountRecord> findByPhone(String phone) {
    return jdbcClient.sql("""
      SELECT id, phone, password, nickname, avatar_url, bio
      FROM user
      WHERE phone = :phone AND deleted = 0
      """)
      .param("phone", phone)
      .query((rs, rowNum) -> new UserAccountRecord(
        rs.getLong("id"),
        rs.getString("phone"),
        rs.getString("password"),
        rs.getString("nickname"),
        rs.getString("avatar_url"),
        rs.getString("bio")
      ))
      .optional();
  }

  public Optional<UserAccountRecord> findById(Long id) {
    return jdbcClient.sql("""
      SELECT id, phone, password, nickname, avatar_url, bio
      FROM user
      WHERE id = :id AND deleted = 0
      """)
      .param("id", id)
      .query((rs, rowNum) -> new UserAccountRecord(
        rs.getLong("id"),
        rs.getString("phone"),
        rs.getString("password"),
        rs.getString("nickname"),
        rs.getString("avatar_url"),
        rs.getString("bio")
      ))
      .optional();
  }

  public long create(String phone, String password, String nickname) {
    jdbcClient.sql("""
      INSERT INTO user (phone, password, nickname, avatar_url, bio)
      VALUES (:phone, :password, :nickname, :avatarUrl, :bio)
      """)
      .param("phone", phone)
      .param("password", password)
      .param("nickname", nickname)
      .param("avatarUrl", "https://placehold.co/96x96")
      .param("bio", "")
      .update();

    return jdbcClient.sql("SELECT id FROM user WHERE phone = :phone")
      .param("phone", phone)
      .query(Long.class)
      .single();
  }

  public UserProfileDto loadProfile(long userId) {
    UserAccountRecord user = findById(userId).orElseThrow();
    long followingCount = jdbcClient.sql("SELECT COUNT(*) FROM user_follow WHERE follower_id = :userId")
      .param("userId", userId)
      .query(Long.class)
      .single();
    long followerCount = jdbcClient.sql("SELECT COUNT(*) FROM user_follow WHERE following_id = :userId")
      .param("userId", userId)
      .query(Long.class)
      .single();
    return new UserProfileDto(user.id(), user.phone(), user.nickname(), user.avatarUrl(), user.bio(), followingCount, followerCount);
  }

  public UserProfileDto updateProfile(long userId, String nickname, String avatarUrl, String bio) {
    UserAccountRecord current = findById(userId).orElseThrow();
    jdbcClient.sql("""
      UPDATE user
      SET nickname = :nickname, avatar_url = :avatarUrl, bio = :bio
      WHERE id = :userId
      """)
      .param("userId", userId)
      .param("nickname", nickname == null || nickname.isBlank() ? current.nickname() : nickname)
      .param("avatarUrl", avatarUrl == null || avatarUrl.isBlank() ? current.avatarUrl() : avatarUrl)
      .param("bio", bio == null ? current.bio() : bio)
      .update();
    return loadProfile(userId);
  }
}
