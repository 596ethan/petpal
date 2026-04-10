package com.petpal.server.user.dto;

public record UserProfileDto(
  Long id,
  String phone,
  String nickname,
  String avatarUrl,
  String bio,
  long followingCount,
  long followerCount
) {
}
